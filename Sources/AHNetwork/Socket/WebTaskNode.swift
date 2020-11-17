import Foundation
import Combine
import ALResult


@available(iOS 13.0, *)
@available(OSX 10.15, *)

final class WebTaskNode: SocketProvider {
  
    
    private let session: URLSession
    fileprivate let adapter: IRequestAdapter = AHRequestAdapter()
    private var openSockets: [String: Subscription] = [:]
    
    init(session: URLSession) {
        self.session = session
    }
    
    @available(iOS 13.0, *)
    func receiveSocketData(request: IRequest) -> AnyPublisher<Data, Error> {
        guard request.taskType == .socket else {
            return errorFuture(request.taskType)
        }
        
        return taskPublisher(for: request).map(extractData)
                                          .filter { $0 != nil}
                                          .map { $0.unsafelyUnwrapped }
                                          .eraseToAnyPublisher()
    }
    @available(iOS 13.0, *)
    func receiveSocketMessage(request: IRequest) -> AnyPublisher<String, Error> {
        guard request.taskType == .socket else {
            return errorFuture(request.taskType)
        }
        
        return taskPublisher(for: request).map(extractString)
                                          .filter { $0 != nil}
                                          .map { $0.unsafelyUnwrapped }
                                          .eraseToAnyPublisher()
    }
    
    
    private func saveSubscription(_ s: Subscription,
                                  for request: IRequest) {
        urlString(from: request).do { openSockets[$0] = s }
        
    }
    func closeSocket(request: IRequest) {
        urlString(from: request)
            .flatMap({ openSockets.removeValue(forKey: $0)})
            .do({ $0.cancel() })
    }
    
    private func urlString(from request: IRequest) -> String? {
        adapter.urlRequest(for: request)
            .url
            .flatMap({ $0.absoluteURL.absoluteString })
    }
    
    

    func errorFuture<T>(_ type: AHTaskType) -> AnyPublisher<T, Error> {
        Future { (completion) in
            completion(.failure(WError.wrongType(type)))
        }.eraseToAnyPublisher()
    }
    
    
    private func taskPublisher(for request: IRequest) -> AnyPublisher<URLSessionWebSocketTask.Message, Error> {
        let urlRequest = adapter.urlRequest(for: request)
    
        return session.webSocketPublisher(request: urlRequest)
            .handleEvents(receiveSubscription: { [weak self] subscription in
                self?.saveSubscription(subscription, for: request)
            })
            .eraseToAnyPublisher()
    }
      
    private func task(for request: IRequest) -> URLSessionWebSocketTask {
         let urlRequest = adapter.urlRequest(for: request)
         return session.webSocketTask(with: urlRequest)
    }
    
}


@available(iOS 13.0, *)
@available(OSX 10.15, *)
private func extractData(message: URLSessionWebSocketTask.Message) -> Data? {
    if case let .data(data) = message {
        return data
    }
    return nil
}

@available(iOS 13.0, *)
@available(OSX 10.15, *)
private func extractString(message: URLSessionWebSocketTask.Message) -> String? {
    if case let .string(msg) = message {
        return msg
    }
    return nil
}

@available(iOS 13.0, *)

@available(OSX 10.15, *)
extension URLSession {
    
    func webSocketPublisher(request: URLRequest) -> WebSocketPublisher {
        .init(session: self, urlRequest: request)
    }
    
    struct WebSocketPublisher: Publisher {
      
        typealias Output = URLSessionWebSocketTask.Message
        typealias Failure = Error
        let session: URLSession
        let urlRequest: URLRequest

        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            
            let task = urlRequest.url.map(session.webSocketTask) ?? session.webSocketTask(with: urlRequest)
    
            subscribe(subscriber: subscriber, to: task)
            keepAlive(task: task)
        }
        
        
        private func subscribe<S>(subscriber: S, to task: URLSessionWebSocketTask) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input  {
            
            let subscription = task.subscription
            subscriber.receive(subscription: subscription)
            
            task.receive(completionHandler: { result in
                result.do { message in
                   let demand = subscriber.receive(message)
                    subscription.request(demand)
                }
                .onError { failure in
                    subscriber.receive(completion: .failure(failure))
                }
            })
            task.resume()
        }
        
        
        private func keepAlive(task: URLSessionWebSocketTask) {
            task.keepAlive({ debugPrint($0.localizedDescription )})
        }
        
    }
}

@available(iOS 13.0, *)
@available(OSX 10.15, *)
extension URLSessionWebSocketTask {
    
    var subscription: WebSocketSubscription {
        .init(task: self)
    }
    
    
    struct WebSocketSubscription: Subscription {
        
        let task: URLSessionWebSocketTask
        init(task: URLSessionWebSocketTask) {
            self.task = task
        }
        
        func request(_ demand: Subscribers.Demand) {
            
        }
        
        func cancel() {
            task.cancel(with: .goingAway, reason: nil)
        }
        
        var combineIdentifier: CombineIdentifier = .init()
        
    }
}

@available(iOS 13.0, *)
@available(OSX 10.15, *)
extension URLSessionWebSocketTask {
    
    var pingQueue: DispatchQueue  {
        .main
    }
    
    func keepAlive(_ failed: @escaping (Error) -> Void ) {
        pingQueue.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            self?.sendPing { (error) in
                if let error = error {
                    failed(error)
                } else {
                    self?.keepAlive(failed)
                }
            }
        }
    }
    
    
}


@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension WebTaskNode {
    enum WError: LocalizedError {
        case wrongType(AHTaskType)
        
        var errorDescription: String? {
            switch self {
            case let .wrongType(type):
                return "Use a different API for \(type)"
            }
        }
    }
}
