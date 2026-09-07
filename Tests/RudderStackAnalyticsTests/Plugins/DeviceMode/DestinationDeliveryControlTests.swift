//
//  DestinationDeliveryControlTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 07/09/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("DestinationDeliveryControl Tests")
struct DestinationDeliveryControlTests {

    private let destinationKey = "MockDestination"

    @Test("given an unknown destination, when admitting an event, then it is skipped")
    func testEventForUnknownDestinationIsSkipped() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()

        let verdict = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        #expect(verdict == .skipped, "A destination that is neither buffering nor ready keeps the existing skip behavior.")
        #expect(recorder.names.isEmpty, "A skipped event must never reach the delivery path.")
    }

    @Test("given a buffering destination, when admitting events, then they are buffered rather than delivered")
    func testEventsAreBufferedWhileBuffering() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)

        let verdict = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        #expect(verdict == .buffered)
        #expect(recorder.names.isEmpty, "A buffered event must not be delivered until the destination is released.")
    }

    @Test("given buffered events, when marked ready, then they hand off in arrival order and the destination delivers")
    func testMarkReadyHandsOffBufferedEventsInOrderThenDelivers() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        for name in ["event-1", "event-2", "event-3"] {
            _ = control.admit(makeEvent(named: name), for: destinationKey) { recorder.append($0) }
        }

        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }

        #expect(recorder.names == ["event-1", "event-2", "event-3"], "Replay order must match arrival order (FIFO).")

        let verdict = control.admit(makeEvent(named: "event-4"), for: destinationKey) { recorder.append($0) }
        #expect(verdict == .delivered, "Once released, the destination delivers directly.")
        #expect(recorder.names == ["event-1", "event-2", "event-3", "event-4"])
    }

    @Test("given a destination just marked ready, when a live event is admitted, then it is enqueued behind the buffered events")
    func testAdmitAfterMarkReadyIsEnqueuedBehindBufferedEvents() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        _ = control.admit(makeEvent(named: "buffered-1"), for: destinationKey) { recorder.append($0) }
        _ = control.admit(makeEvent(named: "buffered-2"), for: destinationKey) { recorder.append($0) }

        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }
        _ = control.admit(makeEvent(named: "live-3"), for: destinationKey) { recorder.append($0) }

        #expect(recorder.names == ["buffered-1", "buffered-2", "live-3"], "A live event must never overtake events buffered before it.")
    }

    @Test("given a destination that never buffered, when marked ready, then it delivers directly")
    func testMarkReadyWithoutBufferingStartsDelivery() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()

        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }
        let verdict = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        #expect(verdict == .delivered, "A destination created without a buffering window still has to start delivering.")
        #expect(recorder.names == ["event-1"])
    }

    @Test("given a buffering destination, when buffering begins again, then already held events are retained")
    func testBeginBufferingIsIdempotent() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        _ = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        control.beginBuffering(for: destinationKey)
        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }

        #expect(recorder.names == ["event-1"], "Buffering is begun from several call sites for one re-initialization; a repeat call must not drop what is already held.")
    }

    @Test("given buffered events, when the destination is marked not ready, then they are discarded")
    func testMarkNotReadyDiscardsBufferedEvents() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        _ = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        let discarded = control.markNotReady(for: destinationKey)

        #expect(discarded == 1, "The caller logs how many events a failed initialization dropped.")
        #expect(recorder.names.isEmpty)

        let verdict = control.admit(makeEvent(named: "event-2"), for: destinationKey) { recorder.append($0) }
        #expect(verdict == .skipped, "A destination that failed to initialize must not keep holding events.")
    }

    @Test("given a released destination, when it is marked not ready, then it stops delivering")
    func testMarkNotReadyStopsDelivery() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }

        _ = control.markNotReady(for: destinationKey)
        let verdict = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        #expect(verdict == .skipped, "Consent revocation marks a live destination not ready; delivery must stop immediately.")
    }

    @Test("given a full buffer, when admitting one more event, then the oldest is dropped")
    func testBufferDropsOldestWhenFull() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        let maxSize = Constants.defaultConfig.destinationReinitBufferSize
        control.beginBuffering(for: destinationKey)

        for index in 1...(maxSize + 1) {
            _ = control.admit(makeEvent(named: "event-\(index)"), for: destinationKey) { recorder.append($0) }
        }
        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }

        #expect(recorder.names.count == maxSize, "The buffer must never exceed its bound.")
        #expect(recorder.names.first == "event-2", "Keep-newest policy: the oldest event is dropped when full.")
        #expect(recorder.names.last == "event-\(maxSize + 1)", "The newest event must always be retained.")
    }

    @Test("given two buffering destinations, when one is released, then the other is untouched")
    func testDestinationsAreIsolated() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        let otherKey = "OtherDestination"
        control.beginBuffering(for: destinationKey)
        control.beginBuffering(for: otherKey)
        _ = control.admit(makeEvent(named: "event-a"), for: destinationKey) { recorder.append($0) }
        _ = control.admit(makeEvent(named: "event-b"), for: otherKey) { recorder.append($0) }

        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }

        #expect(recorder.names == ["event-a"], "Releasing one destination must never hand off another's buffered events.")

        control.markReady(for: otherKey) { recorder.append(contentsOf: $0) }
        #expect(recorder.names == ["event-a", "event-b"])
    }

    @Test("given a live event admitted while buffered events are handing off, then it is enqueued behind them")
    func testAdmitDuringHandOffIsEnqueuedBehindBufferedEvents() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        for index in 1...3 {
            _ = control.admit(makeEvent(named: "buffered-\(index)"), for: destinationKey) { recorder.append($0) }
        }

        let handOffStarted = DispatchSemaphore(value: 0)
        let liveAdmitted = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            control.markReady(for: self.destinationKey) { events in
                // Deliberately slow, to hold the hand-off open while a live event is admitted,
                // so the ordering guarantee is tested rather than assumed.
                handOffStarted.signal()
                _ = liveAdmitted.wait(timeout: .now() + 0.2)
                recorder.append(contentsOf: events)
            }
        }

        handOffStarted.wait()
        _ = control.admit(makeEvent(named: "live-4"), for: destinationKey) { recorder.append($0) }
        liveAdmitted.signal()

        #expect(recorder.names == ["buffered-1", "buffered-2", "buffered-3", "live-4"], "A live event admitted mid-hand-off must wait behind the buffered events; admitting it first is the reported live-3-before-buffered-1 defect.")
    }

    @Test("given a destination already marked ready, when marked ready again, then nothing is delivered twice")
    func testBufferedEventsAreDeliveredExactlyOnce() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        _ = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }
        control.markReady(for: destinationKey) { recorder.append(contentsOf: $0) }

        #expect(recorder.names == ["event-1"], "A source-config refresh marks an already-ready destination ready again; that must not redeliver what it once held.")
    }

    @Test("given a destination slow to accept an event, when another destination admits one, then it is not held up")
    func testSlowDestinationDoesNotBlockAnother() {
        let control = DestinationDeliveryControl()
        let slowKey = "SlowDestination"
        let fastKey = "FastDestination"
        control.markReady(for: slowKey) { _ in }
        control.markReady(for: fastKey) { _ in }

        let slowStarted = DispatchSemaphore(value: 0)
        let fastFinished = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            _ = control.admit(self.makeEvent(named: "slow"), for: slowKey) { _ in
                slowStarted.signal()
                _ = fastFinished.wait(timeout: .now() + 1.0)
            }
        }

        slowStarted.wait()
        let start = Date()
        let verdict = control.admit(makeEvent(named: "fast"), for: fastKey) { _ in }
        let elapsed = Date().timeIntervalSince(start)
        fastFinished.signal()

        #expect(verdict == .delivered)
        #expect(elapsed < 0.5, "Locking is per destination, so one destination being slow to accept an event must not stall another's delivery.")
    }

    @Test("given buffering destinations, when everything is removed, then no state survives")
    func testRemoveAllClearsEveryDestination() {
        let control = DestinationDeliveryControl()
        let recorder = Recorder()
        control.beginBuffering(for: destinationKey)
        _ = control.admit(makeEvent(named: "event-1"), for: destinationKey) { recorder.append($0) }

        control.removeAll()

        let verdict = control.admit(makeEvent(named: "event-2"), for: destinationKey) { recorder.append($0) }
        #expect(verdict == .skipped)
        #expect(recorder.names.isEmpty)
    }
}

// MARK: - Helpers
extension DestinationDeliveryControlTests {

    private func makeEvent(named name: String) -> Event {
        TrackEvent(event: name)
    }
}

// MARK: - Recorder
/**
 Collects delivered events in order. Synchronized because the delivery closure runs on whichever
 thread admitted or released the event.
 */
final class Recorder {
    @Synchronized private var recorded: [String] = []

    var names: [String] { recorded }

    func append(_ event: Event) {
        $recorded.modify { $0.append(Self.name(of: event)) }
    }

    func append(contentsOf events: [Event]) {
        $recorded.modify { $0.append(contentsOf: events.map(Self.name(of:))) }
    }

    private static func name(of event: Event) -> String {
        (event as? TrackEvent)?.event ?? ""
    }
}
