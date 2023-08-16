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
    
    private let arContainer = ARContainerView()
    private var objectDetector: ObjectDetectProtocol
    private var servicesController: ServicesController
    
    init() {
        guard let detectorUnwrapped = YOLOv8ObjectDetect(arContainer.arView) else {
            fatalError("Error Initializing object detector")
        }
        self.objectDetector = detectorUnwrapped
        self.servicesController = ServicesController(objectDetector)
    }
    
    var body: some View {
        ZStack() {
            arContainer
            VStack {
                Spacer()
                ToolbarView(controller: ServicesController( YOLOv8ObjectDetect(arContainer.arView)))
            }
        }
        .edgesIgnoringSafeArea([.top, .leading, .trailing])
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
