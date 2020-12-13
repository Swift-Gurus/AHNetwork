import Foundation
import Combine
import ALResult

@available(iOS 13.0, *)
@available(OSX 10.15, *)


final class WebTaskNode: SocketProvider {
      
    private let session: AHSession
    fileprivate let adapter: IRequestAdapter = AHRequestAdapter()
    private var openSockets: [CombineIdentifier: String] = [:]
    
    init(session: AHSession) {
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
        urlString(from: request).do { openSockets[s.combineIdentifier] = $0}
    }
    
    func closeSocket(id: CombineIdentifier) {
        openSockets
            .removeValue(forKey: id)
            .do({ session.cancelConnection(key: $0) })
    }
    
    func closeAllSockets() {
        openSockets.values.forEach(session.cancelConnection)
    }
    
    func closeSocket(request: IRequest) {
        let value  = urlString(from: request) ?? ""
        let id = openSockets.first(where: { $0.value == value})?.key
        id.flatMap({ openSockets.removeValue(forKey: $0) })
            .do({ session.cancelConnection(key: $0) })
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
            }, receiveCancel: { [weak self] in
                self?.closeSocket(request: request)
            })
            .eraseToAnyPublisher()
    }
    
}


@available(iOS 13.0, *)
@available(OSX 10.15, *)
private func extractData(message: URLSessionWebSocketTask.Message) -> Data? {
    do {
        switch message {
        case let .data(data):
            return data
        case let .string(msg):
            let str = msg.data(using: .utf8)!
            let jsonObj = try JSONSerialization.jsonObject(with: str, options: .allowFragments)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: .fragmentsAllowed)

            return jsonData
        @unknown default:
            return nil
        }
    }catch {
        return nil
    }
  

}

@available(iOS 13.0, *)
@available(OSX 10.15, *)
private func extractString(message: URLSessionWebSocketTask.Message) -> String? {
    
    if case let .string(msg) = message {
    
        return msg
    }
    return nil
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
