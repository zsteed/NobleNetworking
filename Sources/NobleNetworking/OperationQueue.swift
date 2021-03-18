//
//  OperationQueue.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 8/26/20.
//  Copyright © 2020 Zachary Steed. All rights reserved.
//

import Foundation

open class OperationQueue: Foundation.OperationQueue {

    /// General queue
    public static let sharedQueue = OperationQueue(queueName: "OperationQueue")

    /// A queue set to maxCount == 1
    public static let validAuthQueue = OperationQueue(queueName: "OperationValidAuthQueue", maxCount: 1)

    public init(queueName: String, maxCount: Int? = nil) {
        super.init()
        self.name = queueName

        if let maxCount = maxCount {
            self.maxConcurrentOperationCount = maxCount
        }
    }

    private func deDupOperation<Op: Operation>(_ operation: Op) -> (isDup: Bool, operation: Op) {
        for existingOperation in self.operations {
            if let existingOperation = existingOperation as? Op,
               let existingComp = existingOperation as? AsyncOperation,
               let newOperation = operation as? AsyncOperation
               , existingComp.operationUniqueId() == newOperation.operationUniqueId()
            {
                print("Found duplicate operation (\(existingComp.operationUniqueId())) so returning existing operation: \(existingOperation)")
                return (isDup: true, operation: existingOperation)
            }
        }
        return (isDup: false, operation: operation)
    }

    open func addOperation<Op: Operation>(_ operation: Op, qualityOfService: QualityOfService = .default, ignoreIfDup: Bool = false, callback:((_ operation: Op)->Void)?) {
        var ops = [Operation]()

        // Check if equivalent operation already exists
        let dupCheck = deDupOperation(operation)
        if dupCheck.isDup && ignoreIfDup {
            print("Not adding duplicate operation in favor of existing operation: \(dupCheck.operation)")
            return
        }

        let targetOperation: Op = dupCheck.operation

        if targetOperation === operation { // Didn't find an existing operation, so add the new operation
            ops.append(operation)
            operation.qualityOfService = qualityOfService
        }

        if let callback = callback {
            let callBackOperation = BlockOperation { () -> Void in
                callback(targetOperation)
            }
            callBackOperation.addDependency(targetOperation)
            callBackOperation.qualityOfService = qualityOfService
            ops.append(callBackOperation)
        }

        self.addOperations(ops, waitUntilFinished: false)
    }

    /// Defaults to use the General `sharedQueue`
    open class func addOperation<Op: Operation>(_ operation: Op, qualityOfService: QualityOfService = .default, ignoreIfDup: Bool = false, callback:((_ operation: Op)->Void)?) {
        sharedQueue.addOperation(operation, qualityOfService: qualityOfService, ignoreIfDup: ignoreIfDup, callback: callback)
    }

}
