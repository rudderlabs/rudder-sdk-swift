//
//  MessageManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation
// MARK: - MessageManager
/**
 This class manages messages and their operations, such as storing and uploading them.
 */
final class MessageManager {
    var analytics: AnalyticsClient
    
    //Different channel for different operations..
    private var writeChannel: AsyncChannel<Message>
    private var uploadChannel: AsyncChannel<String>
    private var httpClient: HttpClient?
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        self.httpClient = HttpClient(analytics: analytics)
        
        self.start()
    }
    
    deinit {
        self.httpClient = nil
        self.stop()
    }
    
    func put(_ message: Message) {
        guard message.type != .flush else { self.flush(); return }
        self.writeChannel.send(message)
    }
    
    private func flush() {
        self.uploadChannel.send(Constants.uploadSignal)
    }
    
    private func start() {
        Task {
            await self.writeChannel.consume { message in
                self.performStorage(message)
            }
        }
        
        Task {
            await self.uploadChannel.consume { value in
                self.startUploading()
            }
        }
    }
    
    func stop() {
        self.writeChannel.closeChannel()
        self.uploadChannel.closeChannel()
    }
}

// MARK: - Storage
extension MessageManager {
    var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    func performStorage(_ message: Message) {
        guard let json = message.jsonString else { return }
        self.storage.write(message: json)
    }
}

// MARK: - Upload
extension MessageManager {
    
    var storageMode: StorageMode {
        return self.storage.eventStorageMode
    }
    
    func startUploading() {
        self.storage.rollover {
            if self.storageMode == .disk {
                if let received = self.storage.read().dataFiles { // disk store
                    for file in received {
                        print(file.path())
                        print(FileManager.contentsOf(file: file.path()) ?? "No contents of file")
                        
                        guard let content = FileManager.contentsOf(file: file.path()) else { continue }
                        self.uploadBatch(content, file.path())
                        self.isInOrder(content)
                        print("Processed: \(file.path())")
                    }
                }
            } else {
                if let received = self.storage.read().dataItems { // memory store
                    for item in received {
                        print(item.batch)
                        self.uploadBatch(item.batch, item.id)
                        self.isInOrder(item.batch)
                        print("Processed: \(item.id)")
                    }
                }
            }
        }
    }
    
    func uploadBatch(_ batch: String, _ reference: String) {
        self.httpClient?.postBatchEvents(batch, { result in
            switch result {
            case .success(let response):
                print(response.jsonString ?? "Bad response")
                self.storage.remove(messageReference: reference)
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
}

extension MessageManager {
    func isInOrder(_ batch: String) {
        if let batchData = batch.utf8Data, let batchObject = try? JSONSerialization.jsonObject(with: batchData, options: []) as? [String: Any], let events = batchObject["batch"] as? [[String: Any]] {
            if isSortedByTrackKey(array: events) {
                print("Everything is in order")
            } else {
                print("Events are not in order")
            }
        }
    }
    
    func extractTrackNumber(from trackString: String) -> Int? {
        // Extract the number after "Track: "
        if let numberString = trackString.split(separator: " ").last,
           let number = Int(numberString) {
            return number
        }
        return nil
    }
    
    func isSortedByTrackKey(array: [[String: Any]]) -> Bool {
        for (prev, next) in zip(array, array.dropFirst()) {
            // Safely unwrap the "track" value and ensure it's a String
            if let prevTrackString = prev["event"] as? String,
               let nextTrackString = next["event"] as? String,
               let prevTrack = extractTrackNumber(from: prevTrackString),
               let nextTrack = extractTrackNumber(from: nextTrackString) {
                print("Breaking at -->\(prevTrack) :: \(nextTrack)")
                if nextTrack - 1 != prevTrack {
                    print("Breaking at -->\(prevTrackString) :: \(nextTrackString)")
                    return false
                }
            } else {
                // Handle missing or invalid "track" value
                return false
            }
        }
        return true
    }
}
