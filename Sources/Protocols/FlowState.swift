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

protocol FlowState: class, Safe {
    var stateQueue: DispatchQueue { get }
    var rawState: State { get set }
    func changedTo(_ state: State)
}

extension FlowState {

    var safeState: State {
        get {
            var val: State!
            readSafe(queue: stateQueue) {
                val = self.rawState
            }
            return val
        }
        set {
            writeSafe(queue: stateQueue) {
                self.rawState = newValue
                self.changedTo(self.rawState)
            }
        }
    }

    var unsafeState: State {
        get {
            return self.rawState
        }
        set {
            self.rawState = newValue
            changedTo(self.rawState)
        }
    }
}
