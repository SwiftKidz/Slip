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
    
    fileprivate var finishBlock: FinishBlock
    fileprivate var errorBlock: FlowCoreApi.ErrorBlock?
    fileprivate var cancelBlock: FlowCoreApi.CancelBlock?
    
    fileprivate var rawState: State
    
}

extension AsyncOperationFlow {
    
    public var state: State {
        get {
            var val: State!
//            readSafe(queue: handlerQueue) {
                val = self.rawState
//            }
            return val
        }
        set {
//            writeSafe(queue: handlerQueue) {
//                guard self.rawState != .canceled else { return }
                self.rawState = newValue
//                DispatchQueue.global().async {
//                    self.changedTo(newValue)
//                }
//            }
        }
    }
}
