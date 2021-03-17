//
//  DoneOperation.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 2/18/21.
//  Copyright © 2021 Zachary Steed. All rights reserved.
//

import Foundation

/// This class captures multiple Network dependencies and uses a closure to signal if all operations are successful or if 1 failed, then they all fail.
public class DoneOperation: AsyncOperation {

    private let dependentOperations: [NetworkOperation]

    public init(dependentOperations: [NetworkOperation]) {
        self.dependentOperations = dependentOperations
        super.init()

        self.dependentOperations.forEach { addDependency($0) }
    }

    /// Begins executing the dependencies by adding them to an operationQueue, will default to "shared" queue if one isn't passed
    public func execute(completion: @escaping (Bool) -> Void, operationQueue: OperationQueue? = nil) {
        let queue = operationQueue ?? OperationQueue.sharedQueue

        // Add this `done` operation to queue, won't execute as it still has dependencies
        queue.addOperation(self) { _ in
            for operation in self.dependentOperations {
                if operation.isSuccessful == false {
                    completion(false)
                    break
                }
            }

            completion(true)
        }

        // Begin each operation dependency
        dependentOperations.forEach { $0.execute() }
    }

    public override func main() {
        completeOperation()
    }

}
