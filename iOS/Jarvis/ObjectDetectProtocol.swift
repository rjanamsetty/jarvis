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


/// A coordinator for AR object detection
@objc
protocol ObjectDetectProtocol where Self: NSObject {
    
    ///  The parent view associated with the view
    var parent: ARView { get set }
    var frameSize: CGSize { get set}
    
    /// Performs the requested computer vision tasks for the given image
    /// - Parameters:
    ///   - cvPixelBuffer: The raw camera frame
    ///   - orientation: Orientation of the phone
    func performVision(cvPixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation)
    
    @discardableResult
    /// Sets up the pipeline for the computer vision task
    /// - Returns: An error detailing the setup, if applicable
    func setupVision() -> NSError?
    
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
    
    /// Defines the action to perfom on a tap of the screen
    /// - Parameter sender: Sender of this function
    func onTap(_ sender : UITapGestureRecognizer){
        
        // Dynamically get view and frame from the gesture
        let log = Logger(subsystem: "com.rjanamsetty.jarvis", category: "ObjectDetectProtocol")
        log.debug("Screen Tapped")
        guard let sceneView = sender.view as? ARView else { return }
        guard let currentFrame = sceneView.session.currentFrame else { return }
        frameSize = currentFrame.camera.imageResolution
        
        // Get orientation and perform vision
        let exifOrientation = exifOrientationFromDeviceOrientation()
        performVision(cvPixelBuffer: currentFrame.capturedImage, orientation: exifOrientation)
    }
    
}
