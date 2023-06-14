//
//  ContentView.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/9/23.
//

import SwiftUI
import RealityKit
import ARKit
import Vision
import CoreML
import os

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    
    private let log = Logger(subsystem: "com.rjanamsetty.jarvis", category: "ARViewContainer")
    var frameSize: CGSize = .zero
    let arView = ARView(frame: .zero)
       
    func makeUIView(context: Context) -> ARView {
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.tapGestureMethod(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        log.debug("App Initialized")
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> ObjectDetectCoordinator {
        return ObjectDetectCoordinator(self)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
