//
//  RSFactoryManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 23/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSFactoryManager: RSBaseManager {
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
        if let destinations = serverConfig?.destinations {
            logDebug("EventRepository: initiating factories")
            guard let config = config, !config.factories.isEmpty else {
                logDebug("EventRepository: No native SDK is found in the config")
                return
            }
            if destinations.isEmpty {
                logDebug("EventRepository: No native SDK factory is found in the server config")
            } else {
                for factory in config.factories {
                    if let destination = destinations.first(where: { $0.destinationDefinition?.name == factory.key }), destination.enabled {
                        if let destinationConfig = destination.destinationDefinition?.destinationConfig {
                            let integration = factory.initiate(destinationConfig, client: RSClient.shared, rudderConfig: config)
                            logDebug("Initiating native SDK factory \(factory.key)")
                            let integrationOperation = RSIntegrationOperation(key: factory.key, integration: integration)
                            integrationOperationList.append(integrationOperation)
                            logDebug("Initiated native SDK factory \(factory.key)")
                        }
                    }
                }
            }
        } else {
            logDebug("EventRepository: no device mode present")
        }
    }
}
