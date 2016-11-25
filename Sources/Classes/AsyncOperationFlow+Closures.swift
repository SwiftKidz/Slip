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

    @discardableResult
    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .ready = state
        else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    @discardableResult
    public func onValue(_ block: @escaping ValueBlock) -> Self {
        guard case .ready = state
        else { print("Cannot modify flow after starting") ; return self }
        valueBlock = block
        return self
    }

    @discardableResult
    public func onError(_ block: @escaping FlowCoreApi.ErrorBlock) -> Self {
        guard case .ready = state
        else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    @discardableResult
    public func onCancel(_ block: @escaping FlowCoreApi.CancelBlock) -> Self {
        guard case .ready = state
        else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension AsyncOperationFlow {

    @discardableResult
    func blocks(_ blocks: [FlowCoreApi.WorkBlock]) -> Self {
        guard case .ready = state
        else { print("Cannot modify flow after starting") ; return self }
        addBlocks(blocks)
        return self
    }

    @discardableResult
    func run(_ block: @escaping FlowCoreApi.WorkBlock) -> Self {
        guard case .ready = state
            else { print("Cannot modify flow after starting") ; return self }
        addBlock(block)
        return self
    }
}

extension AsyncOperationFlow {

    @discardableResult
    func test(beforeRun: Bool = true, expectedToPass: Bool = true, _ block: @escaping FlowCoreApi.TestBlock) -> Self {
        guard case .ready = state
        else { print("Cannot modify flow after starting") ; return self }
        testBlock = block
        testEnabled = true
        testFirst = beforeRun
        testPassResult = expectedToPass
        return self
    }
}
