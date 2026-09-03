//
//  DestinationReinitBuffer.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Foundation

// MARK: - DestinationReinitBuffer
/**
 A bounded, per-destination hold for events that arrive while a destination is re-initializing
 after a consent grant.

 A destination's buffer exists only between `open` and `close` — the re-init window. Appends
 outside the window are no-ops, so every other not-ready moment keeps the SDK's existing
 skip behavior. When a buffer is full, the oldest event is dropped (keep-newest policy).
 This is not a general-purpose queue.
 */

final class DestinationReinitBuffer {
    
    private static let maxBufferSize = Constants.defaultConfig.destinationReinitBufferSize
    @Synchronized private var buffers: [String: [Event]] = [:]
    
    /**
     Opens the re-init window for a destination, clearing any previous buffer.
     
     - Parameter key: The destination key.
     */
    func open(for key: String) {
        $buffers.modify { buffers in
            buffers[key] = []
        }
    }
    
    /**
     Buffers an event if the destination's re-init window is open; no-op otherwise.
     
     - Parameters:
        - event: The event to hold.
        - key: The destination key.
     */
    func append(event: Event, for key: String) {
        $buffers.modify { buffers in
            guard var buffer = buffers[key] else { return }
            if buffer.count >= Self.maxBufferSize {
                buffer.removeFirst()
            }
            buffer.append(event)
            buffers[key] = buffer
        }
    }
    
    /**
     Closes the re-init window for a destination and returns the held events in arrival order.
     
     - Parameter key: The destination key.
     - Returns: The buffered events; empty when no window was open.
     */
    @discardableResult
    func close(for key: String) -> [Event] {
        var events: [Event] = []
        $buffers.modify { buffers in
            events = buffers.removeValue(forKey: key) ?? []
        }
        return events
    }
    
    /**
     Discards all buffers and windows.
     */
    func removeAll() {
        $buffers.modify { buffers in
            buffers.removeAll()
        }
    }
}
