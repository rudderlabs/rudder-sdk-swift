//
//  RSClient+Startup.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

extension RSClient {
        
    internal func platformStartup() {
        let logPlugin = RSLoggingPlugin()
        logPlugin.analytics = self
        logPlugin.loggingEnabled(config.logLevel != .none)
        add(plugin: logPlugin)
        
        // add segment destination plugin unless
        // asked not to via configuration.
        let segmentDestination = RudderDestinationPlugin()
        segmentDestination.analytics = self
        add(plugin: segmentDestination)
        
        // Setup platform specific plugins
        if let platformPlugins = platformPlugins() {
            for plugin in platformPlugins {
                add(plugin: plugin)
            }
        }
        
        setupSettingsCheck()
    }
    
    internal func platformPlugins() -> [PlatformPlugin]? {
        var plugins = [PlatformPlugin]()
        
        // add context plugin as well as it's platform specific internally.
        // this must come first.
        plugins.append(RSContextPlugin())
        
        plugins += Vendor.current.requiredPlugins

        // setup lifecycle if desired
        if config.trackLifecycleEvents {
            #if os(iOS) || os(tvOS)
            plugins.append(RSiOSLifecycleEvents())
            #endif
            #if os(watchOS)
            plugins.append(RSwatchOSLifecycleEvents())
            #endif
            #if os(macOS)
            // placeholder - need to build this
            // plugins.append(macOSLifecycleEvents())
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
        // do the first one
        checkSettings()
        // set up return-from-background to do it again.
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
        // do the first one
        checkSettings()
        // now set up a timer to do it every 24 hrs.
        // mac apps change focus a lot more than iOS apps, so this
        // seems more appropriate here.
        RSQueueTimer.schedule(interval: .days(1), queue: .main) {
            self.checkSettings()
        }
    }
}
#endif
