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
    
    /// The parent view associated with the view
    var parent: ARView { get set }
    /// The size of the raw frame captured from the camera
    var frameSize: CGSize { get set}
    /// List of objects detected in the scene
    var objects: [String] { get set}
    
    /// Performs the requested computer vision tasks for the given image
    /// - Parameter cvPixelBuffer: The raw camera frame
    /// - Returns: List of objects detected in the scene
    func performVision(_ cvPixelBuffer: CVPixelBuffer) -> [String]
    
    @discardableResult
    /// Sets up the pipeline for the computer vision task
    /// - Returns: An error detailing the setup, if applicable
    func setupVision() -> NSError?
    
    /// Performs a vision request from a tap action though a coordinator
    /// - Parameter sender: Sender of this function
    @objc func tapGestureMethod(_ sender : UITapGestureRecognizer)
    
}

extension ObjectDetectProtocol {
    
    /// Gets the current orientation of the device
    /// - Returns: The orientation of the current device
    func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    /// Performs a vision request from a ARViiew
    /// - Parameter view: ARView associated with the vision request
    /// - Returns: List of objects detected in the scene
    func performVisionFromARView(_ view: ARView) -> [String] {
        let log = Logger(subsystem: AppDelegate.subsystem, category: "ObjectDetectProtocol")
        guard let currentFrame = view.session.currentFrame else {
            log.debug("No ARFrame Found")
            return []
        }
        frameSize = currentFrame.camera.imageResolution
        return performVision(currentFrame.capturedImage)
    }
    
    @discardableResult
    /// Performs a vision request from a tap action
    /// - Parameter sender: Sender of this function
    /// - Returns: List of objects detected in the scene
    func performVisionFromTap(_ sender : UITapGestureRecognizer) -> [String] {
        let log = Logger(subsystem: AppDelegate.subsystem, category: "ObjectDetectProtocol")
        log.debug("Screen Tapped")
        guard let sceneView = sender.view as? ARView else {
            log.debug("Sender is not a AR View")
            return []
        }
        return performVisionFromARView(sceneView)
    }
    
}
