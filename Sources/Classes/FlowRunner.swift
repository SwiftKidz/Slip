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
    fileprivate let resultsQueue: DispatchQueue
    fileprivate let opQueue: OperationQueue
    fileprivate var finishHandler: (Result<[FlowOpResult]>) -> Void
    fileprivate var numberOfRunningBlocks: Int

    var onRunSucceed: () -> Void = {}
    var onTestSucceed: () -> Void = {}
    var testFlow: Bool = false
    var testPassResult: Bool = true
    var verbose: Bool = false

    var safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.flowRunnerQueue", attributes: DispatchQueue.Attributes.concurrent)

    init(maxSimultaneousOps: Int,
         qos: QualityOfService,
         onFinish: @escaping (Result<[FlowOpResult]>) -> Void) {
        runnerQueue = DispatchQueue(label: "com.slip.flow.flowRunnerQueue", attributes: DispatchQueue.Attributes.concurrent)
        resultsQueue = DispatchQueue(label: "com.slip.flow.flowRunner.resultsQueue", attributes: DispatchQueue.Attributes.concurrent)
        opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = maxSimultaneousOps
        opQueue.qualityOfService = qos
        finishHandler = onFinish
        numberOfRunningBlocks = -1
    }

    func cancelRunner() {
        stopRunner()
    }
}

extension FlowRunner: Safe {

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

    fileprivate var currentResults: [FlowOpResult] {
        var res: [FlowOpResult]!
        resultsQueue.sync { res = rawResults }
        res = rawResults
        return res
    }

    fileprivate func getCurrentResults() -> [T] {
        return currentResults.flatMap { $0.result as? T }
    }

    fileprivate func addNewResult(result: FlowOpResult) {
        resultsQueue.async(flags: .barrier) {
            self.rawResults.append(result)
            guard self.rawResults.count == self.numberOfRunningBlocks else { return }
            self.handleStop(error: nil, results: self.rawResults)
        }
    }

    fileprivate func finishWith(result: Result<[FlowOpResult]>) {
        let fHandler = finishHandler
        DispatchQueue.global(qos: .background).async {
            fHandler(result)
        }
    }
}

extension FlowRunner {

    func runClosure(runBlock: @escaping TestFlowApi.RunBlock, onFinish: @escaping () -> Void) {
        let execute: (FlowOpResult) -> Void = { (res) in
            self.finishedOp(with: res)
        }

        let run: FlowOp = FlowOp(qos: .background,
                                 orderNumber: rawResults.count,
                                 resultsHandler: { [weak self] in self?.getCurrentResults() ?? [] },
                                 callBack: execute,
                                 run: runBlock)

        opQueue.addOperation(run)
    }

    func runFlowOfBlocks(blocks: [FlowTypeBlocks.RunBlock]) {
        guard !blocks.isEmpty else { finishWith(result: Result.success(rawResults)); return }

        numberOfRunningBlocks = blocks.count

        let execute: (FlowOpResult) -> Void = { (res) in
            self.finishedOp(with: res)
        }

        for i in 0..<blocks.count {
            let op = FlowOp(qos: .background,
                            orderNumber: i,
                            resultsHandler: { [weak self] in self?.getCurrentResults() ?? [] },
                            callBack: execute,
                            run: blocks[i])
            opQueue.addOperation(op)
        }
    }
}

extension FlowRunner {

    func runTest(testBlock: @escaping FlowTypeTests.TestBlock, onFinish: @escaping () -> Void) {
        let execute: (FlowTestResult) -> Void = { (res) in
            self.finishedTest(with: res)
        }
        opQueue.addOperation(FlowTest(qos: .background, callBack: execute, test: testBlock))
    }
}

extension FlowRunner: FlowOpHandler {

    func finishedOp(with res: FlowOpResult) {
        self.handle(op: res)
//        resultsQueue.addOperation {
//
//        }
    }

    func handle(op res: FlowOpResult) {
        guard !shouldStop else {
            if verbose {
                print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            }
            return
        }

        guard res.error == nil else {
            handleStop(error: res.error!, results: currentResults)
            return
        }

        addNewResult(result: res)
//        rawResults.append(res)
//        guard !(rawResults.count == numberOfRunningBlocks) else {
//            handleStop(error: nil)
//            return
//        }

        guard testFlow else { return }

        let runSucceed = onRunSucceed
        DispatchQueue.global(qos: .default).async {
            runSucceed()
        }
    }
}

extension FlowRunner: FlowTestHandler {

    func finishedTest(with res: FlowTestResult) {
        self.handle(test: res)
    }

    func handle(test res: FlowTestResult) {
        guard !shouldStop else {
            if verbose {
                print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            }
            return
        }

        guard res.error == nil else {
            handleStop(error: res.error!, results: currentResults)
            return
        }

        guard testPassResult == res.success else {
            handleStop(error: nil, results: currentResults)
            return
        }

        guard testFlow else { return }

        let testSucceed = onTestSucceed
        DispatchQueue.global(qos: .default).async {
            testSucceed()
        }
    }
}

extension FlowRunner {

    func stopRunner(error: Error? = nil) {
        handleStop(error: nil, results: currentResults)
    }

    func handleStop(error: Error?, results: [FlowOpResult]) {
        let result = error == nil ? Result.success(results) : Result.failure(error!)
        shouldStop = true
        opQueue.cancelAllOperations()
        finishWith(result: result)
    }
}
