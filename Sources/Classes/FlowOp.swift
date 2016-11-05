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

final class FlowOp {

    typealias RunBlock = (BlockOp, Int, Any?) -> ()

    fileprivate let order: Int
    fileprivate let flow: FlowOpHandler
    fileprivate let runBlock: RunBlock

    init(orderNumber: Int, flowHandler: FlowOpHandler, run: @escaping RunBlock) {
        order = orderNumber
        flow = flowHandler
        runBlock = run
    }
}

extension FlowOp {

    var operation: Operation {
        let f: BlockOp = self
        let o: Int = order
        return BlockOperation { [weak self] in
            guard
                let strongSelf = self,
                !strongSelf.flow.isCanceled
            else { return }

            strongSelf.runBlock(f, o, strongSelf.flow.results)
        }
    }
}

extension FlowOp: BlockOp {

    func finish<R>(_ result: R) {
        guard !flow.isCanceled else {
            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            return
        }
        flow.finished(with: FlowOpResult(order: order, result: result, error: nil))
    }

    func finish(_ error: Error) {
        guard !flow.isCanceled else {
            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            return
        }
        flow.finished(with: FlowOpResult(order: order, result: nil, error: error))
    }
}
