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

internal final class FlowRunner<T> {

    fileprivate var stop: Bool = false
    fileprivate var rawResults: [FlowOpResult] = []
    fileprivate let runnerQueue: DispatchQueue
    fileprivate let opQueue: OperationQueue
    fileprivate var finishHandler: (Result<[T]>) -> Void

    var onRunSucceed: () -> Void = {}
    var onTestSucceed: () -> Void = {}
    var testPassResult: Bool = true
    var verbose: Bool = false

    init(maxSimultaneousOps: Int,
         qos: QualityOfService,
         onFinish: @escaping (Result<[T]>) -> Void) {
        runnerQueue = DispatchQueue(label: "com.slip.flow.flowRunnerQueue", attributes: DispatchQueue.Attributes.concurrent)
        opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = maxSimultaneousOps
        opQueue.qualityOfService = qos
        finishHandler = onFinish
    }

    func cancel() {
        runnerQueue.async(flags: .barrier) {
            self.handleStop(error: nil, results: self.rawResults)
        }
    }
}

extension FlowRunner {

    fileprivate var current: [FlowOpResult] {
        var res: [FlowOpResult]!
        runnerQueue.sync { res = self.rawResults }
        return res
    }

    fileprivate func add(_ results: [FlowOpResult]) {
        runnerQueue.async(flags: .barrier) {
            self.rawResults.append(contentsOf: results)
        }
    }

}

extension FlowRunner {

    var shouldStop: Bool {
        get {
            var isStopped: Bool!
            runnerQueue.sync { isStopped = stop }
            return isStopped
        }
        set {
            runnerQueue.async(flags: .barrier) {
                self.stop = newValue
            }
        }
    }

    fileprivate func finishWith(result: Result<[T]>) {
        self.finishHandler(result)
    }
}

extension FlowRunner {

    func runFlowOfBlocks(blocks: [FlowTypeBlocks.RunBlock]) {
        guard !blocks.isEmpty else { finishWith(result: Result.success([])); return }

        let handler = FlowResultsHandler(maxOps: blocks.count) { results, error in
            guard let error = error else {
                self.finishWith(result: Result.success(results.flatMap { $0.result as? T }))
                return
            }
            self.finishWith(result: Result.failure(error))
        }

        for i in 0..<blocks.count {
            let op = FlowOp(qos: .background,
                            orderNumber: i,
                            resultsHandler: handler,
                            run: blocks[i])
            opQueue.addOperation(op)
        }
    }
}

extension FlowRunner {

    func runClosure(runBlock: @escaping TestFlowApi.RunBlock) {
        let handler = FlowResultsHandler(maxOps: 1) { results, error in
            self.handleRun(results: results, error: error)
        }

        let run: FlowOp = FlowOp(qos: .background,
                                 orderNumber: rawResults.count,
                                 resultsHandler: handler,
                                 run: runBlock)

        opQueue.addOperation(run)
    }

    func runTest(testBlock: @escaping FlowTypeTests.TestBlock) {
        let execute: (FlowTestResult) -> Void = { (result) in
            self.handle(test: result)
        }
        opQueue.addOperation(FlowTest(qos: .background, callBack: execute, test: testBlock))
    }
}

extension FlowRunner {

    fileprivate func handleRun(results: [FlowOpResult], error: Error?) {
        guard !shouldStop else {
            if verbose {
                print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            }
            return
        }

        guard error == nil else {
            handleStop(error: error!, results: current)
            return
        }

        add(results)

        let runSucceed = onRunSucceed
        DispatchQueue.global().async {
            runSucceed()
        }
    }

    fileprivate func handle(test res: FlowTestResult) {
        guard !shouldStop else {
            if verbose {
                print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            }
            return
        }

        guard res.error == nil else {
            handleStop(error: res.error!, results: current)
            return
        }

        guard testPassResult == res.success else {
            handleStop(error: nil, results: current)
            return
        }

        let testSucceed = onTestSucceed
        DispatchQueue.global().async {
            testSucceed()
        }
    }
}

extension FlowRunner {

    fileprivate func handleStop(error: Error?, results: [FlowOpResult]) {
        let result = error == nil ? Result.success(results.flatMap { $0.result as? T }) : Result.failure(error!)
        shouldStop = true
        opQueue.cancelAllOperations()
        finishWith(result: result)
    }
}
