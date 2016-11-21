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
//
//final class FlowOp {
//
//    fileprivate let resultHandler: FlowResultsHandler
//    fileprivate var retryCount: Int
//
//    init(qos: DispatchQoS = .background,
//         retryTimes: Int,
//         orderNumber: Int,
//         resultsHandler: FlowResultsHandler,
//         run: @escaping FlowTypeBlocks.RunBlock) {
//        retryCount = retryTimes
//        resultHandler = resultsHandler
////        super.init(qos: qos, orderNumber: orderNumber) {
////
////        }
////        asyncBlock = { [unowned self] in
////            let results = self.resultHandler.currentResults
////            let order: Int = self.order
////            let blockOp: BlockOp = self
////            run(blockOp, order, results.map { $0.result })
////        }
//    }
//}
//
//extension FlowOp: BlockOp {
//
//    func finish<R>(_ result: R) {
////        guard !isCancelled else { return }
////        resultHandler.addNewResult(FlowOpResult(order: order, result: result, error: nil))
////        markAsFinished()
//    }
//
//    func finish(_ error: Error) {
////        guard !isCancelled else { return }
////        resultHandler.addNewResult(FlowOpResult(order: order, result: nil, error: error))
////        markAsFinished()
//    }
//}
