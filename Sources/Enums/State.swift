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

public enum State {
    case ready
    case testing
    case running
    case canceled
    case failed(Error)
    case finished(Any)
}

extension State {

    public var error: Error? {
        guard case .failed(let error) = self else { return nil }
        return error
    }

    public var value: Any? {
        guard case .finished(let res) = self else { return nil }
        return res
    }
}

extension State: Equatable {
    public static func==(lhs: State, rhs: State) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready): return true
        case (.testing, .testing): return true
        case (.canceled, .canceled): return true
        case (.failed(_), .failed(_)): return true
        case (.running, .running): return true
        case (.finished, .finished): return true
        default: return false
        }
    }
}
