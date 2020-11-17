//
//  AHGenericNetworkLayer.swift
//  AHNetwork
//
//  Created by Alex Hmelevski on 2020-02-15.
//

import Foundation
import ALResult
import Combine

public protocol NetworkRequestFactory {
    associatedtype RequestType
    func getRequest(of type: RequestType) -> IRequest
}

@available(OSX 10.15, *)
open class GenericNetworkLayer<RequestFactory: NetworkRequestFactory> {

    private let coreNetwork: AHCoreNetwork
    private let requestFactory: RequestFactory
    private let serializer: DataDeserializer

    init(coreNetwork: AHCoreNetwork,
         requestFactory: RequestFactory,
         serializer: DataDeserializer) {
        self.coreNetwork = coreNetwork
        self.requestFactory = requestFactory
        self.serializer = serializer
    }

    /// Generic method to send request of type supported by factory
    ///
    /// - Parameters:
    ///   - type: request type
    ///   - completion: closure with DictionaryMappable object
    ///
    public func sendRequest<T>(of type: RequestFactory.RequestType, completion: @escaping ResultClosure<T>) where T: Decodable {
        let request = requestFactory.getRequest(of: type)
        coreNetwork.send(request: request) { [weak self] (result) in
            guard let `self` = self else { return }
            result.tryMap(self.serializer.convertToObject) » completion
        }
    }
    
    @available(iOS 13.0, *)
    public func send<Object>(requestOfType type: RequestFactory.RequestType) -> AnyPublisher<Object, Error>  where Object: Decodable {
        let request = requestFactory.getRequest(of: type)
        return coreNetwork.send(request: request)
                          .map({ $0.data })
                          .tryMap({ try self.serializer.convertToObject(data: $0) })
                          .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    public func listenSocketForObject<Object>(requestOfType type: RequestFactory.RequestType) -> AnyPublisher<Object, Error>  where Object: Decodable {
        let request = requestFactory.getRequest(of: type)
        return coreNetwork.receiveSocketData(request: request)
                          .tryMap({ try self.serializer.convertToObject(data: $0) })
                          .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    public func listenSocketForString(requestOfType type: RequestFactory.RequestType) -> AnyPublisher<String, Error> {
        let request = requestFactory.getRequest(of: type)
        return coreNetwork.receiveSocketMessage(request: request)
                          .eraseToAnyPublisher()
    }

}
