//
//  MockErrors.swift
//  Slip
//
//  Created by iOS on 22/10/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import Foundation
import Slip

struct MockFlow: FlowControl {

    func finish(_ error: Error) {

    }
    func finish<T>(_ result: T) {

    }
}

enum MockErrors: Error {
    case errorOnFlow
}
