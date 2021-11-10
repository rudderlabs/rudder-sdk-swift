//
//  RSCustomFactoryManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 23/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSCustomFactoryManager: RSBaseManager {
    struct Input {
        let serverConfig: RSServerConfig
        let config: RSConfig?
    }
    
    struct Output {
        let integrationOperationList: [RSIntegrationOperation]
    }
    
    private var serverConfig: RSServerConfig?
    private var config: RSConfig?
    private var integrationOperationList = [RSIntegrationOperation]()
        
    func transform(input: Input) -> Output {
        self.serverConfig = input.serverConfig
        self.config = input.config
        initiateFactories()
        return Output(integrationOperationList: integrationOperationList)
    }
    
    private func initiateFactories() {
        logDebug("EventRepository: initiating factories")
        guard let config = config, !config.customFactories.isEmpty else {
            logDebug("EventRepository: No native SDK is found in the config")
            return
        }
        for factory in config.customFactories {
            let integration = factory.initiate(nil, client: RSClient.shared, rudderConfig: config)
            logDebug("Initiating custom SDK factory \(factory.key)")
            let integrationOperation = RSIntegrationOperation(key: factory.key, integration: integration)
            integrationOperationList.append(integrationOperation)
            logDebug("Initiated custom SDK factory \(factory.key)")            
        }
    }
}
