//
//  GenericNetworkLayerBuilder.swift
//  AHNetwork
//
//  Created by Alex Hmelevski on 2020-02-15.
//

import Foundation

@available(iOS 13.0, *)
final class SocketDelegate: NSObject, URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        
    }

    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        
    }
}

@available(OSX 10.15, *)
public class GenericNetworkLayerBuilder {
    
    public var sessionConfiguration: URLSessionConfiguration = .default
    public var dataSerializer: DataDeserializer = JSONSerializer()
    public init() {}
    
    private var urlSession: URLSession {
        if #available(iOS 13.0, *) {
            return .init(configuration: sessionConfiguration)
        } else {
            return .init(configuration: sessionConfiguration)
        }
    }
    
    @available(iOS 13.0, *)
    private var ahSession: AHSession {
        .init(configuration: sessionConfiguration)
    }
    private var provider: AHNetworkProvider {
        return AHNetworkProvider(session: urlSession)
    }
    
    @available(iOS 13.0, *)
    private var socketProvider: SocketProvider {
        WebTaskNode(session: ahSession)
    }
    
    private var coreNetwork: AHCoreNetwork {
        if #available(iOS 13.0, *) {
            return AHCoreNetworkImp(networkProvider: provider,
                                    socketProvider: socketProvider)
        } else {
            return AHCoreNetworkImp(networkProvider: provider)
        }
    }
    
    public func getNetworkLayer<F: NetworkRequestFactory>(using factory: F) -> GenericNetworkLayer<F> {
        return GenericNetworkLayer(coreNetwork: coreNetwork,
                                   requestFactory: factory,
                                   serializer: dataSerializer)
    }
}
