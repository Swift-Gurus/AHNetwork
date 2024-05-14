//
//  DataDeSerializer.swift
//  AHNetwork
//
//  Created by Alex Hmelevski on 2020-02-15.
//

import Foundation

public protocol DataDeserializer{
    func convertToObject<T>(data: Data) throws -> T where T: Decodable
}

public protocol DataSerializer {
    func convertToData<T: Encodable>(_ obj: T) throws -> Data
}

public final class JSONSerializer: DataSerializer, DataDeserializer {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public func convertToObject<T>(data: Data) throws -> T where T : Decodable {
        return try decoder.decode(T.self, from: data)
    }
    
    public func convertToData<T>(_ obj: T) throws -> Data where T : Encodable {
        return try encoder.encode(obj)
    }
}
