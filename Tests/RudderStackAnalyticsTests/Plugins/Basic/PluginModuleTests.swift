//
//  PluginModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 24/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("Plugin Module Tests")
class PluginModuleTests {
    
    @Test("given PluginChain, when processing event, then executes plugins in correct order")
    func testPluginChainEventProcessingOrder() {
        let analytics = MockProvider.createMockAnalytics()
        let pluginChain = PluginChain(analytics: analytics)
        
        // Add test plugins
        let preProcessPlugin = TestPreProcessPlugin()
        let onProcessPlugin = TestOnProcessPlugin()
        let terminalPlugin = TestTerminalPlugin()
        
        pluginChain.add(plugin: preProcessPlugin)
        pluginChain.add(plugin: onProcessPlugin)
        pluginChain.add(plugin: terminalPlugin)
        
        let event = MockProvider.mockTrackEvent
        pluginChain.process(event: event)
        
        // Verify plugins were set up
        #expect(preProcessPlugin.analytics != nil)
        #expect(onProcessPlugin.analytics != nil)
        #expect(terminalPlugin.analytics != nil)
    }
    
    @Test("given PluginInteractor, when adding and removing plugins, then plugin list is updated correctly")
    func testPluginInteractorAddRemovePlugins() {
        let interactor = PluginInteractor()
        let plugin1 = TestPreProcessPlugin()
        let plugin2 = TestOnProcessPlugin()
        
        // Add plugins
        interactor.add(plugin: plugin1)
        interactor.add(plugin: plugin2)
        
        #expect(interactor.pluginList.count == 2)
        
        // Remove plugin
        interactor.remove(plugin: plugin1)
        
        #expect(interactor.pluginList.count == 1)
        #expect(interactor.pluginList.first === plugin2)
    }
    
    @Test("given PluginInteractor, when finding plugins by type, then returns correct instances")
    func testPluginInteractorFindPluginsByType() {
        let interactor = PluginInteractor()
        let plugin1 = TestPreProcessPlugin()
        let plugin2 = TestOnProcessPlugin()
        
        interactor.add(plugin: plugin1)
        interactor.add(plugin: plugin2)
        
        let foundPlugin = interactor.find(TestPreProcessPlugin.self)
        #expect(foundPlugin === plugin1)
        
        let allFoundPlugins = interactor.findAll(TestPlugin.self)
        #expect(allFoundPlugins.count == 2)
    }
    
    // The plugin contract lets intercept return a newly built event rather than the one it was handed.
    // That event cannot carry the consent the SDK recorded, so the chain puts that back; everything the
    // plugin chose, its own messageId and options included, is left as the plugin returned it.
    @Test("given a plugin returning a newly built event, when executed, then the captured context survives and the plugin's identity and options are kept")
    func testExecuteRestoresSdkOwnedStateOnReplacement() {
        let interactor = PluginInteractor()
        interactor.add(plugin: EventReplacingTestPlugin())
        var original = TrackEvent(event: "original", options: RudderOption(customContext: ["campaign": "spring"]))
        original.capturedReservedContext = ["consentManagement": ["provider": "custom"]]
        
        let result = interactor.execute(original)
        
        let captured = (result as? ReservedContextCapturing)?.capturedReservedContext?["consentManagement"] as? [String: Any]
        #expect(result?.messageId == EventReplacingTestPlugin.messageId, "the plugin's messageId was replaced")
        #expect(result?.options?.customContext?["campaign"] as? String == "plugin", "the plugin's options were replaced")
        #expect(captured?["provider"] as? String == "custom", "the captured context was not preserved")
        #expect((result as? TrackEvent)?.event == "replaced", "the plugin's payload must be kept")
    }
}

// MARK: - Test Helper Plugins

class TestPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: Event) -> Event? {
        return event
    }
    
    func teardown() {
        analytics = nil
    }
}

class TestPreProcessPlugin: TestPlugin {
    override init() {
        super.init()
        pluginType = .preProcess
    }
}

class TestOnProcessPlugin: TestPlugin {
    override init() {
        super.init()
        pluginType = .onProcess
    }
}

class TestTerminalPlugin: TestPlugin {
    override init() {
        super.init()
        pluginType = .terminal
    }
}

/// A plugin that returns a newly built event, with its own messageId and options, instead of the one it was handed.
class EventReplacingTestPlugin: TestPlugin {
    static let messageId = "plugin-message-id"

    override func intercept(event: Event) -> Event? {
        var replacement = TrackEvent(event: "replaced", options: RudderOption(customContext: ["campaign": "plugin"]))
        replacement.messageId = Self.messageId
        return replacement
    }
}
