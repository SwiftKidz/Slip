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

internal class FlowRunner<T> {

    typealias FinishBlock = (FlowState<[T]>) -> ()

    var finishBlock: FinishBlock
    var errorBlock: FlowCore.ErrorBlock?
    var cancelBlock: FlowCore.CancelBlock?

    var runBlock: FlowRunType.RunBlock
    var testBlock: FlowRunType.TestBlock

    var rawState: FlowState<Any>
    var rawResults: [FlowOpResult]

    let blocks: [FlowRunType.RunBlock]
    let limitOfSimultaneousOps: Int
    let qos: QualityOfService
    let synchronous: Bool

    var testFlow: Bool = false
    var testAtBeginning: Bool = true
    var runAfterTest: (() -> ())?

    let safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.safeQueue", attributes: DispatchQueue.Attributes.concurrent)

    lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = self.limitOfSimultaneousOps
        queue.qualityOfService = .background
        return queue
    }()

    convenience init(runBlocks: [FlowRunType.RunBlock],
         limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
         runQoS: QualityOfService = .background,
         sync: Bool = false) {
        self.init(runBlocks: runBlocks,
                  run: { _ in },
                  test: { _ in },
                  limit: limit,
                  runQoS: runQoS,
                  sync: sync)
    }

    convenience init(run: @escaping FlowRunType.RunBlock,
                     test: @escaping FlowRunType.TestBlock,
                     limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                     runQoS: QualityOfService = .background,
                     sync: Bool = false) {
        self.init(runBlocks: [],
                  run: run,
                  test: test,
                  limit: limit,
                  runQoS: runQoS,
                  sync: sync)
    }

    private init(runBlocks: [FlowRunType.RunBlock],
                 run: @escaping FlowRunType.RunBlock,
                 test: @escaping FlowRunType.TestBlock,
                 limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                 runQoS: QualityOfService = .background,
                 sync: Bool = false) {
        rawState = .ready
        finishBlock = { _ in }
        blocks = runBlocks
        runBlock = run
        testBlock = test
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
    }

}

extension FlowRunner: FlowHandlerBlocks {}

extension FlowRunner: Safe, SafeState {}

extension FlowRunner: FlowResults {

    var numberOfRunningBlocks: Int {
        return blocks.count
    }
}

extension FlowRunner: FlowStateChanged {}

extension FlowRunner: FlowOpHandler {

    var isCanceled: Bool {
        return !(safeState == FlowState.running(nil))
    }

    var currentResults: Any? {
        return safeResults.map { $0.result }
    }

    func finished(with res: FlowOpResult) {
        guard !testFlow else { return }

        let shouldFinish = addNewResult(res)
        guard shouldFinish else { return }
        safeState = .finished(safeResults.map { $0.result })
    }
}

extension FlowRunner: FlowRunType {

    var lastRunResult: Any {
        return safeResults
    }

    func testComplete(success: Bool, error: Error?) {

    }
}

extension FlowRunner: FlowCore {

    var state: FlowState<[T]> {
        return safeState.convertType()
    }

    func start() {
        guard case .ready = safeState else { print("Cannot start flow twice") ; return }
        safeState = .queued
        //safeState = .running(outputResults)
        //checkFlowTypeAndRun()
    }

    func cancel() {
        guard case .running = safeState else { print("Cannot cancel a flow that is not running") ; return }
        safeState = .canceled
    }
}
