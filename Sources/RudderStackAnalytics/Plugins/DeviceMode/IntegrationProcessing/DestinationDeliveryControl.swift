//
//  DestinationDeliveryControl.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 07/09/26.
//

import Foundation

// MARK: - DestinationDeliveryControl
/**
 Admission control for device-mode delivery, held per destination.

 Owns both halves of the decision — whether a destination is ready, and what it is holding while it
 initializes — so the two can never disagree. Keeping them apart is what lets a live event overtake
 events buffered before it: readiness flips, and the buffered events are handed off a moment later.

 A destination is in one of three states:
 - unknown: neither initializing nor ready, so events are skipped, which is the SDK's existing behavior
 - buffering: initialization is in flight, so events are held
 - ready: events are delivered

 Each destination carries its own lock, and the `deliver` closures run while that lock is held. That
 is what makes the hand-off ordering a guarantee rather than a race: an event admitted before
 `markReady` is buffered and handed off with the rest, and one admitted during the hand-off waits on
 the lock until it finishes. Because the lock is per destination, a slow destination delays only its
 own events. The lock is recursive so that a destination which sends an event from inside its own
 delivery does not deadlock itself.

 A destination's buffer is bounded; when it is full the oldest event is dropped (keep-newest).
 */
final class DestinationDeliveryControl {

    /// What happened to one admitted event.
    enum Verdict: Equatable {
        case delivered
        case buffered
        case skipped
    }

    private final class DestinationState {
        let lock = NSRecursiveLock()
        /// Events held while initialization is in flight; `nil` when not buffering.
        var buffered: [Event]?
        /// The consent decision in force for this destination. Events created under an earlier one
        /// are never delivered — held or ready makes no difference. It outlives the hold, so it is
        /// cleared only when the destination stops being ready.
        var heldFromEpoch: UInt64 = 0
        var isReady = false

        func withLock(_ block: (DestinationState) -> Void) {
            self.lock.lock()
            defer { self.lock.unlock() }
            block(self)
        }
    }

    private static let maxBufferSize = Constants.defaultConfig.maxHeldEventsPerDestination
    /// An event with no marker belongs to no decision, so it is skipped rather than replayed.
    private static func epoch(of event: Event) -> UInt64 {
        (event as? ConsentEpochCarrying)?.consentEpoch ?? 0
    }
    @Synchronized private var destinations: [String: DestinationState] = [:]

    /**
     Starts holding events for a destination that is initializing.

     Repeat calls carrying the same consent decision are idempotent: one re-initialization begins
     buffering from more than one call site, so whatever is already held must survive. A call
     carrying a different decision replaces the hold — everything buffered was admitted under the
     previous decision and must not be replayed against this one.

     - Parameters:
        - key: The destination key.
        - epoch: The consent decision in force. Events created under an earlier one are skipped;
                 zero means no decision has been taken yet, so everything is held.
     */
    func beginBuffering(for key: String, notBefore epoch: UInt64 = 0) {
        let state = self.state(for: key, creatingIfNeeded: true)
        state?.withLock { destination in
            guard destination.buffered == nil || destination.heldFromEpoch != epoch else { return }
            destination.buffered = []
            destination.heldFromEpoch = epoch
        }
    }

    /**
     Decides what happens to one event, delivering it when the destination is ready to receive it.

     - Parameters:
        - event: The event to admit.
        - key: The destination key.
        - deliver: Hands the event to the destination. Runs while the destination's lock is held, so
                   later events for the same destination wait behind it.
     - Returns: The verdict for this event.
     */
    @discardableResult
    func admit(_ event: Event, for key: String, deliver: (Event) -> Void) -> Verdict {
        guard let state = self.state(for: key, creatingIfNeeded: false) else { return .skipped }

        var verdict = Verdict.skipped
        state.withLock { destination in
            // Checked ahead of the branch, not inside the hold: a customer plugin can pause an event
            // and release it after initialization has finished, so the decision it was created under
            // has to be honoured on the ready path too.
            if Self.epoch(of: event) < destination.heldFromEpoch {
                verdict = .skipped
                return
            }
            if var buffered = destination.buffered {
                if buffered.count >= Self.maxBufferSize { buffered.removeFirst() }
                buffered.append(event)
                destination.buffered = buffered
                verdict = .buffered
            } else if destination.isReady {
                deliver(event)
                verdict = .delivered
            }
        }
        return verdict
    }

    /**
     Marks a destination ready and hands off everything it buffered, in arrival order.

     - Parameters:
        - key: The destination key.
        - deliver: Hands the buffered events to the destination. Runs while the destination's lock
                   is held, so a concurrently admitted event cannot overtake them.
     */
    func markReady(for key: String, deliver: ([Event]) -> Void) {
        let state = self.state(for: key, creatingIfNeeded: true)
        state?.withLock { destination in
            let buffered = destination.buffered ?? []
            destination.buffered = nil
            // The boundary is deliberately kept: becoming ready ends the hold, not the consent
            // decision the hold opened under.
            destination.isReady = true
            deliver(buffered)
        }
    }

    /**
     Marks a destination not ready, discarding anything it buffered.

     - Parameter key: The destination key.
     - Returns: The number of buffered events discarded, which the caller reports.
     */
    @discardableResult
    func markNotReady(for key: String) -> Int {
        guard let state = self.state(for: key, creatingIfNeeded: false) else { return 0 }

        var discarded = 0
        state.withLock { destination in
            discarded = destination.buffered?.count ?? 0
            destination.buffered = nil
            destination.heldFromEpoch = 0
            destination.isReady = false
        }
        $destinations.modify { $0.removeValue(forKey: key) }
        return discarded
    }

    /// Drops every destination's state.
    func removeAll() {
        $destinations.modify { $0.removeAll() }
    }

    /// Looks up a destination's state, optionally creating it. The map lock is released before the
    /// destination's own lock is taken, so the two are never held together.
    private func state(for key: String, creatingIfNeeded: Bool) -> DestinationState? {
        var state: DestinationState?
        $destinations.modify { destinations in
            if let existing = destinations[key] {
                state = existing
            } else if creatingIfNeeded {
                let fresh = DestinationState()
                destinations[key] = fresh
                state = fresh
            }
        }
        return state
    }
}
