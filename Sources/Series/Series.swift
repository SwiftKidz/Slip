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

public final class Series {

    public typealias FinishBlock = (FlowState<Any>) -> ()
    public typealias ErrorBlock = (Error) -> ()
    public typealias CancelBlock = () -> ()

    fileprivate var steps: [Step]
    fileprivate typealias AnyThingArray = [Any?]


    fileprivate var finishBlock: FinishBlock = { _ in }
    fileprivate var errorBlock: ErrorBlock?
    fileprivate var cancelBlock: CancelBlock?
    fileprivate var currentState: FlowState<Any> = .queued
    fileprivate let syncQueue = DispatchQueue(label: "com.slip.flow.series.syncQueue", attributes: DispatchQueue.Attributes.concurrent)

    public fileprivate(set) var state: FlowState<Any> {
        get {
            var val: FlowState<Any>!
            syncQueue.sync(flags: .barrier) {
                val = self.currentState
            }
            return val
        }
        set {
            syncQueue.sync(flags: .barrier) {
                self.currentState = newValue
            }
        }
    }

    public init(steps: [Step]) {
        self.steps = steps
    }

    public init(steps: Step...) {
        self.steps = steps
    }

    deinit {
        print("Will De Init Waterfall Flow Object")
    }
}

extension Series {

    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    public func onError(_ block: @escaping ErrorBlock) -> Self {
        guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    public func onCancel(_ block: @escaping CancelBlock) -> Self {
        guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension Series {

    public func start() {
        guard case .queued = state else { print("Cannot start flow twice") ; return }

        if !steps.isEmpty {
            state = .running(AnyThingArray())
            let step = steps.first
            steps.removeFirst()
            step?.runStep(flowController: self)
        } else {
            print("No more steps to run")
        }
    }

    public func cancel() {
        state = .canceled
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

extension Series: FlowController {

    public func finish<T>(_ result: T) {
        guard case .running = state else {
            print("Step finished but flow will be interrupted due to state being : \(state) ")
            return
        }
        var currentValue: AnyThingArray? = state.value as? AnyThingArray
        currentValue?.append(result)
        guard !steps.isEmpty else {
            state = .finished(currentValue ?? [result])
            DispatchQueue.main.async {
                self.finishBlock(self.state)
            }
            return
        }
        var step: Step?

        state = .running(currentValue)
        syncQueue.sync(flags: .barrier, execute: {
            step = self.steps.first
            self.steps.removeFirst()
        })
        step?.runStep(flowController: self)
    }

    public func finish(_ error: Error) {
        state = .failed(error)
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
