//
//  Response View.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 8/5/23.
//

import SwiftUI

struct ResponseView: View {
    
    /// The controller that manages the services.
    var controller: ServicesController
    /// Whether the current response or the history is showing
    @State private var showCurrent = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Response")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.black)
                .padding(.bottom, 2)
            ScrollView {
                Text(controller.response)
                    .font(.body)
                    .fontWeight(.regular)
                    .padding(.bottom, 10)
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct ResponseView_Previews: PreviewProvider {
    static var previews: some View {
        ResponseView(
            controller: ServicesController(UIPreviewObjectDetector())
        )
    }
}
