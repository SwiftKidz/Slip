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

internal class FlowRunner<T>: FlowCoreApi {

    public typealias FinishBlock = (State, Result<[T]>) -> ()

    var finishBlock: FinishBlock
    var errorBlock: FlowCoreApi.ErrorBlock?
    var cancelBlock: FlowCoreApi.CancelBlock?

    var runBlock: FlowTypeBlocks.RunBlock
    var testBlock: FlowTypeTests.TestBlock

    var rawState: State
    var rawResults: [FlowOpResult]
    var rawError: Error?

    var blocks: [FlowTypeBlocks.RunBlock]
    let numberOfRunningBlocks: Int

    let limitOfSimultaneousOps: Int
    let qos: QualityOfService
    let synchronous: Bool

    var testFlow: Bool = false
    var testAtBeginning: Bool = true
    var testPassResult: Bool = true

    let safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.safeQueue", attributes: DispatchQueue.Attributes.concurrent)

    lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = self.limitOfSimultaneousOps
        queue.qualityOfService = self.qos

        return queue
    }()

    init(runBlocks: [FlowTypeBlocks.RunBlock],
         limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
         runQoS: QualityOfService = .background,
         sync: Bool = false) {
        rawState = .ready
        finishBlock = { _ in }
        blocks = runBlocks
        numberOfRunningBlocks = runBlocks.count
        runBlock = { $0.0.finish() }
        testBlock = { $0.complete(success: false, error: nil) }
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
        stateChanged()
    }

    init(run: @escaping FlowTypeBlocks.RunBlock,
                     test: @escaping FlowTypeTests.TestBlock,
                     limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                     runQoS: QualityOfService = .background,
                     sync: Bool = false) {
        rawState = .ready
        finishBlock = { _ in }
        blocks = []
        numberOfRunningBlocks = 0
        runBlock = run
        testBlock = test
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
        stateChanged()
        testFlow = true
    }
}

extension FlowRunner: Safe {}

extension FlowRunner: FlowState {}

extension FlowRunner: FlowError {}

extension FlowRunner: FlowStopped {}

extension FlowRunner: FlowHandlerBlocks {

    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    public func onError(_ block: @escaping FlowCoreApi.ErrorBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    public func onCancel(_ block: @escaping FlowCoreApi.CancelBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension FlowRunner: FlowTypeBlocks {}

extension FlowRunner: FlowTypeTests {}

extension FlowRunner: FlowRun {}

extension FlowRunner: FlowResults {}

extension FlowRunner: FlowOutcome {}

extension FlowRunner {

    var state: State {
        return safeState
    }

    public func start() {
//        guard case .ready = safeState else { print("Cannot start flow twice") ; return }
//        safeState = .queued
        runFlowOfBlocks()
    }

    public func cancel() {
        guard case .running = safeState else { print("Cannot cancel a flow that is not running") ; return }
        safeState = .canceled
    }
}



extension FlowRunner {

    func runClosure() {
        //let run = FlowOp(orderNumber: safeResults.count, flowHandler: self, run: runBlock).operation
        //opQueue.addOperation(run)
    }

    func runFlowOfBlocks() {
        guard !blocks.isEmpty else { safeState = .finished; return }

        //let ops = [Int](0..<blocks.count).map { FlowOp(orderNumber: $0, flowHandler: self, run: blocks[$0]) }.map { $0.operation }
        var ops: [Operation] = []

        for i in 0..<blocks.count {
            //ops.append(FlowOp(orderNumber: i, flowHandler: self, run: blocks[i]).operation)
            //opQueue.addOperation(FlowOp(orderNumber: i, flowHandler: self, run: blocks[i]).operation)
            ops.append(operationFrom(block: blocks[i], order: i))
        }

//        let fop = BlockOperation { [weak self] in
//            guard let strongSelf = self else { return }
//            //strongSelf.safeState = .finished
//            strongSelf.runFinishBlock()
//        }

//        ops.forEach { fop.addDependency($0) }
//        ops.append(fop)

        opQueue.addOperations(ops, waitUntilFinished: false)
        blocks.removeAll()
    }

    private func operationFrom(block: @escaping FlowTypeBlocks.RunBlock, order: Int) -> Operation {
        let f: BlockOp = FlowOp(orderNumber: order) { [weak self] (res) in
            self?.finishedOp(with: res)
        }
        let o: Int = order
        return BlockOperation { [weak self] in
            block(f, o, self?.results ?? [])
        }
    }
}

extension FlowRunner {

    func runTest() {
        let test = FlowTest(flowHandler: self, test: testBlock).operation
        opQueue.addOperation(test)
    }
}

extension FlowRunner {

    func stateChanged() {
        switch safeState {
        case .testing:
            testing()
        case .running:
            running()
        case .canceled:
            canceled()
        case .failed:
            failed()
        case .finished:
            finished()
        case .queued:
            queued()
        case .ready:
            print("Flow is ready to begin")
        }
    }

    func testing() {
        runTest()
    }

    func running() {
        testFlow ? runClosure() : runFlowOfBlocks()
    }

    func queued() {
        guard testFlow else { safeState = .running; return }
        guard testAtBeginning else { safeState = .running; return }
        safeState = .testing
    }

    func failed() {
        opQueue.cancelAllOperations()
        guard
            let _ = errorBlock,
            let error = safeError
            else {
                DispatchQueue.main.async {
                    self.runFinishBlock()
                }
                return
        }
        DispatchQueue.main.async {
            self.runErrorBlock(error: error)
        }
    }

    func canceled() {
        opQueue.cancelAllOperations()
        guard let _ = cancelBlock else {
            DispatchQueue.main.async {
                self.runFinishBlock()
            }
            return
        }
        DispatchQueue.main.async {
            self.runCancelBlock()
        }
    }

    func finished() {
        DispatchQueue.main.async {
            self.runFinishBlock()
        }
    }

    fileprivate func runFinishBlock() {
        finishBlock(self.safeState, self.endResult)
//        var finishBlock: FinishBlock!
//        write {
//            finishBlock = self.finishBlock
//            self.finishBlock = { _ in }
//            finishBlock(self.safeState, self.endResult)
//        }
    }

    fileprivate func runCancelBlock() {
        var cancelBlock: FlowCoreApi.CancelBlock!
        writeSafe {
            cancelBlock = self.cancelBlock
            self.cancelBlock = { }
            cancelBlock()
        }
    }

    fileprivate func runErrorBlock(error: Error) {
        var errorBlock: FlowCoreApi.ErrorBlock!
        writeSafe {
            errorBlock = self.errorBlock
            self.errorBlock = { _ in }
            errorBlock(error)
        }

    }
}

extension FlowRunner: FlowOpHandler {

    func finishedOp(with res: FlowOpResult) {
        addNew(result: res) { [weak self] shouldFinish in
            guard shouldFinish else { return }
            self?.finished()
        }
    }

    var results: Any? {
        return currentResults
    }

    func finished(with res: FlowOpResult) {
        //        //print("\(safeResults.count)")
        //        guard !hasStopped else {
        //            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
        //            return
        //        }
        //
//
//        guard res.error == nil else {
//            safeError = res.error!
//            safeState = .failed
//            return
//        }
//
//        let shouldFinish = addNewResult(res)
//
//        guard !testFlow else {
//            safeState = .testing
//            return
//        }
//
//        guard shouldFinish else { return }
//        safeState = .finished
    }

}

extension FlowRunner: FlowTestHandler {

    func finished(with res: FlowTestResult) {
        guard !hasStopped else {
            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
            return
        }

        guard res.error == nil else {
            safeError = res.error!
            safeState = .failed
            return
        }

        guard testPassResult == res.success else { safeState = .finished; return }
        safeState = .running
    }
}
//extension FlowRunner: BlockOp {
//
//    func finish<R>(_ result: R) {
//        //        guard !flow.hasStopped else {
//        //            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
//        //            return
//        //        }
//        //finished(with: FlowOpResult(order: order, result: result, error: nil))
//    }
//
//    func finish(_ error: Error) {
//        //        guard !flow.hasStopped else {
//        //            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
//        //            return
//        //        }
//        //finished(with: FlowOpResult(order: order, result: nil, error: error))
//    }
//}
extension FlowRunner: Test {
    func complete(success: Bool, error: Error?) {
        //        guard !flow.hasStopped else {
        //            print("Flow has been stoped, either by error or manually canceled. Ignoring result of unfinished operation")
        //            return
        //        }
        finished(with: FlowTestResult(success: success, error: error))
    }
}
