//
//  NetworkHelpers.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 8/26/20.
//  Copyright © 2020 Zachary Steed. All rights reserved.
//

import Foundation


// MARK: - Network handler typealias

public typealias NetworkResponseResult = Result<NetworkResponseData, NetworkResponseError>
public typealias NetworkResponseCallback = (NetworkResponseResult) -> Void
public typealias JSONDictionary = Dictionary<String, Any>


// MARK: - NetworkResponseData

open class NetworkResponseData {

    public let httpResponse: HTTPURLResponse
    public let data: Data?
    public let url: URL?

    public init(response: HTTPURLResponse, data: Data? = nil, url: URL? = nil) {
        self.httpResponse = response
        self.data = data
        self.url = url
    }

    public func dataAsCsv() -> [String]? {
        guard let data = data else {
            return nil
        }

        return HTTPUtil.parseCsvResponse(data)
    }

    public func dataAsJson() -> JSONDictionary? {
        guard let data = data else {
            return nil
        }

        return HTTPUtil.parseJSONResponse(data)
    }

    public func dataAsDecodable<T: Decodable>(_ decodable: T.Type) -> T? {
        guard let data = data else {
            return nil
        }

        return try? JSONDecoder().decode(decodable, from: data)
    }

}


// MARK: - NetworkResponseError

public class NetworkResponseError: Error {

    public let httpResponse: HTTPURLResponse
    public let error: Error?

    public var httpStatus: HTTPStatus {
        let statusCode = httpResponse.statusCode

        return HTTPStatus(rawValue: statusCode) ?? .unlisted
    }


    // TODO: - Add more status common codes
    public enum HTTPStatus: Int {
        case badRequest = 400
        case unauthorized = 401
        case paymentRequired = 402
        case forbidden = 403
        case notFound = 404

        case internalServerError = 500

        /// HTTP Status not added to Enum yet.
        case unlisted
    }

    public init(httpResponse: HTTPURLResponse, error: Error? = nil) {
        self.httpResponse = httpResponse
        self.error = error
    }

}


// MARK: - Network Operation Enums

/// Sets HTTP Method for networking
public enum HTTPMethod {
    case GET_DATA
    case GET_URL
    case POST(Any?)
    case POST_FORM([MultipartValues])
    case PUT(Any?)
    case DELETE
    case DELETE_PAYLOAD(Any?)

    public var value: String {
        switch self {
        case .GET_DATA, .GET_URL: return "GET"
        case .POST, .POST_FORM: return "POST"
        case .PUT: return "PUT"
        case .DELETE, .DELETE_PAYLOAD: return "DELETE"
        }
    }
}

public struct HeaderType {
    public static let contentType = "Content-Type"
    public static let accept = "Accept"
    public static let authorization = "Authorization"
}

public enum MimeType: String {
    case mpeg4 = "audio/mpeg4"
    case png = "image/png"
    case jpeg = "image/jpeg"
    case svg = "image/svg+xml"
    case textPlain = "text/plain"
    case json = "application/json"
    case unknown
}

public struct MultipartValues {
    public let keyName: String
    public let fileName: String
    public let data: Data
    public let mimeType: MimeType
}
