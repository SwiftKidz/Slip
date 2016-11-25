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

public final class Times<T>: AsyncOperationFlow<T> {

    public typealias Block = (AsyncOp, Int) -> ()

    private override init(limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                          runQoS: QualityOfService = .background,
                          sync: Bool = false) {
        super.init(limit: limit, runQoS: runQoS, sync: sync)
    }

    public init(runQoS: QualityOfService = .background,
                sync: Bool = false) {
        super.init(limit: OperationQueue.defaultMaxConcurrentOperationCount, runQoS: runQoS, sync: sync)
    }

    @discardableResult
    public func run(number: Int, workBlock: @escaping Block) -> Self {
        let convertedBlocks: [FlowCoreApi.WorkBlock] = [Int](0..<number).map { n in
            return { (operation, iteration, _) in
                workBlock(operation, iteration)
            }
        }
        return blocks(convertedBlocks)
    }

    public static func limit(number: Int,
                             limit: Int,
                             runQoS: QualityOfService = .background,
                             sync: Bool = false,
                             run: @escaping Block) -> Times<T> {
        return Times<T>(limit: limit, runQoS: runQoS, sync: sync).run(number: number, workBlock: run)
    }

    public static func series(number: Int,
                             runQoS: QualityOfService = .background,
                             sync: Bool = false,
                             run: @escaping Block) -> Times<T> {
        return Times<T>(limit: 1, runQoS: runQoS, sync: sync).run(number: number, workBlock: run)
    }
}
