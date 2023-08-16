//
//  SettingsView.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 8/5/23.
//

import SwiftUI

struct SettingsView: View {
    
    var controller: ServicesController
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("About")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.black)
                .padding(.bottom, 2)
            ScrollView {
                Text("Jarvis is a audio-visual assistant for iOS. It is made using Swift and Chat GPT.")
                    .font(.body)
                    .fontWeight(.regular)
                    .padding(.bottom, 10)
                    .foregroundColor(.black)
                Spacer()
            }
            Text("Version 0.1a")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.black)
            Text("Copyright © 2023 Ritvik Janamsetty and Naman Parikh.\nAll Rights Reserved.")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            controller: ServicesController(UIPreviewObjectDetector())
        )
    }
}
