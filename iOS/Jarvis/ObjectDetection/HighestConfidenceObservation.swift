//
//  HighestConfidenceObservation.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/26/23.
//

import Foundation
import Vision
import RealityKit
import ARKit
import os

/// Contains information about the highest confidence object match when performing object detection
struct HighestConfidenceObservation {
    
    // MARK: - Properties
    
    /// Raw `VNClassificationObservation` object related to this object
    private let observation: VNClassificationObservation
    /// `ARView` associated with this observation
    private let view: ARView
    /// `Logger` to log within the class
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "HighestConfidenceObservation")
    /// The font name
    private let fontName = "HelveticaNeue"
    /// Label associated with the highest confidence match
    let label: String
    /// The confidence of the match
    let confidence: Float
    /// Location of the object in the 2D frame
    let boundingBox: CGRect
    /// Center point of the detection in 2D
    let center: CGPoint
    /// Creates a raycast from the center of the bounding box to the 3D world
    let raycast: [ARRaycastResult]
    
    // MARK: - Initialization
    
    /// Contains information about the highest confidence object match when performing object detection
    /// - Parameters:
    ///   - recognizedObservation: `VNRecognizedObjectObservation` containing information about the detected object
    ///   - view: `ARView` associated with where the observation took place
    ///   - size: Size of the frame
    /// - Throws: An error if the font is missing
    init(from recognizedObservation: VNRecognizedObjectObservation, with view: ARView, size: CGSize) {
        self.view = view
        self.observation = recognizedObservation.labels[0]
        self.label = observation.identifier
        self.boundingBox = VNImageRectForNormalizedRect(recognizedObservation.boundingBox,
                                                        Int(size.width), Int(size.height))
        self.confidence = observation.confidence
        self.center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        self.raycast = view.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
    }
    
    // MARK: - Public Methods
    
    /// Creates a 3D text visualization to view the results of the object detection
    func create3DTextVisualization() {
        guard let raycastHit = raycast.first else { return }
        
        // Show all debug symbols
        log.debug("Object Name: \(label), \(confidence * 100)")
        
        // Generate the display string
        let displayText = "\(label)\n%\(confidence * 100)"
        guard let font = UIFont(name: fontName, size: 0.05) else {
            log.error("Font '\(fontName)' is missing")
            return
        }
        
        let material = SimpleMaterial(color: .randomColor, roughness: 1, isMetallic: true)
        let mesh = MeshResource.generateText(displayText,
                                             extrusionDepth: 0.001,
                                             font: font,
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

// MARK: - Extensions

extension Array where Element: VNObservation {
    
    /// Converts an array of `VNObservation` objects to `VNRecognizedObjectObservation` objects when performing object detection
    /// - Returns: An array of `VNRecognizedObjectObservation` objects
    func parseAsVNRecognizedObjectObservation() -> [VNRecognizedObjectObservation] {
        return compactMap { $0 as? VNRecognizedObjectObservation }
    }
    
    /// Converts an array of `VNObservation` objects to `HighestConfidenceObservation` objects when performing object detection
    /// - Parameters:
    ///   - parent: `ARView` for which the observation takes place in
    ///   - size: Size of the frame
    /// - Returns: An array of `HighestConfidenceObservation` objects
    func parseAsHighestConfidenceObservation(with parent: ARView, size: CGSize) -> [HighestConfidenceObservation] {
        return parseAsVNRecognizedObjectObservation().compactMap { obs in
            HighestConfidenceObservation(from: obs, with: parent, size: size)
        }
    }
}

extension UIColor {
    
    /// Generates a random color
    static var randomColor: UIColor {
        return UIColor(
            red: .random(),
            green: .random(),
            blue: .random(),
            alpha: 1.0
        )
    }
}

extension CGFloat {
    
    /// Generates a random float
    /// - Returns: Random float
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
