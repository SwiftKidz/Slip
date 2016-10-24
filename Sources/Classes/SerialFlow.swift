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

internal class SerialFlow<T>: StepFlow {

    typealias CurrentStateResultBlock = (_ current: Any?, _ new: Any) -> (Any?)
    typealias CodeBlock = (FlowControl, Any?) -> ()
    typealias FinishBlock = (FlowState<T>) -> ()
    typealias ErrorBlock = (Error) -> ()
    typealias CancelBlock = () -> ()

    fileprivate let syncQueue = DispatchQueue(label: "com.slip.flow.syncQueue", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate var steps: [Step]
    fileprivate var finishBlock: FinishBlock
    fileprivate var errorBlock: ErrorBlock?
    fileprivate var cancelBlock: CancelBlock?
    fileprivate var currentInternalState: FlowState<Any>
    fileprivate var processResult: CurrentStateResultBlock
    fileprivate var passResult: CurrentStateResultBlock

    public init(steps: [Step], process: @escaping CurrentStateResultBlock, passToNext: @escaping CurrentStateResultBlock) {
        self.steps = steps
        self.processResult = process
        self.passResult = passToNext
        self.finishBlock = { _ in }
        self.currentInternalState = .queued
    }

    deinit {
        print("Will De Init Flow Object")
    }
}

extension SerialFlow {

    @discardableResult
    public func step(onBackgroundThread: Bool = false, closure: @escaping CodeBlock) -> Self {
        guard case .queued = internalState else { print("Cannot add steps while running"); return self }
        steps.append(Step(onBackgroundThread: onBackgroundThread, closure: closure))
        return self
    }

}

extension SerialFlow {

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
        }
    }

    public var state: FlowState<T> {
        return internalState.convertType()
    }
}

extension SerialFlow {

    func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    func onError(_ block: @escaping ErrorBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    func onCancel(_ block: @escaping CancelBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension SerialFlow {

    public func start() {
        guard case .queued = internalState else { print("Cannot start flow twice") ; return }

        if !steps.isEmpty {
            internalState = .running(nil)
            let step = steps.first
            steps.removeFirst()
            step?.runStep(flowController: self, previousResult: nil)
        } else {
            internalState = .finished(nil)
            print("No more steps to run")
        }
    }

    public func cancel() {
        internalState = .canceled
        syncQueue.sync(flags: .barrier, execute: {
            self.steps.removeAll()
        })
        DispatchQueue.main.async {
            guard let cancelBlock = self.cancelBlock else {
                self.finishBlock(self.state)
                return
            }
            cancelBlock()
            self.cancelBlock = nil
        }
    }
}

extension SerialFlow: FlowControl {

    public func finish<R>(_ result: R) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
        let nextResult = processResult(internalState.value, result) ?? nil // Result is either Any or nil
        guard !steps.isEmpty else {
            internalState = .finished(nextResult)
            DispatchQueue.main.async {
                self.finishBlock(self.state)
            }
            return
        }
        var step: Step?
        internalState = .running(nextResult)
        syncQueue.sync(flags: .barrier, execute: {
            step = self.steps.first
            self.steps.removeFirst()
        })
        let toPassResult = passResult(internalState.value, result) ?? nil // Result is either Any or nil
        step?.runStep(flowController: self, previousResult: toPassResult)
    }

    public func finish(_ error: Error) {
        internalState = .failed(error)
        syncQueue.sync(flags: .barrier, execute: {
            self.steps.removeAll()
        })
        DispatchQueue.main.async {
            guard let errorBlock = self.errorBlock else {
                self.finishBlock(self.state)
                return
            }
            errorBlock(error)
            self.errorBlock = nil
        }
    }
}
