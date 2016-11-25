//
//  FlowCoreApi.swift
//  Slip
//
//  Created by João Mourato on 31/10/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import Foundation

public protocol FlowCoreApi {

    associatedtype T

    typealias WorkBlock = (AsyncOp, Int, Any) -> Void
    typealias TestBlock = (TestOp) -> Void

    typealias FinishBlock = (State, Result<[T]>) -> Void
    typealias ErrorBlock = (Error) -> Void
    typealias CancelBlock = () -> Void
    typealias ValueBlock = ([T]) -> ()


    func onFinish(_ block: @escaping FinishBlock) -> Self
    func onError(_ block: @escaping ErrorBlock) -> Self
    func onCancel(_ block: @escaping CancelBlock) -> Self
    func onValue(_ block: @escaping ValueBlock) -> Self

    var state: State { get }

    func start()
    func cancel()
}
