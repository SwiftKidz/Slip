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

protocol FlowRun: class, FlowTypeTests, FlowOutcome {
    var opQueue: OperationQueue { get }
}

extension FlowRun where Self: FlowTestHandler {

    func runTest(onFinish: @escaping (FlowTestResult) -> Void) {
        let tHandler = FlowTest(callBack: onFinish)
        let test = BlockOperation { //[weak self] in
            self.testBlock(tHandler)
        }
        opQueue.addOperation(test)
    }
}

extension FlowRun where Self: FlowOpHandler {

    func runClosure(onFinish: @escaping (FlowOpResult) -> Void) {
        let o: Int = self.rawResults.count
        let f: BlockOp = FlowOp(orderNumber: o, callBack: onFinish)
        let run = BlockOperation {
            self.runBlock(f, o, self.currentResults)
        }
        opQueue.addOperation(run)
    }

    func runFlowOfBlocks(onFinish: @escaping (FlowOpResult) -> Void) {
        guard !blocks.isEmpty else { safeState = .finished; return }

        var ops: [Operation] = []

        for i in 0..<blocks.count {
            ops.append(operationFrom(block: blocks[i], order: i, finishOpCallback: onFinish))
        }

        opQueue.addOperations(ops, waitUntilFinished: false)
        blocks.removeAll()
    }

    private func operationFrom(block: @escaping FlowTypeBlocks.RunBlock,
                               order: Int,
                               finishOpCallback: @escaping (FlowOpResult) -> Void) -> Operation {
        let f: BlockOp = FlowOp(orderNumber: order, callBack: finishOpCallback)
        let o: Int = order
        return BlockOperation { [weak self] in
            block(f, o, self?.currentResults ?? [])
        }
    }
}
