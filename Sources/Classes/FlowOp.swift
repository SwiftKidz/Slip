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

final class FlowOp: Operation {

    fileprivate enum ChangeKey: String { case isFinished, isExecuting }

    fileprivate let runQueue: DispatchQueue
    fileprivate let runBlock: FlowTypeBlocks.RunBlock
    fileprivate let order: Int
    fileprivate let resultHandler: FlowOperationResultsHandler

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
         orderNumber: Int,
         resultsHandler: FlowOperationResultsHandler,
         run: @escaping FlowTypeBlocks.RunBlock) {
        order = orderNumber
        runQueue = DispatchQueue(
            label: "com.slip.flowOp.runQueue",
            qos: qos
        )
        runBlock = run
        resultHandler = resultsHandler
    }
}

extension FlowOp {

    override func start() {
        guard !isCancelled else { return }
        executingOp = true

        runQueue.async { [unowned self] in
            let results = self.resultHandler.currentResults
            let order: Int = self.order
            let blockOp: BlockOp = self
            self.runBlock(blockOp, order, results.map { $0.result })
        }
    }

    func markAsFinished() {
        executingOp = false
        finishedOp = true
    }
}

extension FlowOp {

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

extension FlowOp: BlockOp {

    func finish<R>(_ result: R) {
        guard !isCancelled else { return }
        resultHandler.addNewResult(FlowOpResult(order: order, result: result, error: nil))
        markAsFinished()
    }

    func finish(_ error: Error) {
        guard !isCancelled else { return }
        resultHandler.addNewResult(FlowOpResult(order: order, result: nil, error: error))
        markAsFinished()
    }
}
