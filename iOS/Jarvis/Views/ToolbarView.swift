//
//  ToolbarView.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/4/23.
//

import SwiftUI
import RealityKit
import os

/// The view that contains the toolbar.
struct ToolbarView: View {
    
    /// The controller that manages the services.
    @ObservedObject var controller: ServicesController
    /// The logger for this view.
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "ToolbarView")

    
    /// The body of the view.
    var body: some View {
        HStack(alignment: .center, spacing: 60) {
            Button {
                controller.showResponse = false
                controller.showSettings = true
                log.info("Opened Settings")
            } label: {
                Image(systemName: "gear.circle")
                    .imageScale(.large)
            }
            .sheet(isPresented: $controller.showSettings)  {
                SettingsView(controller: controller)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            Button {
                controller.showSettings = false
                controller.toggleRecording()
                log.info("Toggled recording")
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
            
            Button {
                controller.showResponse = true
                controller.showSettings = false
                log.info("Opened responses")
            } label: {
                if controller.status == .error {
                    Image(systemName: "exclamationmark.circle")
                        .imageScale(.large)
                } else {
                    Image(systemName: "message.circle")
                        .imageScale(.large)
                }
            }.sheet(isPresented: $controller.showResponse) {
                ResponseView(controller: controller)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            
        }
        .padding()
        .font(.system(size: 48))
        .foregroundColor(.white)
        .frame(width: UIScreen.main.bounds.width, height: 100, alignment: .center)
        .background(Color.black)
        .opacity(0.87)
    }
}

/// The preview for the view.
struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView(controller: ServicesController(UIPreviewObjectDetector()))
    }
}
