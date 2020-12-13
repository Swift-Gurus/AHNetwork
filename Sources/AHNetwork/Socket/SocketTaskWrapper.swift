import Combine
import Foundation

@available(iOS 13.0, *)
final class SocketTaskWrapper {
    typealias CompletionResult = Result<URLSessionWebSocketTask.Message, Error>
    typealias Completion = (CompletionResult) -> Void
    let task: URLSessionWebSocketTask
    var completions: [Completion] = []
    var dispatchWork: DispatchWorkItem?
    var queue = DispatchQueue(label: "SocketTaskWrapper")
    var state: URLSessionTask.State { task.state }
    
    init(task: URLSessionWebSocketTask) {
        self.task = task
    }
    
    func receive(completionHandler: @escaping Completion) {
        completions.append(completionHandler)
    }
    
    func start() {
        callReceive()
        task.resume()
        keepAlive()
    }
    
    private func callReceive() {
        task.receive { [weak self] (result) in
            self?.notify(with: result)
        }
    }
    
    func cancel() {
        task.cancel(with: .goingAway, reason: nil)
    }
    
    deinit {
        cancel()
    }
    
    
    private func createItem() -> DispatchWorkItem {
        .init {[weak self] in
            self?.task.sendPing { (error) in
                if let error = error {
                    self?.notify(with: .failure(error))
                } else {
                    self?.keepAlive()
                }
            }
        }
    }
    
    func keepAlive() {
        guard state == .running else { return }
        let item = createItem()
        queue.asyncAfter(deadline: .now() + .seconds(8), execute: item)
    }
    
    private func notify(with result: CompletionResult) {
        completions.forEach({ $0(result)} )
        result.do({_ in callReceive() })
        
    }
}


@available(iOS 13.0, *)
@available(OSX 10.15, *)
extension SocketTaskWrapper {
    
    var subscription: WebSocketSubscription {
        .init(task: self)
    }
    
    struct WebSocketSubscription: Subscription {
        
        var debugDescription: String { "WebSocket" }
        var description: String { "WebSocket" }
        weak var task: SocketTaskWrapper?
        
        init(task: SocketTaskWrapper) {
            self.task = task
        }
        
        func request(_ demand: Subscribers.Demand) {
            
        }
        
        func cancel() {
            task?.cancel()
        }
        
        var combineIdentifier: CombineIdentifier = .init()
        
    }
}
