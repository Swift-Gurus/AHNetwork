//
//  AHRequestAdapter.swift
//  Pods
//
//  Created by Alex Hmelevski on 2017-06-05.
//
//

import Foundation
#if canImport(FunctionalSwift)
import FunctionalSwift
#else
import AHFunctionalSwift
#endif

protocol IRequestAdapter {
    func urlRequest(for request: IRequest) -> URLRequest
}

public final class AHRequestAdapter: IRequestAdapter {
    
    public init() {}
    
    public func urlRequest(for request: IRequest) -> URLRequest {
        
        return  request » createURLRequest
                        » { appendMethod(to: $0,from: request) }
                        » { appendBody(to: $0,from: request) }
                        » { setHeaders(in: $0,from: request) }
        
    }
    
    
    private func createURLRequest(from request: IRequest) -> URLRequest {
        
        guard let url = (request » createComponents).url   else {
            fatalError("Cannot create URL")
        }
        return URLRequest(url: url)
    }
    
    private func createComponents(from request: IRequest) -> URLComponents {
        var components = tryFrom(url: request.baseURL) ?? URLComponents()
   
        components.host = components.host ?? request.baseURL
        components.path = components.path.isEmpty ? request.path : components.path
        
        if !request.parameters.isEmpty {
            components.queryItems = components.queryItems ?? request.parameters.map(URLQueryItem.init)
        }
        components.scheme = components.scheme ?? request.scheme.string
        components.port = components.port ?? request.port
        
        return components
    }
    
    private func tryFrom(url: String) -> URLComponents? {
        let components = URLComponents(string: url)
        return components?.host == nil ? nil : components
    }
    
    private func appendMethod(to urlRequest: URLRequest, from request: IRequest) -> URLRequest {
        var copy = urlRequest
        copy.httpMethod = request.method.string
        return copy
    }
    
    private func appendBody(to urlRequest: URLRequest, from request: IRequest) -> URLRequest {
        var copy = urlRequest
        copy.httpBody = request.body
        return copy
    }
    
    private func setHeaders(in urlRequest: URLRequest, from request: IRequest) -> URLRequest {
        var newRequest = urlRequest
        request.headers.keys.forEach { (key) in
            newRequest.setValue(request.headers[key], forHTTPHeaderField: key)
        }
        return newRequest
    }
    
    private func queryItems(from params: [String: String]) -> [URLQueryItem] {
        return params.map(URLQueryItem.init)
    }
}
