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

public final class Whilst<T> {

    public typealias RunBlock = (FlowControl) -> ()
    public typealias TestBlock = (T?) -> (Bool)
    public typealias FinishBlock = (FlowState<T>) -> ()
    public typealias ErrorBlock = (Error) -> ()
    public typealias CancelBlock = () -> ()

    fileprivate var finishBlock: FinishBlock
    fileprivate var errorBlock: ErrorBlock?
    fileprivate var cancelBlock: CancelBlock?
    fileprivate var currentInternalState: FlowState<Any> {
        didSet {
           stateChanged()
        }
    }

    fileprivate var runBlock: RunBlock
    fileprivate var testBlock: TestBlock

    fileprivate var backgroundThread: Bool

    fileprivate let syncQueue = DispatchQueue(label: "com.slip.flow.syncQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    public init(onBackgroundThread: Bool = false, test: @escaping TestBlock, run: @escaping RunBlock) {
        runBlock = run
        testBlock = test
        finishBlock = { _ in }
        currentInternalState = .queued
        backgroundThread = onBackgroundThread
    }
}

extension Whilst {
    
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
        return currentInternalState.convertType()
    }

    internal func stateChanged() {
        switch currentInternalState {
        case .running:
            run()
        case .canceled:
            canceled()
        case .failed:
            failed()
        case .finished:
            finished()
        default:
            break
        }
    }
}

extension Whilst {

    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .queued = currentInternalState else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    public func onError(_ block: @escaping ErrorBlock) -> Self {
        guard case .queued = currentInternalState else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    public func onCancel(_ block: @escaping CancelBlock) -> Self {
        guard case .queued = currentInternalState else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension Whilst {

    public func start() {
        guard case .queued = currentInternalState else { print("Cannot start flow twice") ; return }
        currentInternalState = .running(nil)
    }

    public func cancel() {
        currentInternalState = .canceled
    }
}

extension Whilst {

    fileprivate func run() {
        guard case .running(_) = currentInternalState else { return }
        guard testBlock(state.value) else { currentInternalState = .finished(state.value); return }

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
        DispatchQueue.main.async {
            self.finishBlock(self.state)
        }
    }

}

extension Whilst: FlowControl {

    public func finish<R>(_ result: R) {
        guard case .running = currentInternalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(currentInternalState) ")
            return
        }
        currentInternalState = .running(result)
    }

    public func finish(_ error: Error) {
        guard case .running = currentInternalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(currentInternalState) ")
            return
        }
        currentInternalState = .failed(error)
    }
}
