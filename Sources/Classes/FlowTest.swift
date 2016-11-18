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

final class FlowTest: Operation {

    fileprivate enum ChangeKey: String { case isFinished, isExecuting }

    fileprivate let testQueue: DispatchQueue
    fileprivate let testBlock: FlowTypeTests.TestBlock
    fileprivate let flowCallback: (FlowTestResult) -> Void

    var finishedOp: Bool = false {
        didSet {
            didChangeValue(forKey: ChangeKey.isFinished.rawValue)
        }
        willSet {
            willChangeValue(forKey: ChangeKey.isFinished.rawValue)
        }
    }

    var executingOp: Bool = false {
        didSet {
            didChangeValue(forKey: ChangeKey.isExecuting.rawValue)
        }
        willSet {
            willChangeValue(forKey: ChangeKey.isExecuting.rawValue)
        }
    }

    init(qos: DispatchQoS = .background,
         callBack: @escaping (FlowTestResult) -> Void,
         test: @escaping FlowTypeTests.TestBlock) {
        flowCallback = callBack
        testQueue = DispatchQueue(
            label: "com.slip.flowTest.testQueue",
            qos: qos
        )
        testBlock = test
    }

}

extension FlowTest {

    override func start() {
        guard !isCancelled else { return }
        executingOp = true

        testQueue.async { [unowned self] in
            let testHandler: Test = self
            self.testBlock(testHandler)
        }
    }

    func markAsFinished() {
        executingOp = false
        finishedOp = true
    }
}

extension FlowTest {

    override var isAsynchronous: Bool {
        return true
    }

    override var isFinished: Bool {
        get { return finishedOp }
        set { finishedOp = newValue }
    }

    override var isExecuting: Bool {
        get { return executingOp }
        set { executingOp = newValue }
    }
}

extension FlowTest: Test {

    func complete(success: Bool, error: Error?) {
        guard !isCancelled else { return }
        flowCallback(FlowTestResult(success: success, error: error))
        markAsFinished()
    }
}
