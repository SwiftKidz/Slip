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

protocol FlowStateChanged: class, FlowCore, FlowHandlerBlocks, SafeState, FlowResults, FlowError, FlowRun {}

extension FlowStateChanged where Self: FlowOpHandler & FlowTestHandler & FlowTypeTests & FlowTypeBlocks & FlowOutcome {

    func stateChanged() {
        switch safeState {
        case .testing:
            testing()
        case .running:
            running()
        case .canceled:
            canceled()
        case .failed:
            failed()
        case .finished:
            finished()
        case .queued:
            queued()
        case .ready:
            print("Flow is ready to begin")
        }
    }

    func testing() {
        runTest()
    }

    func running() {
        testFlow ? runClosure() : runFlowOfBlocks()
    }

    func queued() {
        guard testFlow else { safeState = .running; return }
        guard testAtBeginning else { safeState = .running; return }
        safeState = .testing
    }

    func failed() {
        print("fb error \(safeState)")
        opQueue.cancelAllOperations()
        guard
            let _ = errorBlock,
            let error = safeError
        else {
            DispatchQueue.main.async {
                self.runFinishBlock()
            }
            return
        }
        DispatchQueue.main.async {
            self.runErrorBlock(error: error)
        }
    }

    func canceled() {
        print("fb canceled \(safeState)")
        opQueue.cancelAllOperations()
        guard let _ = cancelBlock else {
            DispatchQueue.main.async {
                 self.runFinishBlock()
            }
            return
        }
        DispatchQueue.main.async {
            self.runCancelBlock()
        }
    }

    func finished() {
        print("fb finished \(safeState)")
        runFinishBlock()
    }

    fileprivate func runFinishBlock() {
        var finishBlock: FinishBlock!
        write {
            finishBlock = self.finishBlock
            self.finishBlock = { _ in }
        }
        finishBlock(self.safeState, self.endResult)
    }

    fileprivate func runCancelBlock() {
        var cancelBlock: CancelBlock!
        write {
            cancelBlock = self.cancelBlock
            self.cancelBlock = { }
        }
        cancelBlock()
    }

    fileprivate func runErrorBlock(error: Error) {
        var errorBlock: ErrorBlock!
        write {
            errorBlock = self.errorBlock
            self.errorBlock = { _ in }
        }
        errorBlock(error)
    }
}
