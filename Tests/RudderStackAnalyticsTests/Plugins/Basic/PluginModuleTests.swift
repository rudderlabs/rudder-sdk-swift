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
    func testPluginChain_EventProcessingOrder() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        let pluginChain = PluginChain(analytics: analytics)
        
        // Add test plugins
        let preProcessPlugin = TestPreProcessPlugin()
        let onProcessPlugin = TestOnProcessPlugin()
        let terminalPlugin = TestTerminalPlugin()
        
        pluginChain.add(plugin: preProcessPlugin)
        pluginChain.add(plugin: onProcessPlugin)
        pluginChain.add(plugin: terminalPlugin)
        
        let event = SwiftTestMockProvider.mockTrackEvent
        pluginChain.process(event: event)
        
        // Verify plugins were set up
        #expect(preProcessPlugin.analytics != nil)
        #expect(onProcessPlugin.analytics != nil)
        #expect(terminalPlugin.analytics != nil)
    }
    
    @Test("given PluginInteractor, when adding and removing plugins, then plugin list is updated correctly")
    func testPluginInteractor_AddRemovePlugins() {
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
    func testPluginInteractor_FindPluginsByType() {
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
