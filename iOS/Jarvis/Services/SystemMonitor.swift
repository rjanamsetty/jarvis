//
//  NetworkMonitor.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/17/23.
//

import Foundation
import os

class SystemMonitor {
    
    // MARK: - Static Methods
    
    static func logAndThrow(with error: Error, at category: String) -> Error {
        let log = Logger(subsystem: AppDelegate.subsystem, category: category)
        log.error("\(error.localizedDescription)")
        return error
    }
    
    
}
