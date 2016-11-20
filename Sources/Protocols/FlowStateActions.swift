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

//protocol FlowStateActions: class, FlowCoreApi, FlowState, FlowTypeBlocks, FlowRun, FlowHandlerBlocks {}
//
//extension FlowStateActions {
//
//    func queued() {
//        guard testFlow else { unsafeState = .running; return }
//        guard testAtBeginning else { unsafeState = .running; return }
//        unsafeState = .testing
//    }
//
//    func testing() {
//        runTest ()
//    }
//
//    func running() {
//        testFlow ? runClosure() : runFlowOfBlocks()
//    }
//
//    func failed() {
//        opQueue.cancelAllOperations()
//        guard
//            let _ = errorBlock,
//            let error = unsafeState.error
//        else {
//            finished()
//            return
//        }
//        DispatchQueue.main.async {
//            self.errorBlock?(error)
//            self.errorBlock = nil
//            self.finishBlock = { _ in }
//        }
//    }
//
//    func canceled() {
//        opQueue.cancelAllOperations()
//        guard let _ = cancelBlock else {
//            finished()
//            return
//        }
//        DispatchQueue.main.async {
//            self.cancelBlock?()
//            self.cancelBlock = nil
//            self.finishBlock = { _ in }
//        }
//
//    }
//
//    func finished() {
//        let state = self.unsafeState
//        let result = state.error == nil ? Result.success((state.value as? [T]) ?? []) : Result.failure(state.error!)
//
//        DispatchQueue.main.async {
//            self.finishBlock(state, result)
//            self.finishBlock = { _ in }
//        }
//    }
//}
