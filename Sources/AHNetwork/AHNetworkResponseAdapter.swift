//
//  AHNetworkResponseAdapter.swift
//  Pods
//
//  Created by Alex Hmelevski on 2017-06-05.
//
//

import Foundation
import AHFunctionalSwift

protocol INetworkResponseAdapter {
    
    func response(from data: Data?, with response: URLResponse?, and error: Error?) ->
        ALResult<AHNetworkResponse>
}

protocol INetworkDownloadAdapter {
    func response(from url: URL?, with response: URLResponse?, and error: Error?) -> ALResult<AHNetworkResponse>
}

struct AHNetworkResponseAdapter: INetworkResponseAdapter, INetworkDownloadAdapter {
    
    func response(from data: Data?,
                  with response: URLResponse?,
                  and error: Error?) -> ALResult<AHNetworkResponse> {
        
            let resp = AHNetworkResponse(data: data, response: response)
            return ALResult(success: resp, error: error)
    }
    
    func response(from url: URL?, with response: URLResponse?, and error: Error?) -> ALResult<AHNetworkResponse> {
        let data =  url?.absoluteString.data(using: .utf8)
        let resp = AHNetworkResponse(data: data, response: response)
        return ALResult(success: resp, error: error)
    }

}
