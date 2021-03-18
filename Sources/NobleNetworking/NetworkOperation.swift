//
//  NetworkOperation.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 8/26/20.
//  Copyright © 2020 Zachary Steed. All rights reserved.
//

import Foundation

///
/// NetworkOperation object, used for networking
///
///  ** Benefits **
///  1. Handles duplicate entries
///  2. Queue ( handles not overloading the system )
///  3. Quality of service ( Range of UserInitiated vs utility )
///  4. Dependency chaining ( ie other operations )
///  5. Will retry failed operation 3 times
///  6. If subclassed, will attempt to restore if http status code is 401
///
open class NetworkOperation: AsyncOperation {


    // MARK: - Properties

    /// The request that is passed in, core of this class
    private var request: NetworkRequest

    /// The HTTP Method associated with the endpoint
    private var httpMethod: HTTPMethod

    /// Tracks the number of attempts, only increased if failed response from server
    private var attempts = 0

    /// Max attempt count set to 3
    private let maxRetries = 3

    /// Optional property for those POST or PUT requests
    private var payload: Any?

    /// Return object for data request logic, need to always have a value when returned
    private var networkResponseDataResult: NetworkResponseResult? = nil

    /// Completion callback to use when operation is finished
    private let networkResponseDataCallback: NetworkResponseCallback

    /// Easy access to check if operation was successful
    var isSuccessful = false

    /// The queue to execute the operation on. Defaults to OperationQueue.sharedQueue
    var queue: OperationQueue = OperationQueue.sharedQueue

    /// OperationQueue allows duplicate entries to be ignored. default is true
    var ignoreIfDuplicate = true


    /// Creates a Network Operation object
    ///
    /// - parameter uniqueId: The ID used to check for duplicate operation entries
    /// - parameter request: The networkRequest object that has some network logic
    ///
    public init(uniqueId: String = String(arc4random()),
                httpMethod: HTTPMethod,
                request: NetworkRequest,
                completion: @escaping NetworkResponseCallback) {
        self.request = request
        self.httpMethod = httpMethod
        self.networkResponseDataCallback = completion

        super.init()
        self.uniqueId = uniqueId
    }


    // MARK: - AsyncOperation overrides

    /// Begins Execution of the operation
    override open func main() {
        if self.isCancelled {
            return
        }

        executeOperation()
    }

}


extension NetworkOperation {

    /// Public call to begin the operation
    public func execute() {
        queue.addOperation(self, qualityOfService: qualityOfService, ignoreIfDup: ignoreIfDuplicate) { op in
            if let result = self.networkResponseDataResult {
                self.networkResponseDataCallback(result)

            } else {
                // Developer error, force a crash.
                // We don't want this flying under the radar
                fatalError("Network response result should not be null")
            }
        }
    }

    /// Private method that is called inside operation method main()
    private func executeOperation() {
        switch httpMethod {
        case .GET_DATA:
            request.getData(completion: handleResponse)

        case .GET_URL:
            request.getDownloadUrl(completion: handleResponse)

        case .POST_FORM(let values):
            request.postMultipart(multipartValues: values, completion: handleResponse)

        case .POST(let payload):
            request.postPayload(payload, completion: handleResponse)

        case .PUT(let payload):
            request.putPayload(payload, completion: handleResponse)

        case .DELETE:
            request.deleteAtEndpoint(completion: handleResponse)

        case .DELETE_PAYLOAD(let payload):
            request.deletePayload(payload, completion: handleResponse)

        }
    }

    private func handleResponse(result: Result<NetworkResponseData, NetworkResponseError>) {
        switch result {
        case .success(let response):
            self.handleSuccessCase(response: response)

        case .failure(let error):
            self.handleFailCase(error: error)

        }
    }

    private func handleSuccessCase(response: NetworkResponseData) {
        isSuccessful = true
        networkResponseDataResult = .success(response)
        completeOperation()
    }

    private func handleFailCase(error: NetworkResponseError) {
        isSuccessful = false

        if error.httpStatus == .unauthorized {
            self.restoreSession(error: error) { success in
                self.handleSessionRestoreAttempt(success: success, error: error)
            }
        } else {
            checkShouldRetryRequest(error: error)

        }
    }

}



extension NetworkOperation {

    private final func checkShouldRetryRequest(error: NetworkResponseError) {
        if attempts >= maxRetries {
            networkResponseDataResult = .failure(error)
            completeOperation()
            return
        } else {
            attempts += 1
            executeOperation()
            return
        }
    }

    open func restoreSession(error: NetworkResponseError, completion: @escaping (_ success: Bool) -> Void) {
        completion(false)
    }

    private final func handleSessionRestoreAttempt(success: Bool, error: NetworkResponseError) {
        if success {
            attempts = 0
            executeOperation()
        } else {
            if attempts >= maxRetries {
                networkResponseDataResult = .failure(error)
                completeOperation()
            } else {
                attempts += 1
                restoreSession(error: error) { [weak self] success in
                    self?.handleSessionRestoreAttempt(success: success, error: error)
                }
            }
        }
    }

}
