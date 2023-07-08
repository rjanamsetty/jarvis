//
//  YoloObjectDetect.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/26/23.
//

import Foundation
import UIKit
import Vision
import ARKit
import RealityKit
import os

/// Coordinator for object detection using
class YoloObjectDetect: NSObject, ObjectDetectProtocol{
    
    /// The vision requests queue
    private var requests = [VNRequest]()
    /// Logger to log within the class
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "YoloObjectDetect")
    /// The parent view associated with the view
    var parent: ARView
    /// The size of the raw frame captured from the camera
    var frameSize: CGSize
    /// List of objects detected in the scene
    var objects: [String]
    
    /// Creates a coordinator for AR object detection
    /// - Parameter view: `ARView` from which object detection is called
    init(_ parent: ARView) {
        self.parent = parent
        self.frameSize = .zero
        self.objects = []
        super.init()
        if let error = self.setupVision() {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Performs a vision request from a tap action though a coordinator
    /// - Parameter sender: Sender of this function
    @objc func tapGestureMethod(_ sender : UITapGestureRecognizer){
        performVisionFromTap(sender)
    }
    
    @discardableResult
    /// Sets up the pipeline for the computer vision task using YOLO object detection
    /// - Returns: An error detailing the setup, if applicable
    func setupVision() -> NSError? {
        
        // Set the error to throw
        let error: NSError! = nil
        log.debug("Setting up vision")
        
        // Load the model URL from the library
        guard let modelURL = Bundle.main.url(forResource: "yolov8s", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        let visionModel = try! VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        
        // Handle frame requests and throw an error if for some reason unsuccesful
        let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
            
            // Insert any non-UI updates here on the helper Queue
            self.objects = []
            let observations = request.results?.parseAsHighestConfidenceObservation(with: self.parent, size: self.frameSize)
            if let obs = observations {
                for obj in obs {
                    self.objects.append(obj.label)
                }
            }
            
            // Insert any UI updates on the main queue
            DispatchQueue.main.async(execute: {
                if let obs = observations {
                    for obj in obs {
                        obj.create3DTextVisualization()
                    }
                }
            })
        })
        objectRecognition.imageCropAndScaleOption = .centerCrop
        self.requests = [objectRecognition]
        return error
    }
    
    /// Performs the requested computer vision tasks for the given image using YOLO object detection
    /// - Parameter cvPixelBuffer: The raw camera frame
    /// - Returns: List of objects detected in the scene
    func performVision(_ cvPixelBuffer: CVPixelBuffer) -> [String] {
        let orientation = exifOrientationFromDeviceOrientation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: orientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
            return self.objects
        } catch {
            log.error("Error: \(error.localizedDescription)")
            return []
        }
    }
}
