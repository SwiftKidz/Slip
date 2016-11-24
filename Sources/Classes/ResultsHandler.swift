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

class ResultsHandler<T> {
    var rawResults: [T] = []
    let resultsQueue: DispatchQueue
    let finishHandler: ([T], Error?) -> Void
    let numberOfResultsToFinish: Int
    var stop: Bool = false

    required init(maxOps: Int, onFinish: @escaping ([T], Error?) -> Void) {
        resultsQueue = DispatchQueue(label: "com.slip.flow.flowOperationResultsHandler.resultsQueue")
        finishHandler = onFinish
        numberOfResultsToFinish = maxOps
    }

    static func unlimited() -> Self {
        return self.init(maxOps: -1, onFinish: { _ in })
    }
}

extension ResultsHandler {

    var stored: [T] {
        var res: [T]!
        resultsQueue.sync { res = rawResults }
        return res
    }
}

extension ResultsHandler {

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

extension ResultsHandler {

    func add(_ results: [T]) {
        resultsQueue.sync {
            guard !self.stop else { return }
            self.rawResults.append(contentsOf: results)
            guard self.rawResults.count == self.numberOfResultsToFinish else { return }
            self.finish()
        }
    }
}
