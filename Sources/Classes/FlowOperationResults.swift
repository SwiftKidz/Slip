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

final class FlowOperationResults {

    fileprivate var rawResults: [FlowOpResult] = []
    fileprivate let resultsQueue: DispatchQueue
    fileprivate var finishHandler: () -> Void

    var numberOfResultsToFinish: Int = -1

    init(onFinish: @escaping () -> Void) {
        resultsQueue = DispatchQueue(label: "com.slip.flow.FlowOperationResults.resultsQueue", attributes: DispatchQueue.Attributes.concurrent)
        finishHandler = onFinish
    }
}

extension FlowOperationResults {

    var currentResults: [FlowOpResult] {
        var res: [FlowOpResult]!
        objc_sync_enter(self)
        //resultsQueue.sync { res = rawResults }
        res = rawResults
        objc_sync_exit(self)
        return res
    }
}

extension FlowOperationResults {

    func addNewResult(_ result: FlowOpResult) {
        objc_sync_enter(self)
        self.rawResults.append(result)
        guard self.rawResults.count == self.numberOfResultsToFinish else { return }
        let handler = self.finishHandler
        self.finishHandler = {}
        DispatchQueue.global(qos: .userInitiated).async {
            handler()
        }
        objc_sync_exit(self)
        /*
        resultsQueue.async(flags: .barrier) {
            self.rawResults.append(result)
            guard self.rawResults.count == self.numberOfResultsToFinish else { return }
            let handler = self.finishHandler
            self.finishHandler = {}
            DispatchQueue.global(qos: .userInitiated).async {
                handler()
            }
        }
        */
    }
}
