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

public final class Forever<T>: FlowHandler<T> {

    public typealias Run = (BlockOp) -> ()

    public convenience init(run: @escaping Run,
                            runQoS: QualityOfService = .background,
                            sync: Bool = false) {
        let convertedTest: FlowTypeTests.TestBlock = { testHandler in
            testHandler.complete(success: true, error: nil)
        }
        let convertedRun: FlowTypeBlocks.RunBlock = { (blockOp, _, _) in
            run(blockOp)
        }
        self.init(run: convertedRun, test: convertedTest, limit: 1, runQoS: runQoS, sync: sync)
    }

    private override init(run: @escaping FlowTypeBlocks.RunBlock,
                          test: @escaping FlowTypeTests.TestBlock,
                          limit: Int,
                          runQoS: QualityOfService,
                          sync: Bool) {
        super.init(run: run, test: test, limit: limit, runQoS: runQoS, sync: sync)
        testAtBeginning = true
        testPassResult = true
    }
}
