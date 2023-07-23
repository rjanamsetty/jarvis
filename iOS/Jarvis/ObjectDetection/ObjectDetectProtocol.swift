//
//  ObjectDetectProtocol.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/11/23.
//

import Foundation
import UIKit
import Vision
import ARKit
import RealityKit
import os

@objc
/// A protocol for AR object detection
protocol ObjectDetectProtocol where Self: NSObject {
    
    // MARK: - Properties
    
    /// The parent view associated with the view
    var parent: ARView { get set }
    /// The size of the raw frame captured from the camera
    var frameSize: CGSize { get set }
    /// List of objects detected in the scene
    var objects: [String] { get set }
    
    // MARK: - Protocol Methods
    
    /// Performs a vision request from the given image
    /// - Parameter cvPixelBuffer: The raw camera frame
    /// - Returns: List of objects detected in the scene
    func performVision(_ cvPixelBuffer: CVPixelBuffer) throws -> [String]
    
    /// Sets up the pipeline for the computer vision task
    func setupVision() throws
    
    /// Performs a vision request from a tap action though a coordinator
    /// - Parameter sender: Sender of this function
    @objc func tapGestureMethod(_ sender : UITapGestureRecognizer)
}

extension ObjectDetectProtocol {
    
    // MARK: - Extensions
    
    /// Gets the current orientation of the device
    /// - Returns: The orientation of the current device
    func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case .portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case .landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case .landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case .portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        
        return exifOrientation
    }
    
    /// Performs a vision request from an `ARView`
    /// - Parameter arView: ARView associated with the vision request. Defaults to `parent`
    /// - Returns: List of objects detected in the scene
    func performVision(_ arView: ARView) throws -> [String] {
        guard let currentFrame = arView.session.currentFrame else {
            throw ObjectDetectionError.noARFrameFound
        }
        frameSize = currentFrame.camera.imageResolution
        return try performVision(currentFrame.capturedImage)
    }
    
    /// Performs a vision request from an `ARView` from the parent view
    /// - Returns: List of objects detected in the scene
    func performVision() throws -> [String] {
        return try performVision(parent)
    }
    
    @discardableResult
    /// Performs a vision request from a tap action
    /// - Parameter sender: Sender of this function
    /// - Returns: List of objects detected in the scene
    func performVision(_ sender: UITapGestureRecognizer) throws -> [String] {
        guard let sceneView = sender.view as? ARView else {
            throw ObjectDetectionError.senderNotARView
        }
        return try performVision(sceneView)
    }
    
    /// Logs the `Error` and throws it
    /// - Parameter error: The `Error` to be logged
    /// - Returns: The given `Error` to be able to thrown in one line
    private func logAndThrow(_ error: Error) -> Error {
        return SystemMonitor.logAndThrow(with: error, at: "ObjectDetectProtocol")
    }
}
