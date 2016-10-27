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

public enum FlowState<R> {
    case queued
    case running(R?)
    case canceled
    case failed(Error)
    case finished(R?)

    public var value: R? {
        switch self {
        case .running(let r):
            return r ?? nil
        case .finished(let r):
            return r ?? nil
        default:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .failed(let e):
            return e
        default:
            return nil
        }
    }

    func convertType<T>() -> FlowState<T> {
        switch self {
        case .queued:
            return FlowState<T>.queued
        case .canceled:
            return FlowState<T>.canceled
        case .failed(let e):
            return FlowState<T>.failed(e)
        case .running(let r):
            return FlowState<T>.running(r as? T)
        case .finished(let f):
            return FlowState<T>.finished(f as? T)
        }
    }
}

extension FlowState: Equatable {
    public static func==(lhs: FlowState, rhs: FlowState) -> Bool {
        switch (lhs, rhs) {
        case (.queued, .queued): return true
        case (.canceled, .canceled): return true
        case (.failed, .failed): return true
        case (.running, .running): return true
        case (.finished, .finished): return true
        default: return false
        }
    }
}
//
//extension FlowState {
//
//    func sorted<R: Collection>(by orderingBlock: (R.Iterator.Element,R.Iterator.Element)->(Bool)) -> R? {
//
//    }
//}
