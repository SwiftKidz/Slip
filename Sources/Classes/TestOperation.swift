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

extension AsyncOperation {

    static func test(qos: DispatchQoS = .background,
        retryTimes: Int = 0,
        orderNumber: Int = 0,
        store: AsyncOpResultStore? = nil,
        test: @escaping FlowCoreApi.TestBlock)
        -> AsyncOperation {
          return AsyncOperation(qos: qos,
                      retryTimes: retryTimes,
                      orderNumber: orderNumber,
                      store: store,
                      async: { op in
                        guard let top = op as? TestOp else { op.finish(); return }
                        test(top)
          })
    }
}

extension AsyncOperation: TestOp {

    func success(_ result: Bool) {
        finish(result)
    }

    func failed(_ error: Error) {
        finish(error)
    }
}
