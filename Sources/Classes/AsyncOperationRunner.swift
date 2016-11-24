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

typealias FlowRunner<T> = AsyncOperationRunner<T>

internal final class AsyncOperationRunner<T> {

    typealias Block = () -> Void

    fileprivate var stop: Bool = false
    fileprivate var rawResults: [AsyncOpResult] = []
    fileprivate let queue: DispatchQueue
    fileprivate let opQueue: OperationQueue
    fileprivate var finishHandler: (Result<[T]>) -> Void

    fileprivate lazy var testStore: AsyncOpResultStore = {
        return AsyncResultsHandler.unlimited()
    }()

    var onRunSucceed: Block = {}
    var onTestSucceed: Block = {}
    var testPassResult: Bool = true
    var testing: Bool = false

    var verbose: Bool = false
    var orderedOutput: Bool = false

    init(maxSimultaneousOps: Int,
         qos: QualityOfService,
         onFinish: @escaping (Result<[T]>) -> Void) {
        queue = DispatchQueue(label: "com.slip.flow.flowRunnerQueue", attributes: .concurrent)
        opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = maxSimultaneousOps
        opQueue.qualityOfService = qos
        finishHandler = onFinish
    }

    func cancel() {
        self.handleStop(error: nil, results: [])
    }
}

extension AsyncOperationRunner {

    fileprivate func resultStore(for maxOps: Int, isTest: Bool = false) -> AsyncResultsHandler {
        guard maxOps != 1 else {
            return AsyncResultsHandler() { results, error in
                self.handleRun(result: results.first, error: error, isTest: isTest)
            }
        }

        return AsyncResultsHandler(maxOps: maxOps) { results, error in
            guard !self.shouldStop else { return }

            guard let error = error else {
                let outcome = self.orderedOutput ? results.sorted(by: { $0.0.order < $0.1.order }) : results
                self.finishWith(result: Result.success(outcome.flatMap { $0.result as? T }))
                return
            }
            self.finishWith(result: Result.failure(error))
        }
    }
}

extension AsyncOperationRunner {

    var shouldStop: Bool {
        get {
            var isStopped: Bool!
            queue.sync { isStopped = stop }
            return isStopped
        }
        set {
            queue.async(flags: .barrier) {
                self.stop = newValue
            }
        }
    }

    fileprivate func finishWith(result: Result<[T]>) {
        DispatchQueue.global().async {
            self.finishHandler(result)
        }
    }
}

extension AsyncOperationRunner {

    func runFlowOfBlocks(blocks: [FlowTypeBlocks.RunBlock]) {
        guard !blocks.isEmpty else { finishWith(result: Result.success([])); return }

        let store: AsyncOpResultStore = resultStore(for: blocks.count)

        for i in 0..<blocks.count {
            let op = AsyncOperation.work(qos: .background, retryTimes: 0, orderNumber: i, store: store, run: blocks[i])
            opQueue.addOperation(op)
        }
    }
}

extension AsyncOperationRunner {

    func runClosure(runBlock: @escaping TestFlowApi.RunBlock) {
        let store: AsyncOpResultStore = resultStore(for: 1)

        let op = AsyncOperation.work(qos: .background, retryTimes: 0, orderNumber: testStore.current.count, store: store, run: runBlock)
        opQueue.addOperation(op)
    }

    func runTest(testBlock: @escaping FlowTypeTests.TestBlock) {
        let store: AsyncOpResultStore = resultStore(for: 1, isTest: true)

        let op = AsyncOperation.test(qos: .background, retryTimes: 0, orderNumber: testStore.current.count, store: store, test: testBlock)
        opQueue.addOperation(op)
    }
}

extension AsyncOperationRunner {

    fileprivate func handleRun(result: AsyncOpResult?, error: Error?, isTest: Bool = false) {
        guard !shouldStop else {
            if verbose {
                print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            }
            return
        }

        guard error == nil else {
            handleStop(error: error!, results: testStore.current)
            return
        }

        guard let result = result else { return }

        if isTest {
            guard
                testPassResult == result.success else {
                handleStop(error: nil, results: testStore.current)
                return
            }
        } else {
            testStore.addNewResult(result)
        }

        let successed = isTest ? onTestSucceed : onRunSucceed
        DispatchQueue.global().async {
            successed()
        }
    }
}

extension AsyncOperationRunner {

    fileprivate func handleStop(error: Error?, results: [AsyncOpResult]) {
        queue.async(flags: .barrier) {
            self.stopRunner(error: error, results: results)
        }
    }

    private func stopRunner(error: Error?, results: [AsyncOpResult]) {
        let result = error == nil ? Result.success(results.flatMap { $0.result as? T }) : Result.failure(error!)
        stop = true
        opQueue.cancelAllOperations()
        finishWith(result: result)
    }
}
