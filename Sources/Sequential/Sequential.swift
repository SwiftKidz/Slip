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

public final class Sequential<T>: FlowRunner<T> {

    public typealias Block = (BlockOp, T?) -> ()

    public convenience init(runBlocks: [Block],
                            runQoS: QualityOfService = .background,
                            sync: Bool = false) {

        func toRunBlock(run: @escaping Block) -> BlockFlowApi.RunBlock {
            return { (operation, _, results) in
                let lastResult = (results as? [T])?.last
                run(operation, lastResult)
            }
        }
        let convertedBlocks: [BlockFlowApi.RunBlock] = runBlocks.map(toRunBlock)

        self.init(runBlocks: convertedBlocks, limit: 1, runQoS: runQoS, sync: sync)
    }

    private override init(runBlocks: [BlockFlowApi.RunBlock],
                          limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                          runQoS: QualityOfService = .background,
                          sync: Bool = false) {
        super.init(runBlocks: runBlocks, limit: limit, runQoS: runQoS, sync: sync)
    }
}
