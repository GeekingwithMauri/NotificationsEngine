//
//  MainThreadGuarantee.swift
//  
//
//  Created by Mauricio Chirino on 27/6/22.
//

import Foundation

/// Fail-check that guarantees _main's thread_ execution. Safe to use anywhere
/// Ideal to remove hardcoded `DispatchQueue.main.async` from production code that makes unit testing hard
/// - Parameter completion: closure to execute within the **main's** thread
func guaranteeMainThread(_ completion: @escaping () -> Void) {
    if Thread.isMainThread {
        completion()
    } else {
        DispatchQueue.main.async(execute: completion)
    }
}
