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
    fileprivate var finishHandler: (Result<[FlowOpResult]>) -> Void
    fileprivate var testFlow: Bool = false
    fileprivate var testPassResult: Bool = true
    fileprivate var onRunSucceed: () -> Void = {}
    fileprivate var onTestSucceed: () -> Void = {}
    fileprivate var numberOfRunningBlocks: Int

    var safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.flowRunnerQueue", attributes: DispatchQueue.Attributes.concurrent)

    init(maxSimultaneousOps: Int,
         qos: QualityOfService,
         onFinish: @escaping (Result<[FlowOpResult]>) -> Void) {
        runnerQueue = DispatchQueue(label: "com.slip.flow.flowRunnerQueue", attributes: DispatchQueue.Attributes.concurrent)
        opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = maxSimultaneousOps
        opQueue.qualityOfService = qos
        finishHandler = onFinish
        numberOfRunningBlocks = -1
    }
}

extension FlowRunner: Safe {

    fileprivate var currentResults: [FlowOpResult] {
        var res: [FlowOpResult]!
        readSafe(queue: runnerQueue) { res = rawResults }
        return res
    }

    fileprivate func getCurrentResults() -> [T] {
        return currentResults.flatMap { $0.result as? T }
    }

    fileprivate var shouldStop: Bool {
        var stopping: Bool!
        readSafe(queue: runnerQueue) { stopping = stop }
        return stopping
    }

    fileprivate func finishWith(result: Result<[FlowOpResult]>) {
        let fHandler = finishHandler
        DispatchQueue.global(qos: .default).async {
            fHandler(result)
        }
    }

    func cancelRunner() {
        writeSafe(queue: runnerQueue) { self.stop = true }
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

        onRunSucceed = onFinish

        opQueue.addOperation(run)
    }

    func runFlowOfBlocks(blocks: [FlowTypeBlocks.RunBlock]) {
        guard !blocks.isEmpty else { finishWith(result: Result.success(rawResults)); return }

        numberOfRunningBlocks = blocks.count

        let execute: (FlowOpResult) -> Void = { (res) in
            self.finishedOp(with: res)
        }

        for i in 0..<blocks.count {
            opQueue.addOperation(FlowOp(qos: .background,
                                        orderNumber: i,
                                        resultsHandler: { [weak self] in self?.getCurrentResults() ?? [] },
                                        callBack: execute,
                                        run: blocks[i]))
        }
    }
}

extension FlowRunner {

    func runTest(testBlock: @escaping FlowTypeTests.TestBlock, onFinish: @escaping () -> Void) {
        let execute: (FlowTestResult) -> Void = { (res) in
            self.finishedTest(with: res)
        }
        opQueue.addOperation(FlowTest(qos: .background, callBack: execute, test: testBlock))

        onTestSucceed = onFinish
    }
}

extension FlowRunner: FlowOpHandler {

    func finishedOp(with res: FlowOpResult) {
        safeBlock(queue: runnerQueue) {
            self.handle(op: res)
        }
    }

    func handle(op res: FlowOpResult) {
        guard !stop else {
            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            return
        }

        guard res.error == nil else {
            finishWith(result: Result.failure(res.error!))
            return
        }

        rawResults.append(res)
        guard !(rawResults.count == numberOfRunningBlocks) else {
            finishWith(result: Result.success(rawResults))
            return
        }

        guard testFlow else { return }
        onRunSucceed()
    }
}

extension FlowRunner: FlowTestHandler {

    func finishedTest(with res: FlowTestResult) {
        safeBlock(queue: runnerQueue) {
            self.handle(test: res)
        }
    }

    func handle(test res: FlowTestResult) {
        guard !stop else {
            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            return
        }

        guard res.error == nil else {
            finishWith(result: Result.failure(res.error!))
            return
        }

        guard testPassResult == res.success else {
            finishWith(result: Result.success(rawResults))
            return
        }
        onTestSucceed()
    }
}

extension FlowRunner {

}
