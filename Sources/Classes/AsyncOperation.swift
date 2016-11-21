/*
 MIT License

 Copyright (c) 2016 SwiftKidz

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation

class AsyncOperation: Operation {

    typealias AsyncBlock = (AsyncOp) -> Void

    fileprivate enum ChangeKey: String { case isFinished, isExecuting }

    fileprivate let runQueue: DispatchQueue
    fileprivate let order: Int

    fileprivate var retryNumber: Int
    fileprivate var asyncBlock: AsyncBlock
    fileprivate var store: AsyncOpResultStore?

    var finishedOp: Bool = false {
        didSet {
            didChangeValue(forKey: ChangeKey.isFinished.rawValue)
        }
        willSet {
            willChangeValue(forKey: ChangeKey.isFinished.rawValue)
        }
    }

    var executingOp: Bool = false {
        didSet {
            didChangeValue(forKey: ChangeKey.isExecuting.rawValue)
        }
        willSet {
            willChangeValue(forKey: ChangeKey.isExecuting.rawValue)
        }
    }

    init(qos: DispatchQoS = .background,
         retryTimes: Int = 0,
         orderNumber: Int = 0,
         store: AsyncOpResultStore? = nil,
         run: @escaping AsyncBlock
        ) {
        retryNumber = retryTimes
        order = orderNumber
        runQueue = DispatchQueue(label: "com.slip.asyncOperation.runQueue", qos: qos)
        self.store = store
        asyncBlock = run
    }
}



extension AsyncOperation {

    override func start() {
        guard !isCancelled else { print("CanceledOp"); return }
        executingOp = true
        runOperation()
    }

    func runOperation() {
        runQueue.async { [unowned self] in
            self.asyncBlock(self)
        }
    }

    func markAsFinished() {
        executingOp = false
        finishedOp = true
    }
}

extension AsyncOperation {

    override var isAsynchronous: Bool {
        return true
    }

    override var isFinished: Bool {
        get { return finishedOp }
        set { finishedOp = newValue }
    }

    override var isExecuting: Bool {
        get { return executingOp }
        set { executingOp = newValue }
    }
}

extension AsyncOperation {

    func retry() -> Bool {
        guard retryNumber > 0 else { return false }
        retryNumber -= 1
        runOperation()
        return true
    }
}

extension AsyncOperation: AsyncOp {

    func finish<R>(_ result: R) {
        guard !isCancelled else { return }
        store?.addNewResult(AsyncOpResult(order: order, result: result, error: nil))
        markAsFinished()
    }

    func finish(_ error: Error) {
        guard !isCancelled else { return }
        guard !retry() else { return }
        store?.addNewResult(AsyncOpResult(order: order, result: nil, error: error))
        markAsFinished()
    }
}
