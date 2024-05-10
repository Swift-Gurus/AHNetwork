//
//  AHRequestAdapterTests.swift
//  AHNetwork
//
//  Created by Alex Hmelevski on 2017-06-05.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import AHNetwork

struct MockRequest: IRequest {
    var baseURL: String =   "www.myApi.com"
    var path: String = "/console"
    var parameters: [String : String] =
         ["role": "admin","access" : "full"]
    
    
    var headers: [String : String] = ["username": "admin", "password" : "12345"]
    
    
    var body: Data? =  "Test".data(using: .utf8)!
    
    var method: AHMethod =  .get
    var scheme: AHScheme = .https
    var taskType: AHTaskType = .request
    var port: Int? = 980
}

class AHRequestAdapterTests: XCTestCase {
    
    func test_adapter_uses_base_url() {
       let urlRequest =  AHRequestAdapter().urlRequest(for: MockRequest())
       XCTAssertEqual(urlRequest.url?.host, MockRequest().baseURL)
    }
    
    func test_adapter_missing_params() {
        var mockR = MockRequest()
        mockR.parameters = [:]
        let urlRequest = AHRequestAdapter().urlRequest(for: mockR)
        XCTAssertEqual(urlRequest.url?.absoluteURL.absoluteString, "https://www.myApi.com:980/console")
    }
    
    func test_adapter_uses_path() {
        let urlRequest =  AHRequestAdapter().urlRequest(for: MockRequest())
        XCTAssertEqual(urlRequest.url?.path, MockRequest().path)
    }
    
    func test_adapter_uses_scheme() {
        let urlRequest =  AHRequestAdapter().urlRequest(for: MockRequest())
        XCTAssertEqual(urlRequest.url?.scheme, MockRequest().scheme.string)
    }
    
    func test_adapter_uses_headers() {
        let urlRequest =  AHRequestAdapter().urlRequest(for: MockRequest())
        XCTAssertEqual(urlRequest.allHTTPHeaderFields!, MockRequest().headers)
    }
    
    func test_adapter_uses_method() {
        let urlRequest =  AHRequestAdapter().urlRequest(for: MockRequest())
        XCTAssertEqual(urlRequest.httpMethod, MockRequest().method.string)
    }
    
    func test_adapter_uses_body() {
        let urlRequest =  AHRequestAdapter().urlRequest(for: MockRequest())
        XCTAssertEqual(urlRequest.httpBody, MockRequest().body)
    }
    
    
    func test_url_already_contains_scheme() {
        var mockR = MockRequest()
        mockR.parameters = [:]
        mockR.baseURL = "https://www.myApi.com:980/console"
        let urlRequest = AHRequestAdapter().urlRequest(for: mockR)
        XCTAssertEqual(urlRequest.url?.absoluteURL.absoluteString, "https://www.myApi.com:980/console")
    }
}
