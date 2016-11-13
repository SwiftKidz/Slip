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

//Using the "Reader-Writer Access" Asynchrounous Design Pattern

protocol Safe {
    var safeQueue: DispatchQueue { get }
}

extension Safe {

    func readSafe(queue: DispatchQueue, _ block: () -> Void) {
//        print("1 - Entered Read Safe \(queue.label)")
        queue.sync { block(); }//print("1 - Executed Write Safe \(queue.label)") }
//        print("1 - Exited Read Safe \(queue.label)")
    }

    func writeSafe(queue: DispatchQueue, _ block: @escaping () -> Void) {
//        print("2 - Entered Write Safe \(queue.label)")
        queue.async(flags: .barrier) {
            block()
//            print("2 - Executed Write Safe \(queue.label)")
        }
//        print("2 - Exited write Safe \(queue.label)")
    }

    func safeBlock(queue: DispatchQueue, _ block: @escaping () -> Void) {
        queue.async(flags: .barrier) { block() }
    }

//    func readSafe(_ block: () -> Void) {
////        objc_sync_enter(self)
////        defer { objc_sync_exit(self) }
////        block()
//        print("1 - Entered Read Safe")
//        safeQueue.sync { block(); print("1 - Executed Write Safe") }
//        print("1 - Exited Read Safe")
//
//    }
//
//    func writeSafe(_ block: @escaping () -> Void) {
////        objc_sync_enter(self)
////        defer { objc_sync_exit(self) }
////        block()
//        //safeQueue.sync { block() }
//        print("2 - Entered Write Safe")
//        safeQueue.async(flags: .barrier) {
//            block()
//            print("2 - Executed Write Safe")
//        }
////        safeQueue.async(flags: .barrier, execute: block)
//        print("2 - Exited write Safe")
//    }

}
