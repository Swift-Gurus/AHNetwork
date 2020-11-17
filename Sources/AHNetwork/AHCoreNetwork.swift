//
//  AHCoreNetwork.swift
//  AHFuture
//
//  Created by Alex Hmelevski on 2020-02-15.
//

import Foundation
import ALResult
import Combine


protocol AHCoreNetwork {
    func send(request: IRequest, completion: @escaping ResultClosure<Data>)
    
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    func send(request: IRequest) -> AnyPublisher<AHNetworkResponse, Error>
    
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    func receiveSocketData(request: IRequest) -> AnyPublisher<Data, Error>
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    func receiveSocketMessage(request: IRequest) -> AnyPublisher<String, Error>
}

@available(OSX 10.15, *)
final class AHCoreNetworkImp: AHCoreNetwork {
    

    private let provider: INetworkProvider
    private let socketProvider: SocketProvider
    init(networkProvider: INetworkProvider, socketProvider: SocketProvider) {
        provider = networkProvider
        self.socketProvider = socketProvider
    }

    
    
    @available(iOS 13.0, *)
    func send(request: IRequest) -> AnyPublisher<AHNetworkResponse, Error> {
        return provider.send(request)
            .mapError { $0 }
            .tryMap(statusCheck)
            .eraseToAnyPublisher()
        
     }
    /// Sends IRequest
    ///
    /// Performs status check
    /// - Parameters:
    ///   - request: request that conforms to IRequest
    ///   - completion: ALResult<Data>
    func send(request: IRequest, completion: @escaping ResultClosure<Data>) {
        provider.send(request,
                      completion: { [weak self] in self?.processResult($0, completion: completion) },
                      progress: nil)
    }

    private func processResult(_ result: ALResult<AHNetworkResponse>,
                               completion: @escaping ResultClosure<Data>) {
        result.onError({ completion(.failure($0)) })
              .do( { self.proccess(response: $0, with: completion) })
    }

    private func proccess(response: AHNetworkResponse,
                          with completion: @escaping ResultClosure<Data>) {

        convertToError(networkResponse: response).do( { completion(.failure($0)) })
                                                 .onNone { completion(.success(response.data)) }
    }
    
    func receiveSocketData(request: IRequest) -> AnyPublisher<Data, Error> {
        socketProvider.receiveSocketData(request: request)
    }
    
    func receiveSocketMessage(request: IRequest) -> AnyPublisher<String, Error> {
        socketProvider.receiveSocketMessage(request: request)
    }
}

private func statusCheck(networkResponse: AHNetworkResponse) throws -> AHNetworkResponse  {
    guard networkResponse.statusCode != 200  else { return networkResponse }
    throw CoreNetworkError.responseError(networkResponse)
}

private func convertToError(networkResponse: AHNetworkResponse) -> CoreNetworkError? {
    guard networkResponse.statusCode != 200  else { return nil }
    return .responseError(networkResponse)
}

public enum CoreNetworkError: LocalizedError {
    case timeout
    case responseError(AHNetworkResponse)

    public var errorDescription: String? {
        var msg: String

        switch self {
        case .timeout:
            msg = "Response timeout"
        case let .responseError(networkResponse):
            msg = "Network status response: \(String(networkResponse.statusCode))"
        }

        return msg
    }
}
