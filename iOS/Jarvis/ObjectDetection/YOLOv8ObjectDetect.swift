//
//  YoloObjectDetect.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/26/23.
//

import UIKit
import Foundation
import Vision
import RealityKit
import os

/// An object detector using the YOLOv8 coreML model
class YOLOv8ObjectDetect: NSObject, ObjectDetectProtocol{
    
    // MARK: - Properties
    
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
    
    // MARK: - Initialization
    
    /// Creates a YOLOv8 object detector
    /// - Parameter view: `ARView` from which object detection is called
    init?(_ parent: ARView) {
        self.parent = parent
        self.frameSize = .zero
        self.objects = []
        super.init()
        do {
            try setupVision()
        } catch{
            log.error("Error in vision setup: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    // MARK: - Public Methods
    
    /// Performs the requested computer vision tasks for the given image using YOLO object detection
    /// - Parameter cvPixelBuffer: The raw camera frame
    /// - Returns: List of objects detected in the scene
    func performVision(_ cvPixelBuffer: CVPixelBuffer) throws -> [String] {
        let orientation = exifOrientationFromDeviceOrientation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: orientation, options: [:])
        do {
            try imageRequestHandler.perform(requests)
            return objects
        } catch {
            throw logAndThrow(ObjectDetectionError.visionRequestFailed(error))
        }
    }
    
    /// Sets up the pipeline for the computer vision task using YOLO object detection
    /// - Throws: An error detailing the setup, if applicable
    func setupVision() throws {
        log.debug("Setting up vision")
        
        // Load the model URL from the library
        let filename = "yolov8s"
        let fileExtension = "mlmodelc"
        guard let modelURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            throw logAndThrow(ObjectDetectionError.modelFileMissingCoreML("\(filename).\(fileExtension)"))
        }
        
        // Set up the vision model
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            
            // Handle frame requests and throw an error if unsuccessful
            let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let self = self else { return }
                
                // Insert any non-UI updates here on the helper Queue
                self.objects = []
                let observations = request.results?.parseAsHighestConfidenceObservation(with: self.parent, size: self.frameSize)
                if let obs = observations {
                    for obj in obs {
                        self.objects.append(obj.label)
                    }
                }
                
                // Insert any UI updates on the main queue
                /*
                DispatchQueue.main.async {
                    if let obs = observations {
                        for obj in obs {
                            obj.create3DTextVisualization()
                        }
                    }
                }
                 */
            }
            
            objectRecognition.imageCropAndScaleOption = .centerCrop
            self.requests = [objectRecognition]
        } catch {
            throw logAndThrow(ObjectDetectionError.modelCreationFailedCoreML(error))
        }
        
    }
    
    /// Performs a vision request from a tap action though a coordinator
    /// - Parameter sender: Sender of this function
    @objc func tapGestureMethod(_ sender : UITapGestureRecognizer){
        do {
            try performVision(sender)
        } catch {
            log.error("Error in vision request: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Logs the `Error` and throws it
    /// - Parameter error: The `Error` to be logged
    /// - Returns: The given `Error` to be able to thrown in one line
    private func logAndThrow(_ error: Error) -> Error {
        return SystemMonitor.logAndThrow(with: error, at: "YoloObjectDetect")
    }
}
