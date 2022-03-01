//
//  RSClient+Plugins.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

extension RSClient {
        
    internal func addPlugins() {
        let replayQueuePlugin = RSReplayQueuePlugin()
        replayQueuePlugin.client = self
        add(plugin: replayQueuePlugin)
        
        let logPlugin = RSLoggingPlugin()
        logPlugin.client = self
        logPlugin.loggingEnabled(config.logLevel != .none)
        add(plugin: logPlugin)
        
        let segmentDestination = RudderDestinationPlugin()
        segmentDestination.client = self
        add(plugin: segmentDestination)
        
        if let platformPlugins = platformPlugins() {
            for plugin in platformPlugins {
                add(plugin: plugin)
            }
        }
        
        setupSettingsCheck()
    }
    
    internal func platformPlugins() -> [PlatformPlugin]? {
        var plugins = [PlatformPlugin]()
        
        plugins.append(RSContextPlugin())
        
        plugins += Vendor.current.requiredPlugins

        if config.trackLifecycleEvents {
            #if os(iOS) || os(tvOS)
            plugins.append(RSiOSLifecycleEvents())
            #endif
            #if os(watchOS)
            plugins.append(RSwatchOSLifecycleEvents())
            #endif
            #if os(macOS)
            plugins.append(RSmacOSLifecycleEvents())
            #endif
        }
        
        if plugins.isEmpty {
            return nil
        } else {
            return plugins
        }
    }
}

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
extension RSClient {
    internal func setupSettingsCheck() {
        checkSettings()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { (notification) in
            guard let app = notification.object as? UIApplication else { return }
            if app.applicationState == .background {
                self.checkSettings()
            }
        }
    }
}
#elseif os(watchOS)
extension RSClient {
    internal func setupSettingsCheck() {
        checkSettings()
    }
}
#elseif os(macOS)
import Cocoa
extension RSClient {
    internal func setupSettingsCheck() {
        checkSettings()
        RSQueueTimer.schedule(interval: .days(1), queue: .main) {
            self.checkSettings()
        }
    }
}
#endif
