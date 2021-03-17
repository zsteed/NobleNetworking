//
//  NetworkRequest.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 8/26/20.
//  Copyright © 2020 Zachary Steed. All rights reserved.
//

import Foundation

/// Basic networking object
open class NetworkRequest {

    // MARK: - Properties

    /// The endpoint for the operation
    public let endpoint: String

    /// Any parameters to add to the endpoint
    public let parameters: [String: String]?

    /// Any headers to set with the endpoint
    public let headers: [String: String]?

    /// Handler contains the required values for multiform uploads
    public var multipartValues: [MultipartValues] = []


    // MARK: - Init

    /// Creates a Network Operation object
    ///
    /// - parameter endpoint: The url endpoint
    /// - parameter params: Parameters to add to the URL endpoint
    /// - parameter headers: Additional headers that can be added to a url session
    ///
    public init(
        endpoint: String,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil)
    {
        self.endpoint = endpoint
        self.parameters = parameters
        self.headers = headers
    }

}

// MARK: - Network operation result handlers

extension NetworkRequest {

    public func putPayload(_ payload: Any?, completion: @escaping NetworkResponseCallback) {
        executeUploadRequest(httpMethod: .PUT(payload), payload: payload, completion: completion)
    }

    public func postMultipart(multipartValues: [MultipartValues], completion: @escaping NetworkResponseCallback) {
        self.multipartValues = multipartValues
        executeMultipartRequest(httpMethod: .POST_FORM(multipartValues), completion: completion)
    }

    public func postPayload(_ payload: Any?, completion: @escaping NetworkResponseCallback) {
        executeUploadRequest(httpMethod: .POST(payload), payload: payload, completion: completion)
    }

    public func deletePayload(_ payload: Any?, completion: @escaping NetworkResponseCallback) {
        executeUploadRequest(httpMethod: .DELETE, payload: payload, completion: completion)
    }

    public func deleteAtEndpoint(completion: @escaping NetworkResponseCallback) {
        executeDataRequest(httpMethod: .DELETE, completion: completion)
    }

    public func getData(completion: @escaping NetworkResponseCallback) {
        executeDataRequest(httpMethod: .GET_DATA, completion: completion)
    }

    public func getDownloadUrl(completion: @escaping NetworkResponseCallback) {
        executeDownloadRequest(httpMethod: .GET_URL, completion: completion)
    }

}

// MARK: - Upload request

extension NetworkRequest {

    private final func executeUploadRequest(httpMethod: HTTPMethod,
                                            payload: Any?,
                                            completion: @escaping NetworkResponseCallback) {
        let session = HTTPUtil.jsonSession()

        guard let url = HTTPUtil.makeUrl(endpoint, params: parameters) else {
            fatalError("Error making URL - \(endpoint), parameters: \(String(describing: parameters))")
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        var requestData: Data? = nil

        if let stringPayload = payload as? String {
            requestData = stringPayload.data(using: String.Encoding.utf8)

        } else if let dataPayload = payload as? Data {
            requestData = dataPayload

        } else if let payload = payload {
            do {
                requestData = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions())
            } catch {
                fatalError("Error formatting payload for endpoint - \(url)")
            }
        }

        guard let formattedPayloadData = requestData else {
            fatalError("Error formatting payload for endpoint - \(url)")
        }

        let task = session.uploadTask(with: request, from: formattedPayloadData) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }
        task.resume()
    }

}


// MARK: - Execute download request

extension NetworkRequest {

    private final func executeDownloadRequest(httpMethod: HTTPMethod,
                                              completion: @escaping NetworkResponseCallback) {
        let session = HTTPUtil.binarySession()

        guard let url = HTTPUtil.makeUrl(endpoint, params: parameters) else {
            fatalError("Error making URL - \(endpoint), parameters: \(String(describing: parameters))")
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let task = session.downloadTask(with: request) { url, response, error in
            self.handleDownloadResponse(url: url,
                                        response: response,
                                        error: error,
                                        completion: completion)
        }
        task.resume()
    }

    private final func handleDownloadResponse(url: URL?,
                                              response: URLResponse?,
                                              error: Error?,
                                              completion: @escaping NetworkResponseCallback) {
        if let error = error {
            completion(.failure(NetworkResponseError(httpResponse: response as! HTTPURLResponse, error: error)))
            return
        }

        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200...299:
            if let url = url {
                let responseUrl = NetworkResponseData(response: httpResponse, url: url)
                completion(.success(responseUrl))
            } else {
                completion(.success(NetworkResponseData(response: httpResponse)))
            }

        default:
            completion(.failure(NetworkResponseError(httpResponse: httpResponse, error: error)))

        }
    }

}


// MARK: - Data request Methods

extension NetworkRequest {

    private final func executeDataRequest(httpMethod: HTTPMethod,
                                          completion: @escaping NetworkResponseCallback) {
        let session = HTTPUtil.jsonSession()

        guard let url = HTTPUtil.makeUrl(endpoint, params: parameters) else {
            fatalError("Error making URL - \(endpoint), parameters: \(String(describing: parameters))")
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value

        if let headers = headers {
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        }

        let task = session.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data,
                                response: response,
                                error: error,
                                completion: completion)
        }
        task.resume()
    }

    private final func handleResponse(data: Data?,
                                      response: URLResponse?,
                                      error: Error?,
                                      completion: @escaping NetworkResponseCallback) {
        if let error = error {
            completion(.failure(NetworkResponseError(httpResponse: response as! HTTPURLResponse, error: error)))
            return
        }

        let httpResponse = response as! HTTPURLResponse

        switch httpResponse.statusCode {
        case 200...299:
            if let data = data, data.count > 0 {
                let responseData = NetworkResponseData(response: httpResponse, data: data)
                completion(.success(responseData))
            } else {
                completion(.success(NetworkResponseData(response: httpResponse)))
            }

        default:
            completion(.failure(NetworkResponseError(httpResponse: httpResponse, error: error)))

        }
    }

}


// MARK: - Multiform methods

extension NetworkRequest {

    private final func executeMultipartRequest(httpMethod: HTTPMethod,
                                               completion: @escaping NetworkResponseCallback) {
        let binarySession = HTTPUtil.binarySession()

        guard let url = HTTPUtil.makeUrl(endpoint, params: parameters) else {
            fatalError("Error making URL - \(endpoint), parameters: \(String(describing: parameters))")
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let parts = HTTPUtil.createMultipartRequest(multipartValues: multipartValues)
        request.setValue(parts.contentType, forHTTPHeaderField: HeaderType.contentType)
        request.httpBody = parts.body

        let task = binarySession.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }
        task.resume()
    }

}


