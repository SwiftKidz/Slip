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

    typealias FinishBlock = (FlowState, Result<[T]>) -> ()//(Flow) -> ()
    typealias ErrorBlock = (Error) -> ()
    typealias CancelBlock = () -> ()

    func onFinish(_ block: @escaping FinishBlock) -> Self
    func onError(_ block: @escaping ErrorBlock) -> Self
    func onCancel(_ block: @escaping CancelBlock) -> Self

    var state: FlowState { get }

    func start()
    func cancel()
}
