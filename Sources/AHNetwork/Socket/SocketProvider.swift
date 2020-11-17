import Foundation
import Combine

@available(OSX 10.15, *)
public protocol SocketProvider {

    @available(iOS 13.0, *)
    func receiveSocketData(request: IRequest) -> AnyPublisher<Data, Error>
    @available(iOS 13.0, *)
    func receiveSocketMessage(request: IRequest) -> AnyPublisher<String, Error>
    
    func closeSocket(request: IRequest)
}
