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

protocol FlowHandlerBlocks: class, Flow {

    var finishBlock: FinishBlock { get set }
    var errorBlock: ErrorBlock? { get set }
    var cancelBlock: CancelBlock? { get set }

}

extension FlowHandlerBlocks {

    func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    func onError(_ block: @escaping ErrorBlock) -> Self {
        guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    func onCancel(_ block: @escaping CancelBlock) -> Self {
        guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}
