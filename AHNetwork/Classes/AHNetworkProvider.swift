//
//  AHNetworkProvider.swift
//  Pods
//
//  Created by Alex Hmelevski on 2017-06-05.
//
//

import Foundation
import ALEither
import AHFuture

enum NetworkProviderError: Error {
    case imposibleToSendTask
}

public protocol INetworkProvider {
    @discardableResult
    func send(_ request: IRequest, completion: completionHandler?) -> ICancellable
}


struct NetworkTaskRequest {
    let urlRequest: URLRequest
    let type: AHTaskType
}


public typealias completionHandler = (ALEither<AHNetworkResponse,Error>) -> Void


public class AHNetworkProvider: INetworkProvider {

    fileprivate let adapter: IRequestAdapter = AHRequestAdapter()
    fileprivate let sender: INetworkTaskNode
    
    public init(session: URLSession = URLSession(configuration: URLSessionConfiguration.default)) {
        sender = BasicTaskNode.createChain(from: [RequestTaskNode.self], using: session)
    }
    
    @discardableResult
    public func send(_ request: IRequest, completion: completionHandler?) -> ICancellable {
        let nRequest = NetworkTaskRequest(urlRequest: adapter.urlRequest(for: request), type: request.taskType)
        return sender.send(request: nRequest, completion: completion)
    }
}

public extension AHNetworkProvider {

    public func requestFuture(for request: IRequest) -> AHFuture<AHNetworkResponse,Error> {
        return AHFuture<AHNetworkResponse,Error>() { (scope) in
            self.send(request, completion: scope)
        }
    }
}


