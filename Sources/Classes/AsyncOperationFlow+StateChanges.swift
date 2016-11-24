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

extension AsyncOperationFlow {

    func changedTo(_ state: State) {
        switch state {
        case .ready:
            print("Flow is ready to begin")
        case .testing:
            testing()
        case .running:
            running()
        case .canceled:
            canceled()
        case .failed:
            failed(state.error)
        case .finished:
            finished()
        }
    }

    func testing() {
        executeTest()
    }

    func running() {
        executeBlocks()
    }

    func failed(_ error: Error?) {
        guard let errorBlock = errorBlock, let error = error
            else { finished(); return }
        onMain { errorBlock(error) }
    }

    func canceled() {
        guard let cancelBlock = cancelBlock else { finished(); return }
        onMain { cancelBlock() }
    }

    func finished() {
        guard let finishBlock = finishBlock else { return }
        let state = self.state
        let result = state.error == nil ? Result.success((state.value as? [T]) ?? []) : Result.failure(state.error!)
        onMain { finishBlock(state, result) }
    }

    fileprivate func onMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async { block() }
    }
}
