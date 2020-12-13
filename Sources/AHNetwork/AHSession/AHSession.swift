import Foundation
import Combine
@available(iOS 13.0, *)
@available(OSX 10.15, *)

class AHSession {
    
    let session: URLSession
    private var publishers: [String: WebSocketPublisher] = [:]

    public init(configuration: URLSessionConfiguration) {
        
        session = .init(configuration: configuration)
    }
    
    func webSocketPublisher(request: URLRequest) -> WebSocketPublisher {
        let key = request.url?.absoluteString ?? ""
        if let existedPublisher = publishers[key] {
            return existedPublisher
        } else {
            let newPublisher = WebSocketPublisher(task: getTask(for: request))
            publishers[key] = newPublisher
            return newPublisher
        }
        
    }
    
    func cancelConnection(key: String) {
        publishers.removeValue(forKey: key)
    }
    
    func closeAllConnections() {
        publishers = [:]
    }

    private func getTask(for urlRequest: URLRequest) -> SocketTaskWrapper {
        SocketTaskWrapper(task: session.webSocketTask(with: urlRequest))
    }
    deinit {
        
    }
}



@available(iOS 13.0, *)
@available(OSX 10.15, *)

struct WebSocketPublisher: Publisher {
  
    typealias Output = URLSessionWebSocketTask.Message
    typealias Failure = Error
    let task: SocketTaskWrapper
    
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {

        subscribe(subscriber: subscriber, to: task)
        if task.state != .running {
            task.start()
        }
    }
    
    
    private func subscribe<S>(subscriber: S, to task: SocketTaskWrapper) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input  {
        
        let subscription = task.subscription
        subscriber.receive(subscription: subscription)
        task.receive(completionHandler: { result in
            result.do { message in
                subscription.request(subscriber.receive(message))
            }
            .onError { failure in
                subscriber.receive(completion: .failure(failure))
            }
        })
    }
}

