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

internal class TestFlow<T>: TestingFlow {

    typealias RunBlock = (FlowControl) -> ()
    typealias TestBlock = (T?) -> (Bool)
    typealias FinishBlock = (FlowState<T>) -> ()
    typealias ErrorBlock = (Error) -> ()
    typealias CancelBlock = () -> ()

    typealias ConditionTestBlock = (FlowState<T>) -> (Bool)

    fileprivate var shouldRunTestBlock: ConditionTestBlock

    fileprivate var finishBlock: FinishBlock
    fileprivate var errorBlock: ErrorBlock?
    fileprivate var cancelBlock: CancelBlock?
    fileprivate var currentInternalState: FlowState<Any>

    fileprivate var runBlock: RunBlock
    fileprivate var testBlock: TestBlock

    fileprivate var backgroundThread: Bool

    var testResult: Bool
    var filterTestResult: (Bool) -> (Bool) = { $0 }

    fileprivate let syncQueue = DispatchQueue(label: "com.slip.flow.syncQueue", attributes: DispatchQueue.Attributes.concurrent)

    public init(onBackgroundThread: Bool = true, whenToRunTest: @escaping ConditionTestBlock, test: @escaping TestBlock, run: @escaping RunBlock) {
        runBlock = run
        testBlock = test
        finishBlock = { _ in }
        currentInternalState = .queued
        backgroundThread = onBackgroundThread
        shouldRunTestBlock = whenToRunTest
        testResult = true
    }
}

extension TestFlow {

    private var testLastResult: Bool {
        get {
            var result: Bool!
            syncQueue.sync(flags: .barrier) {
                result = self.testResult
            }
            return result
        }
        set {
            syncQueue.sync(flags: .barrier) {
                self.testResult = newValue
            }
        }
    }

    func runTest() {
        testLastResult = filterTestResult(testBlock(state.value))
    }

    fileprivate var shouldBreakExecution: Bool {
        return !testLastResult
    }
}

extension TestFlow {

    fileprivate var internalState: FlowState<Any> {
        get {
            var val: FlowState<Any>!
            syncQueue.sync(flags: .barrier) {
                val = self.currentInternalState
            }
            return val
        }
        set {
            syncQueue.sync(flags: .barrier) {
                self.currentInternalState = newValue
            }
            stateChanged()
        }
    }

    public var state: FlowState<T> {
        return internalState.convertType()
    }

    internal func stateChanged() {
        switch internalState {
        case .running:
            run()
        case .canceled:
            canceled()
        case .failed:
            failed()
        case .finished:
            finished()
        case .queued:
            print("Flow is in queue state")
        }
    }
}

extension TestFlow {

    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    public func onError(_ block: @escaping ErrorBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    public func onCancel(_ block: @escaping CancelBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension TestFlow {

    public func start() {
        guard case .queued = internalState else { print("Cannot start flow twice") ; return }
        internalState = .running(nil)
    }

    public func cancel() {
        internalState = .canceled
    }
}

extension TestFlow {

    fileprivate func run() {
        verifyTest()
        guard !shouldBreakExecution else { internalState = .finished(state.value); return }

        guard backgroundThread else { runBlock(self); return }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            self.runBlock(self)
        }
    }

    fileprivate func failed() {
        guard
            let failBlock = errorBlock,
            let error = state.error
            else {
                DispatchQueue.main.async {
                    self.finishBlock(self.state)
                }
                return
        }
        DispatchQueue.main.async {
            failBlock(error)
        }
    }

    fileprivate func canceled() {
        guard let cancelBlock = cancelBlock else {
            DispatchQueue.main.async {
                self.finishBlock(self.state)
            }
            return
        }
        DispatchQueue.main.async {
            cancelBlock()
        }
    }

    fileprivate func finished() {
        verifyTest()
        guard shouldBreakExecution else { internalState = .running(state.value); return }
        DispatchQueue.main.async {
            self.finishBlock(self.state)
        }
    }

    private func verifyTest() {
        guard shouldRunTestBlock(state) else { return }
        runTest()
    }
}

extension TestFlow: FlowControl {

    public func finish<R>(_ result: R) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
        internalState = .finished(result)
    }

    public func finish(_ error: Error) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
        internalState = .failed(error)
    }
}
