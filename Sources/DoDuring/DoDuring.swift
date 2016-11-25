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

public final class DoDuring<T>: AsyncOperationFlow<T> {

    public typealias AsyncTest = (TestOp) -> ()
    public typealias Run = (AsyncOp) -> ()

    public override init(limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                         runQoS: QualityOfService = .background,
                         sync: Bool = false) {
        super.init(limit: limit, runQoS: runQoS, sync: sync)
    }

    @discardableResult
    public func run(workBlocks: [Run]) -> Self {
        return blocks(workBlocks.map { runBlock in
            return { asyncOp, _, _ in
                runBlock(asyncOp)
            }
        })
    }

    @discardableResult
    public func run(workBlock: @escaping Run) -> Self {
        return run({ asyncOp, _, _ in
            workBlock(asyncOp)
        })
    }

    @discardableResult
    public func test(_ testBlock: @escaping AsyncTest) -> Self {
        return test(beforeRun: false, expectedToPass: true, testBlock)
    }
}
