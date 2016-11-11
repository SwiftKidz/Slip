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

protocol FlowOpHandler: class {
    func finishedOp(with: FlowOpResult)
}

extension FlowOpHandler where Self: FlowStopped & FlowResults & FlowTypeTests {

    func finishedOp(with res: FlowOpResult) {
        safeBlock {
            guard !hasStopped else {
                print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
                return
            }

            guard res.error == nil else {
                safeState = .failed(res.error!)
                return
            }

            addNew(result: res) { shouldFinish in
                guard shouldFinish else { return }
                self.safeState = .finished
            }

            guard testFlow else { return }
            safeState = .testing
        }
    }
}
