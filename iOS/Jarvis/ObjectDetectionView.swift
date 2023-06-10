//
//  ObjectDetector.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/9/23.
//

import Foundation
import ARKit
import RealityKit

struct ObjectDetectionView {
    var view: ARView
    var session: ARSession
    
    
    init(view: ARView) {
        self.view = view
        self.session = view.session
    }
    
}
