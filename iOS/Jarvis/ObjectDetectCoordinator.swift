//
//  ObjectDetectService.swift
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
final class ObjectDetectCoordinator : NSObject {

    private var requests = [VNRequest]()
    private var parent: ARViewContainer
    private let log = Logger(subsystem: "com.rjanamsetty.jarvis", category: "ObjectDetectController")
    
    /// Creates a coordinator for AR object detection
    /// - Parameter view: ARView from which object detection is called
    init(_ parent: ARViewContainer) {
        self.parent = parent
        super.init()
        if let error = self.setupVision() {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Defines the action to perfom on a tap of the screen
    /// - Parameter sender: Sender of this function
    @objc func tapGestureMethod(_ sender : UITapGestureRecognizer){
        
        // Dynamically get view and frame from the gesture
        log.debug("Screen Tapped")
        guard let sceneView = sender.view as? ARView else { return }
        guard let currentFrame = sceneView.session.currentFrame else { return }
        let exifOrientation = exifOrientationFromDeviceOrientation()
        parent.frameSize = currentFrame.camera.imageResolution
        
        // Perform the desired vision requests
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            log.error("Error: \(error.localizedDescription)")
        }
    }
    
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
    
    @discardableResult
    /// Sets up a YOLO object detection model for image proccessing
    /// - Returns: NSError if the model is not found. Else nil
    func setupVision() -> NSError? {
        
        // Set the error to throw
        let error: NSError! = nil
        log.debug("Setting up vision")
        
        // Load the model URL from the library
        guard let modelURL = Bundle.main.url(forResource: "YOLOv3FP16", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        let visionModel = try! VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        
        // Handle frame requests and throw an error if for some reason unsuccesful
        let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
            
            // Insert any non-UI updates here on the helper Queue
            let observations = request.results?.parseAsHighestConfidenceObservation(self.parent)
            
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
}

/// Contains infromation about the highest confidence object match when performing object detection
struct HighestConfidenceObservation {
    private let observation: VNClassificationObservation
    private let view: ARView
    private var container: ARViewContainer
    private let log = Logger(subsystem: "com.rjanamsetty.jarvis", category: "HighestConfidenceObservation")
    
    ///  Label associated with the highest confidence match
    let label: String
    
    /// The confidence of the match
    let confidence: Float
    
    /// Location of the object in the 2D frame
    let boundingBox: CGRect
    
    /// Center point of the detection in 2D
    let center: CGPoint
    
    /// Creates a raycast from the center of the bounding box to the 3D world
    let raycast: [ARRaycastResult]
    
    /// Contains infromation about the highest confidence object match when performing object detection
    /// - Parameters:
    ///   - recognizedObservation: VNRecognizedObjectObservation containing information about the detected object
    ///   - view: ARView associated with where the observation took place
    init(from recognizedObservation: VNRecognizedObjectObservation, with container: ARViewContainer){
        self.container = container
        self.view = container.arView
        self.observation = recognizedObservation.labels[0]
        self.label = observation.identifier
        self.boundingBox = VNImageRectForNormalizedRect(recognizedObservation.boundingBox,
                                                        Int(container.frameSize.width),
                                                        Int(container.frameSize.height))
        self.confidence = observation.confidence
        self.center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        self.raycast = view.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
    }
    
    /// Creates a 3D text visualization to view the results of the object detection
    func create3DTextVisualization(){
        
        // Choose the closest raycast hit and add it to the visualization
        guard let raycastHit = raycast.first else { return }
        
        // Show all debug symbols
        log.debug("Object Name: \(label), \(confidence * 100)")
        log.debug("Center: \(center.debugDescription)")
        log.debug("Bounding Box: \(boundingBox.debugDescription)")
        log.debug("Raycast: \(raycastHit.debugDescription)")
        
        // Generate the display string
        let displayText = "\(label)\n%\(confidence * 100)"
        let material = SimpleMaterial(color: .randomColor, roughness: 1, isMetallic: true)
        let mesh = MeshResource.generateText(displayText,
                                             extrusionDepth: 0.001,
                                             font: UIFont(name: "Helvetica Neue", size: 0.05)!,
                                             containerFrame: CGRect.zero,
                                             alignment: .center,
                                             lineBreakMode: .byCharWrapping)
        
        // Add model display to the scene
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        let anchorEntity = AnchorEntity(world: SIMD3<Float>(raycastHit.worldTransform.columns.3.x,
                                                            raycastHit.worldTransform.columns.3.y,
                                                            raycastHit.worldTransform.columns.3.z))
        anchorEntity.addChild(modelEntity)
        view.scene.addAnchor(anchorEntity)
    }
    
}


extension Array where Element: VNObservation {
    
    /// Converts an array of VNObservation objects as VNRecognizedObjectObservation objects when performing object detection
    /// - Returns: An array of VNRecognizedObjectObservation objects
    func parseAsVNRecognizedObjectObservation() -> [VNRecognizedObjectObservation] {
        return self.compactMap { $0 as? VNRecognizedObjectObservation }
    }
    
    /// Converts an array of VNObservation objects as HighestConfidenceObservation objects when performing object detection
    /// - Parameter view: ARViewContainer for which the observation takes place in
    /// - Returns: An array of HighestConfidenceObservation object
    func parseAsHighestConfidenceObservation(_ parent: ARViewContainer) -> [HighestConfidenceObservation] {
        return self.parseAsVNRecognizedObjectObservation().compactMap { obs in HighestConfidenceObservation(from: obs, with: parent)}
    }
    
}

extension UIColor {
    static var randomColor : UIColor{
        return UIColor(
            red:   .random(),
            green: .random(),
            blue:  .random(),
            alpha: 1.0
        )
    }
}
extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
