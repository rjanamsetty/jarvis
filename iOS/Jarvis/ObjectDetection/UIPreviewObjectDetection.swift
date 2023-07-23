//
//  UIPreviewObjectDetection.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/21/23.
//
import Foundation
import UIKit
import Vision
import ARKit
import RealityKit
import os

/// An object detector using dummy data for UI previews
class UIPreviewObjectDetector: NSObject, ObjectDetectProtocol {
    
    // MARK: - Properties
    
    /// The parent view associated with the view
    var parent: ARView
    /// The size of the raw frame captured from the camera
    var frameSize: CGSize
    /// List of objects detected in the scene
    var objects: [String]
    
    // MARK: - Initialization
    
    /// Creates a dummy object detector for UI Previews
    /// - Parameter view: `ARView` from which object detection is called
    init(parent: ARView = ARView(frame: .zero)) {
        self.parent = parent
        self.frameSize = .zero
        self.objects = []
        super.init()
    }
    
    // MARK: - Object Detection
    
    /// Performs a dummy object detection request using fake objects
    /// - Parameter cvPixelBuffer: The raw camera frame
    /// - Returns: List of randomized objects to simulate object detection
    func performVision(_ cvPixelBuffer: CVPixelBuffer) throws -> [String] {
        // In this dummy implementation, we'll randomly generate a list of objects.
        let possibleObjects = ["Cup", "Chair", "Plant", "Lamp", "Book", "Table"]
        let numberOfObjects = Int.random(in: 0..<5)
        objects = (0..<numberOfObjects).compactMap { _ in
            possibleObjects.randomElement()
        }
        return objects
    }
    
    /// Dummy implementation of `setupVision` that does nothing except fill protocol requirements
    /// - Throws: Nothing since this is a dummy implementation
    func setupVision() throws {
        // In the dummy implementation, we don't need any setup.
    }
    
    @objc
    /// Performs a dummy vision request from a tap action though a coordinator
    /// - Parameter sender: Sender of this function
    func tapGestureMethod(_ sender: UITapGestureRecognizer) {
        do {
            try performVision(sender)
        } catch {
            print("idk how you caused an error in a dummy object lol")
        }
    }
}
