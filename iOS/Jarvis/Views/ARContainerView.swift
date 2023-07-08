//
//  ARContainerView.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/4/23.
//

import SwiftUI
import RealityKit
import ARKit
import Vision
import CoreML
import os

struct ARContainerView: UIViewRepresentable {
    
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "ARViewContainer")
    let arView = ARView(frame: .zero)
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> ObjectDetectProtocol {
        return YoloObjectDetect(arView)
    }
}
