//
//  ObjectDetectionError.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/20/23.
//

import Foundation

/// Error definitons for classes that use the `ObjectDetectProtocol`
enum ObjectDetectionError: LocalizedError {
    case modelFileMissingCoreML(_ file: String)
    case visionRequestFailed(_ error: Error)
    case modelCreationFailedCoreML(_ error: Error)
    case noARFrameFound
    case senderNotARView
    case userDisplayFailed(_ message: String)
    
    /// Error message assoicated with `ObjectDetectionError`
    var errorDescription: String? {
        switch self {
        case .modelFileMissingCoreML (let file):
            return NSLocalizedString("The core ML model file \(file) is missing.", comment: "")
        case .visionRequestFailed(let error):
            return NSLocalizedString("Vision request failed with error: \(error.localizedDescription)", comment: "")
        case .modelCreationFailedCoreML(let error):
            return NSLocalizedString("Core ML model creation failed with error: \(error.localizedDescription)", comment: "")
        case .noARFrameFound:
            return NSLocalizedString("No ARFrame found in the current frame", comment: "")
        case .senderNotARView:
            return NSLocalizedString("The tap gesture sender is not an AR View", comment: "")
        case .userDisplayFailed(let message):
            return NSLocalizedString("User display failed with message: \(message)", comment: "")
        }
       
    }
}
