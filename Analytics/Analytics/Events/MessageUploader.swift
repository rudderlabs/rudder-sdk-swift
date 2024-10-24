//
//  MessageUploader.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/10/24.
//

import Foundation

class MessageUploader {
    private var manager: MessageManager
    
    private var uploadQueue = DispatchQueue(label: "rudderstack.message.upload.queue")
    @Synchronized private var pendingUploads: [UploadItem] = []
    private var isUploading = false
    
    init(manager: MessageManager) {
        self.manager = manager
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
                self.manager.responseChannel.send(nextItem.reference)
                processNextUpload()
            } else {
                print("Upload failed: \(nextItem.reference), dropping all pending uploads")
                clearQueueAndStop()
            }
        }
    }
    
    private func clearQueueAndStop() {
        pendingUploads.removeAll()
        isUploading = false
    }
    
    private func upload(item: UploadItem) async -> Bool {
        do {
            _ = try await self.manager.httpClient?.postBatchEvents(item.content)
            return true
        } catch {
            return false
        }
    }
}


struct UploadItem: Equatable {
    let content: String
    let reference: String
    
    static func == (lhs: UploadItem, rhs: UploadItem) -> Bool {
        return lhs.reference == rhs.reference
    }
}
