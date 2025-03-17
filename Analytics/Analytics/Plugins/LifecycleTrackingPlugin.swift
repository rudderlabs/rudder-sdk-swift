//
//  LifecycleTrackingPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 10/03/25.
//

import Foundation

// MARK: - LifecycleTrackingPlugin
/**
 A plugin created to track app lifecycle events.
 */
final class LifecycleTrackingPlugin: Plugin {
    var pluginType: PluginType = .manual
    
    var analytics: AnalyticsClient?
    var appVersion: AppVersion?
    
    @Synchronized private var isFirstLaunch = true
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        
        self.appVersion = self.prepareAppVersion()
        self.updateAppVersion()
        
        if analytics.configuration.trackApplicationLifecycleEvents {
            self.trackAppInstallationEvents()
            analytics.lifecycleObserver?.addObserver(self)
        }
    }
    
    deinit {
        analytics?.lifecycleObserver?.removeObserver(self)
    }
}

// MARK: - LifecycleEventListener

extension LifecycleTrackingPlugin: LifecycleEventListener {
    func onBecomeActive() {
        var properties: [String: Any] = [:]
        if isFirstLaunch {
            properties["version"] = appVersion?.currentVersionName
        }
        properties["from_background"] = !isFirstLaunch
        isFirstLaunch = false
        self.analytics?.track(name: LifecycleEvent.applicationOpened.rawValue, properties: properties)
    }
    
    func onBackground() {
        self.analytics?.track(name: LifecycleEvent.applicationBackgrounded.rawValue)
    }
}

// MARK: - Installation Events

extension LifecycleTrackingPlugin {
    func trackAppInstallationEvents() {
        guard let appVersion else { return }
        if appVersion.previousBuild == -1 {
            self.analytics?.track(name: LifecycleEvent.applicationInstalled.rawValue, properties: [
                "version": appVersion.currentVersionName ?? "",
                "build": appVersion.currentBuild
            ])
            self.onBecomeActive()
        } else {
            guard appVersion.currentBuild != appVersion.previousBuild || appVersion.currentVersionName != appVersion.previousVersionName else { return }
            self.analytics?.track(name: LifecycleEvent.applicationUpdated.rawValue, properties: [
                "version": appVersion.currentVersionName ?? "",
                "build": appVersion.currentBuild,
                "previous_version": appVersion.previousVersionName ?? "",
                "previous_build": appVersion.previousBuild
            ])
        }
    }
}

// MARK: - Version Updaters

extension LifecycleTrackingPlugin {
    private func prepareAppVersion() -> AppVersion {
        let bundle = Bundle.main
        let currentVersionName = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let currentBuild = Int(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0
        
        return AppVersion(
            currentVersionName: currentVersionName,
            currentBuild: currentBuild,
            previousVersionName: self.analytics?.storage.read(key: Constants.StorageKeys.appVersion),
            previousBuild: self.analytics?.storage.read(key: Constants.StorageKeys.appBuild) ?? -1
        )
    }
    
    private func updateAppVersion() {
        if let versionName = self.appVersion?.currentVersionName {
            self.analytics?.storage.write(value: versionName, key: Constants.StorageKeys.appVersion)
        }
        self.analytics?.storage.write(value: self.appVersion?.currentBuild, key: Constants.StorageKeys.appBuild)
    }
}

// MARK: - AppVersion

struct AppVersion {
    var currentVersionName: String?
    var currentBuild: Int
    var previousVersionName: String?
    var previousBuild: Int
}

// MARK: - LifecycleEvent

enum LifecycleEvent: String {
    case applicationInstalled = "Application Installed"
    case applicationUpdated = "Application Updated"
    case applicationOpened = "Application Opened"
    case applicationBackgrounded = "Application Backgrounded"
}
