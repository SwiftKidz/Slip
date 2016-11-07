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

protocol FlowHandlerBlocks: class, FlowCoreApi, FlowTypeBlocks, FlowTypeTests {

    var finishBlock: FinishBlock { get set }
    var errorBlock: ErrorBlock? { get set }
    var cancelBlock: CancelBlock? { get set }

    var runBlock: RunBlock { get set }
    var testBlock: TestBlock { get set }

}

extension FlowHandlerBlocks {

    public func onRun(_ block: @escaping RunBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        runBlock = block
        return self
    }

    public func onTest(_ block: @escaping TestBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        testBlock = block
        return self
    }
}
