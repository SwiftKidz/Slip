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

internal class AsyncOperationFlow<T>: FlowCoreApi {

    public typealias FinishBlock = (State, Result<[T]>) -> ()
    public typealias ValueBlock = ([T]) -> ()

    var finishBlock: FinishBlock?
    var valueBlock: ValueBlock?
    var errorBlock: FlowCoreApi.ErrorBlock?
    var cancelBlock: FlowCoreApi.CancelBlock?

    var rawblocks: [FlowTypeBlocks.RunBlock]
    var testBlock: FlowTypeTests.TestBlock?

    var rawState: State

    var testEnabled: Bool = false
    var testFirst: Bool = true
    var testPassResult: Bool = true

    let queue: DispatchQueue = DispatchQueue(label: "com.slip.flow.AsyncOperationFlow", attributes: .concurrent)

    let limitOfSimultaneousOps: Int
    let qos: QualityOfService
    let synchronous: Bool

    let flowResults: ResultsHandler<T>

    lazy var flowRunner: AsyncOperationRunner<T> = {
        return AsyncOperationRunner<T>(maxSimultaneousOps: self.limitOfSimultaneousOps,
                             qos: self.qos,
                             onFinish: self.process)
    }()

    init(limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
        runQoS: QualityOfService = .background,
        sync: Bool = false) {
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawState = .ready
        rawblocks = []
        flowResults = ResultsHandler.unlimited()
    }

}

extension AsyncOperationFlow {

    func start() {
        guard case .ready = state
        else { print("Cannot start flow twice") ; return }
        state = shouldStartWithTest ? .testing : .running
    }

    func cancel() {
        guard (.running == state || .testing == state)
        else { print("Cannot cancel a flow that is not running") ; return }
        state = .canceled
    }
}
