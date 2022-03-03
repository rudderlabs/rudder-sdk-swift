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
        
        let logPlugin = RSLoggerPlugin()
        logPlugin.client = self
        logPlugin.loggingEnabled(config.logLevel != .none)
        add(plugin: logPlugin)
        
        let integrationPlugin = RSIntegrationPlugin()
        integrationPlugin.client = self
        add(plugin: integrationPlugin)
        
        let segmentDestination = RudderDestinationPlugin()
        segmentDestination.client = self
        add(plugin: segmentDestination)
        
        add(plugin: RSGDPRPlugin())
        
        if let platformPlugins = platformPlugins() {
            for plugin in platformPlugins {
                add(plugin: plugin)
            }
        }
        
        setupServerConfigCheck()
    }
    
    internal func platformPlugins() -> [RSPlatformPlugin]? {
        var plugins = [RSPlatformPlugin]()
        
        plugins.append(RSContextPlugin())
        
        plugins += Vendor.current.requiredPlugins

        if config.trackLifecycleEvents {
            #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            plugins.append(RSiOSLifecycleEvents())
            #endif
            #if os(watchOS)
            plugins.append(RSwatchOSLifecycleEvents())
            #endif
            #if os(macOS)
            plugins.append(RSmacOSLifecycleEvents())
            #endif
        }
        
        if config.recordScreenViews {
            #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            plugins.append(RSiOSScreenViewEvents())
            #endif
            #if os(watchOS)
            plugins.append(RSwatchOSScreenViewEvents())
            #endif
            #if os(macOS)
            plugins.append(RSmacOSScreenViewEvents())
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
    internal func setupServerConfigCheck() {
        checkServerConfig()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { (notification) in
            guard let app = notification.object as? UIApplication else { return }
            if app.applicationState == .background {
                self.checkServerConfig()
            }
        }
    }
}
#elseif os(watchOS)
extension RSClient {
    internal func setupServerConfigCheck() {
        checkServerConfig()
    }
}
#elseif os(macOS)
import Cocoa
extension RSClient {
    internal func setupServerConfigCheck() {
        checkServerConfig()
        RSQueueTimer.schedule(interval: .days(1), queue: .main) {
            self.checkServerConfig()
        }
    }
}
#endif
