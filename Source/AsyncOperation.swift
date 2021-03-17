//
//  AsyncOperation.swift
//  NobleNetworking
//
//  Created by Zachary Steed on 8/26/20.
//  Copyright © 2020 Zachary Steed. All rights reserved.
//

import Foundation

open class AsyncOperation: Operation {

    public var error: Error?
    public var uniqueId = String(arc4random())

    override init() {
        _executing = false
        _finished = false

        super.init()
    }

    private var _executing: Bool = false
    override open var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            if _executing != newValue {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    private var _finished: Bool = false;
    override open var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if _finished != newValue {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    override open var isAsynchronous: Bool {
        return true
    }

    public func completeOperation () {
        isExecuting = true
        isFinished = true
    }

    override open func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true
        main()
    }


    open func operationUniqueId() -> String {
        return uniqueId
    }

}

public func ==(lhs: AsyncOperation, rhs: AsyncOperation) -> Bool {
    return lhs.operationUniqueId() == rhs.operationUniqueId()
}
