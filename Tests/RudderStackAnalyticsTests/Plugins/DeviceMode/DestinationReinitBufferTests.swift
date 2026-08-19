//
//  DestinationReinitBufferTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("DestinationReinitBuffer Tests")
struct DestinationReinitBufferTests {

    private let destinationKey = "MockDestination"

    @Test("given no open window, when appending an event, then it is not buffered")
    func testAppendOutsideWindowIsNoOp() {
        let buffer = DestinationReinitBuffer()

        buffer.append(event: makeEvent(named: "event-1"), for: destinationKey)

        #expect(buffer.close(for: destinationKey).isEmpty, "Appends outside the re-init window must be no-ops — the buffer is not a general-purpose queue.")
    }

    @Test("given an open window, when appending events, then close returns them in arrival order")
    func testCloseReturnsEventsInArrivalOrder() {
        let buffer = DestinationReinitBuffer()
        buffer.open(for: destinationKey)

        buffer.append(event: makeEvent(named: "event-1"), for: destinationKey)
        buffer.append(event: makeEvent(named: "event-2"), for: destinationKey)
        buffer.append(event: makeEvent(named: "event-3"), for: destinationKey)

        #expect(eventNames(of: buffer.close(for: destinationKey)) == ["event-1", "event-2", "event-3"], "Replay order must match arrival order (FIFO).")
    }

    @Test("given a closed window, when closing again, then no events are returned")
    func testCloseTwiceReturnsEmpty() {
        let buffer = DestinationReinitBuffer()
        buffer.open(for: destinationKey)
        buffer.append(event: makeEvent(named: "event-1"), for: destinationKey)

        buffer.close(for: destinationKey)

        #expect(buffer.close(for: destinationKey).isEmpty, "Closing must drain the buffer — a second close finds no window.")
    }

    @Test("given a window with buffered events, when reopening, then the previous buffer is cleared")
    func testReopenClearsPreviousBuffer() {
        let buffer = DestinationReinitBuffer()
        buffer.open(for: destinationKey)
        buffer.append(event: makeEvent(named: "stale-event"), for: destinationKey)

        buffer.open(for: destinationKey)

        #expect(buffer.close(for: destinationKey).isEmpty, "Reopening starts a fresh window — stale events from an earlier window must not leak into it.")
    }

    @Test("given a full buffer, when appending one more event, then the oldest is dropped")
    func testBoundDropsOldestWhenFull() {
        let buffer = DestinationReinitBuffer()
        let maxSize = Constants.defaultConfig.destinationReinitBufferSize
        buffer.open(for: destinationKey)

        for index in 1...(maxSize + 1) {
            buffer.append(event: makeEvent(named: "event-\(index)"), for: destinationKey)
        }

        let events = eventNames(of: buffer.close(for: destinationKey))
        #expect(events.count == maxSize, "The buffer must never exceed its bound.")
        #expect(events.first == "event-2", "Keep-newest policy: the oldest event is dropped when full.")
        #expect(events.last == "event-\(maxSize + 1)", "The newest event must always be retained.")
    }

    @Test("given two destinations with open windows, when buffering, then they are isolated")
    func testDestinationsBufferIndependently() {
        let buffer = DestinationReinitBuffer()
        let otherKey = "OtherDestination"
        buffer.open(for: destinationKey)
        buffer.open(for: otherKey)

        buffer.append(event: makeEvent(named: "event-a"), for: destinationKey)
        buffer.append(event: makeEvent(named: "event-b"), for: otherKey)

        #expect(eventNames(of: buffer.close(for: destinationKey)) == ["event-a"])
        #expect(eventNames(of: buffer.close(for: otherKey)) == ["event-b"], "Closing one destination's window must never touch another's.")
    }

    @Test("given open windows with events, when removeAll is called, then everything is discarded")
    func testRemoveAllDiscardsEverything() {
        let buffer = DestinationReinitBuffer()
        buffer.open(for: destinationKey)
        buffer.append(event: makeEvent(named: "event-1"), for: destinationKey)

        buffer.removeAll()

        #expect(buffer.close(for: destinationKey).isEmpty)
    }
}

// MARK: - Helpers
extension DestinationReinitBufferTests {

    private func makeEvent(named name: String) -> Event {
        TrackEvent(event: name)
    }

    private func eventNames(of events: [Event]) -> [String] {
        events.compactMap { ($0 as? TrackEvent)?.event }
    }
}
