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

protocol FlowTypeBlocks: class {
    typealias RunBlock = (BlockOp, Int, Any) -> ()

    var blocks: [RunBlock] { get }
    var runBlock: RunBlock { get }

    var limitOfSimultaneousOps: Int { get }
}

extension FlowTypeBlocks where Self: FlowRun & FlowOpHandler & FlowResults & Safe & SafeState & FlowOutcome & FlowStateChanged & FlowTestHandler {

    func runClosure() {
        let run = FlowOp(orderNumber: safeResults.count, flowHandler: self, run: runBlock).operation
        opQueue.addOperation(run)
    }

    func runFlowOfBlocks() {
        guard !blocks.isEmpty else { safeState = .finished; return }

        let ops = [Int](0..<blocks.count).map { FlowOp(orderNumber: $0, flowHandler: self, run: blocks[$0]) }.map { $0.operation }

        opQueue.addOperations(ops, waitUntilFinished: false)
    }
}
