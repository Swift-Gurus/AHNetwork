//
//  AHRequest.swift
//  Pods
//
//  Created by Alex Hmelevski on 2017-06-03.
//
//

import Foundation

public protocol IRequest {
    var baseURL: String { get }
    var path: String { get }
    var parameters: [String: String] { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var method: AHMethod { get }
    var scheme: AHScheme { get }
    var taskType: AHTaskType { get }
    var port: Int? { get }
}

let session = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "Bacl"))




