//
//  MessageUploader.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/10/24.
//

import Foundation

// MARK: - MessageUploader
/**
 This class handles sequential batch uploads, ensuring each upload is performed one after the other.
 */
class MessageUploader {
    private var analytics: AnalyticsClient
    private var uploadQueue = DispatchQueue(label: "rudderstack.message.upload.queue")
    private var isUploading = false
    private var httpClient: HttpClient?
    
    @Synchronized private var pendingUploads: [UploadItem] = []
    
    var delegate: MessageUploaderDelegate?
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.httpClient = HttpClient(analytics: analytics)
    }
    
    func addToQueue(_ item: UploadItem) {
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.pendingUploads.contains(item) {
                self.pendingUploads.append(item)
                self.startUploadIfNeeded()
            } else {
                print("Item with uniqueID \(item.reference) is already in the queue")
            }
        }
    }
    
    // Method to start the upload if not already uploading
    private func startUploadIfNeeded() {
        guard !isUploading else { return }
        isUploading = true
        processNextUpload()
    }
    
    private func processNextUpload() {
        guard !pendingUploads.isEmpty else {
            isUploading = false
            return
        }
        
        let nextItem = pendingUploads.removeFirst()
        Task {
            let success = await upload(item: nextItem)
            if success {
                print("Uploaded successfully: \(nextItem.reference)")
                self.delegate?.didFinishUploading(item: nextItem)
                processNextUpload()
            } else {
                print("Upload failed: \(nextItem.reference), dropping all pending uploads")
                pendingUploads.insert(nextItem, at: 0)
                clearQueueAndStop() //Drops all uploads.. Wait for next set of upload actions to ensure the event ordering..
            }
        }
    }
    
    private func clearQueueAndStop() {
        self.delegate?.resetReferenceCache(pendingUploads)
        pendingUploads.removeAll()
        isUploading = false
    }
    
    private func upload(item: UploadItem) async -> Bool {
        do {
            _ = try await self.httpClient?.postBatchEvents(item.content)
            return true
        } catch {
            return false
        }
    }
}


// MARK: - UploadItem
/**
 This model facilitates the creation of an upload action.
 */
struct UploadItem: Equatable {
    @AutoEquatable var reference: String
    let content: String
}


// MARK: - MessageUploaderDelegate
protocol MessageUploaderDelegate {
    func didFinishUploading(item: UploadItem)
    func resetReferenceCache(_ pendingUploads: [UploadItem])
}
