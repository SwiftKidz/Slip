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

final class FlowOperationResultsHandler {

    fileprivate var rawResults: [FlowOpResult] = []
    fileprivate let resultsQueue: DispatchQueue
    fileprivate let finishHandler: ([FlowOpResult], Error?) -> Void
    fileprivate let numberOfResultsToFinish: Int
    fileprivate var stop: Bool = false

    init(maxOps: Int = -1, onFinish: @escaping ([FlowOpResult], Error?) -> Void) {
        resultsQueue = DispatchQueue(label: "com.slip.flow.flowOperationResultsHandler.resultsQueue")
        finishHandler = onFinish
        numberOfResultsToFinish = maxOps
    }
}

extension FlowOperationResultsHandler {

    var currentResults: [FlowOpResult] {
        var res: [FlowOpResult]!
        resultsQueue.sync { res = rawResults }
        res = rawResults
        return res
    }
}

extension FlowOperationResultsHandler {

    func addNewResult(_ result: FlowOpResult) {
        resultsQueue.sync {
            guard !self.stop else { return }
            guard result.error == nil else {
                self.finish(result.error)
                return
            }
            self.rawResults.append(result)
            guard self.rawResults.count == self.numberOfResultsToFinish else { return }
            self.finish()
        }
    }
}

extension FlowOperationResultsHandler {

    func finish(_ error: Error? = nil) {
        stop = true
        let handler = finishHandler
        let results = rawResults
        let error = error
        DispatchQueue.global().async {
            handler(results, error)
        }
    }
}
