//
//  HTTPUtil.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 8/26/20.
//  Copyright © 2020 Zachary Steed. All rights reserved.
//

import Foundation

open class HTTPUtil: NSObject {

    private static let sharedInstance = HTTPUtil()
    public static let ArrayPayload = "arrayPayload"
    public static let StringPayload = "stringPayload"

    public var ephemeralSharedSession: URLSession?
    public var jsonSharedSession: URLSession?
    public var binarySharedSession: URLSession?

    private override init() {}

    //MARK: - NSURLSession factories

    open class func ephemeralSession() -> URLSession {
        if sharedInstance.ephemeralSharedSession == nil {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            config.httpAdditionalHeaders = [
                HeaderType.accept: MimeType.json.rawValue,
                HeaderType.contentType: MimeType.json.rawValue
            ]
            config.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
            sharedInstance.ephemeralSharedSession = URLSession(configuration: config, delegate: SessionTaskDelegate(), delegateQueue: nil)
        }

        return sharedInstance.ephemeralSharedSession!
    }

    open class func jsonSession() -> URLSession {
        if sharedInstance.jsonSharedSession == nil {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 80
            config.httpAdditionalHeaders = [
                HeaderType.accept: MimeType.json.rawValue,
                HeaderType.contentType: MimeType.json.rawValue
            ]

            config.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
            sharedInstance.jsonSharedSession = URLSession(configuration: config, delegate: SessionTaskDelegate(), delegateQueue: nil)
        }

        return sharedInstance.jsonSharedSession!
    }

    open class func binarySession() -> URLSession {
        if sharedInstance.binarySharedSession == nil {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 120
            config.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
            sharedInstance.binarySharedSession = URLSession(configuration: config, delegate: SessionTaskDelegate(), delegateQueue: nil)
        }

        return sharedInstance.binarySharedSession!
    }


    // MARK: - Making Stuff

    open class func makeUrl(_ urlStr: String, params: Dictionary<String, String>? = nil) -> URL? {
        precondition(!urlStr.contains("Optional"), "URL string cannot contain optional values: \(urlStr)")

        let baseUrl = URL(string: urlStr)
        print("URL QUERY = \(URL(string: urlStr, relativeTo: baseUrl)?.absoluteString ?? "")")

        if let finalUrl = URL(string: urlStr, relativeTo: baseUrl) {
            var finalComponents = URLComponents(url: finalUrl, resolvingAgainstBaseURL: true)
            if let params = params {
                let queryString = createQueryString(params)
                finalComponents?.query = queryString
            }
            return finalComponents?.url
        }

        return nil
    }

    open class func createQueryString(_ params: [String:String]) -> String {
        let pairs = params.keys.map({"\($0)=\(params[$0]!)"})
        let queryString = pairs.joined(separator: "&")

        return queryString
    }

    class func createMultipartRequest(multipartValues: [MultipartValues]) -> (contentType: String, body: Data) {
        let boundary = "MobileBoundary"
        let body = NSMutableData()

        // Add data to form
        for part in multipartValues {
            var paramString = "--\(boundary)\r\n"
            paramString += "Content-Disposition: form-data; name=\"\(part.keyName)\"; filename=\"\(part.fileName)\"\r\n"
            paramString += "Content-Type: \(part.mimeType.rawValue)\r\n\r\n"

            body.append(paramString.data(using: String.Encoding.utf8)!)
            body.append(part.data)
        }

        // End form
        body.append("\r\n--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)

        let contentType = "multipart/form-data; boundary=\(boundary)"
        return (contentType, body as Data)
    }


    //MARK: - Parsing Responses

    class func parseStringResponse(_ data: Data) -> String? {
        if let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
            return responseString
        }
        return nil
    }

    class func parseJSONResponse(_ data: Data) -> JSONDictionary? {
        do {
            let props = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            if let propsDict = props as? JSONDictionary {
                return propsDict

            } else if let propsArray = props as? Array<AnyObject> {
                return [ArrayPayload : propsArray as AnyObject]
            }

        } catch let error as NSError {
            print("Error parsing JSON: \(error)")

            if let stringResponse = parseStringResponse(data) {
                return [StringPayload: stringResponse as AnyObject]
            }
        }

        return nil
    }

    class func parseCsvResponse(_ data: Data) -> [String]? {
        guard let parsedString = HTTPUtil.parseStringResponse(data) else {
            return nil
        }
        
        return parsedString.components(separatedBy: CharacterSet.newlines)
    }

}

extension HTTPUtil {

    class SessionTaskDelegate: NSObject, URLSessionTaskDelegate {

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            if let url = request.url,
               let method = request.httpMethod,
               let requestHeaders = task.originalRequest?.allHTTPHeaderFields,
               let sessionHeaders = session.configuration.httpAdditionalHeaders as? Dictionary<String, String>
               , requestHeaders.keys.count > 0 || sessionHeaders.count > 0
            {
                let newRequest = NSMutableURLRequest(url: url)
                var allHeaders = sessionHeaders
                for (k, v) in requestHeaders {
                    allHeaders[k] = v
                }
                newRequest.allHTTPHeaderFields = allHeaders
                newRequest.httpMethod = method

                completionHandler(newRequest as URLRequest)

            } else {
                task.cancel()
            }
        }
    }

}
