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

final class YoloObjectDetect: NSObject, ObjectDetectProtocol{
    
    private var requests = [VNRequest]()
    let log = Logger(subsystem: "com.rjanamsetty.jarvis", category: "YoloObjectDetect")
    var parent: ARView
    var frameSize: CGSize
    
    /// Creates a coordinator for AR object detection
    /// - Parameter view: ARView from which object detection is called
    init(_ parent: ARView) {
        self.parent = parent
        self.frameSize = .zero
        super.init()
        if let error = self.setupVision() {
            fatalError(error.localizedDescription)
        }
    }
    
    @objc func tapGestureMethod(_ sender : UITapGestureRecognizer){
        onTap(sender)
    }
    
    @discardableResult
    /// Sets up a YOLO object detection model for image proccessing
    /// - Returns: NSError if the model is not found. Else nil
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
            let observations = request.results?.parseAsHighestConfidenceObservation(with: self.parent, size: self.frameSize)
            
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
    
    func performVision(cvPixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: orientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            log.error("Error: \(error.localizedDescription)")
        }
    }
    
    
}
