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

protocol FlowStateActions: class, FlowState, FlowTypeBlocks, FlowRun, FlowOpHandler, FlowTestHandler, FlowHandlerBlocks {}

extension FlowStateActions {

    func queued() {
        guard testFlow else { safeState = .running; return }
        guard testAtBeginning else { safeState = .running; return }
        safeState = .testing
    }

    func testing() {
        runTest { (res) in
            self.finishedTest(with: res)
        }
    }

    func running() {
        let execute: (FlowOpResult) -> Void = { (res) in
            self.finishedOp(with: res)
        }
        testFlow ? runClosure(onFinish: execute) : runFlowOfBlocks(onFinish: execute)
    }

    func failed() {
        opQueue.cancelAllOperations()
        guard
            let _ = errorBlock,
            let error = safeError
        else {
            finished()
            return
        }
        DispatchQueue.main.async {
            self.errorBlock?(error)
            self.errorBlock = nil
        }
    }

    func canceled() {
        opQueue.cancelAllOperations()
        guard let _ = cancelBlock else {
            finished()
            return
        }
        DispatchQueue.main.async {
            self.cancelBlock?()
            self.cancelBlock = nil
        }

    }

    func finished() {
        DispatchQueue.main.async {
            self.finishBlock(self.state, self.endResult)
            self.finishBlock = { _ in }
        }
    }

    fileprivate func runCancelBlock() {
        var block: CancelBlock?
        writeSafeSync {
            block = self.cancelBlock
            self.cancelBlock = nil
        }
        DispatchQueue.main.async {
            block?()
        }
    }

}
