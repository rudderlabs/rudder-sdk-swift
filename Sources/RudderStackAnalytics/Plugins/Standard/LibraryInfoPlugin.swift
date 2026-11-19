//
//  LibraryInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/12/24.
//

import Foundation

// MARK: - LibraryInfoPlugin
/**
 A plugin created to append library information to the event context.
 */
final class LibraryInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?

    private let wrapperLibraryInfo: () -> WrapperLibrary.Info?

    init(wrapperLibraryInfo: @escaping () -> WrapperLibrary.Info? = { WrapperLibrary.info }) {
        self.wrapperLibraryInfo = wrapperLibraryInfo
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        var info: [String: Any] = ["library": self.preparedLibraryInfo]
        if let wrapper = wrapperLibraryInfo() {
            info["wrapperLibrary"] = ["name": wrapper.name, "version": wrapper.version]
        }
        return event.addToContext(info: info)
    }
    
    private var preparedLibraryInfo: [String: Any] = {
        return ["name": RSLibraryName, "version": RSVersion]
    }()
}

// MARK: - WrapperLibrary
/**
 The name and version of a RudderStack SDK that wraps this SDK, for example the Flutter SDK.

 When set, every event of every `Analytics` instance in the process carries it as `context.wrapperLibrary`.
 `context.library` keeps this SDK's own name and version.

 It is not part of the public API: a caller needs `@_spi(RudderStackWrapper) import RudderStackAnalytics`.
 */
@_spi(RudderStackWrapper)
public enum WrapperLibrary {

    typealias Info = (name: String, version: String)

    @Synchronized static var info: Info?

    /**
     Sets the wrapper's name and version. Call it before the first event to cover every event.
     */
    public static func set(name: String, version: String) {
        info = (name, version)
    }
}
