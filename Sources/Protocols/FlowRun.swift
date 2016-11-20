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

//protocol FlowRun: class, FlowCoreApi, FlowTypeTests {
//    var flowRunner: FlowRunner<T> { get }
//    var opQueue: OperationQueue { get }
//}
//
//extension FlowRun {
//
//    func runClosure() {
//        flowRunner.onRunSucceed = { self.safeState = .testing }
//        flowRunner.runClosure(runBlock: runBlock)
//    }
//
//    func runTest() {
//        flowRunner.testPassResult = testPassResult
//        flowRunner.onTestSucceed = { self.safeState = .running }
//        flowRunner.runTest(testBlock: testBlock)
//    }
//}
//
//extension FlowRun {
//
//    func runFlowOfBlocks() {
//        flowRunner.runFlowOfBlocks(blocks: blocks)
//        blocks.removeAll()
//    }
//}
