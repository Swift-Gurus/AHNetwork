//
//  GenericNetworkLayerBuilder.swift
//  AHNetwork
//
//  Created by Alex Hmelevski on 2020-02-15.
//

import Foundation

@available(OSX 10.15, *)
public class GenericNetworkLayerBuilder {
    
    public var sessionConfiguration: URLSessionConfiguration = .default
    public var dataSerializer: DataDeserializer = JSONSerializer()
    
    public init() {}
    
    private var urlSession: URLSession {
        return URLSession(configuration: sessionConfiguration)
    }
    private var provider: AHNetworkProvider {
        return AHNetworkProvider(session: urlSession)
    }
    
    private var socketProvider: SocketProvider {
        WebTaskNode(session: urlSession)
    }
    
    private var coreNetwork: AHCoreNetwork {
        return AHCoreNetworkImp(networkProvider: provider, socketProvider: socketProvider)
    }
    
    public func getNetworkLayer<F: NetworkRequestFactory>(using factory: F) -> GenericNetworkLayer<F> {
        return GenericNetworkLayer(coreNetwork: coreNetwork,
                                   requestFactory: factory,
                                   serializer: dataSerializer)
    }
}
