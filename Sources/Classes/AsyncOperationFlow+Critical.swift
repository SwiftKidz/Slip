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

extension AsyncOperationFlow {

    public internal(set) var state: State {
        get {
            var val: State!
            queue.sync { val = self.rawState }
            return val
        }
        set {
            queue.async(flags: .barrier) {
                self.rawState = newValue
            }
        }
    }
}

extension AsyncOperationFlow {

    var blocks: [FlowTypeBlocks.RunBlock] {
        get {
            var val: [FlowTypeBlocks.RunBlock]!
            queue.sync { val = self.rawblocks }
            return val
        }
    }

    func addBlock(_ block: @escaping FlowTypeBlocks.RunBlock) {
        queue.async(flags: .barrier) {
            self.rawblocks.append(block)
        }
    }

    func addBlocks(_ blocks: [FlowTypeBlocks.RunBlock]) {
        queue.async(flags: .barrier) {
            self.rawblocks.append(contentsOf: blocks)
        }
    }

    func removeAllBlocks() {
        queue.async(flags: .barrier) {
            self.rawblocks.removeAll()
        }
    }

}

extension AsyncOperationFlow {

    var hasTest: Bool {
        get {
            var val: Bool!
            queue.sync { val = self.testEnabled }
            return val
        }
        set {
            queue.async(flags: .barrier) {
                self.testEnabled = newValue
            }
        }
    }

    var testBeforeRun: Bool {
        get {
            var val: Bool!
            queue.sync { val = self.testFirst }
            return val
        }
        set {
            queue.async(flags: .barrier) {
                self.testFirst = newValue
            }
        }
    }

    var shouldStartWithTest: Bool {
        var val: Bool!
        queue.sync { val = self.testEnabled && self.testFirst }
        return val
    }
}
