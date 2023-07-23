//
//  ToolbarView.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/4/23.
//

import SwiftUI
import RealityKit

struct ToolbarView: View {
    @ObservedObject var controller: ServicesController
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 50) {
            Button {
                controller.toggleRecording()
                print("Tapped")
            } label: {
                if controller.status == .recording {
                    Image(systemName: "stop.circle")
                        .imageScale(.large)
                } else if controller.status == .processing {
                    ProgressView()
                        .controlSize(.large)
                } else {
                    Image(systemName: "waveform.circle")
                        .imageScale(.large)
                }
            }
        }
        .padding(.bottom, 15)
        .font(.system(size: 48))
        .foregroundColor(.white)
        .frame(width: UIScreen.main.bounds.width, height: 110, alignment: .center)
        .background(Color.black)
        .opacity(0.87)
    }
}

struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView(controller: ServicesController(UIPreviewObjectDetector()))
    }
}
