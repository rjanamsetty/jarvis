//
//  AudioRecordingService.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/4/23.
//

import SwiftUI
import AVFoundation
import os
import RealityKit

/// Service for acessing the hardware's mic
class AudioRecording: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    /// `Logger` to log any issues in this class
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "AudioRecordingService")
    /// API Access for OpenAI APIs
    private let openAI = OpenAIHandler(lang: "en")
    /// Recorder to record audio through device's mic
    private var audioRecorder: AVAudioRecorder?
    /// ARView representing the scene
    private let view: ARView
    /// Protocol used for object detection
    private let objectDetector: ObjectDetectProtocol
    /// File name of the saved recording
    let audioFilename = "recorded.m4a"
    /// Denotes whether or not the audio is recoding
    var isRecording = false
    /// Denotes whether or not the system is processing a request
    @Published var isProcessing = false
    
    // MARK: - Initialization
    
    /// Creates an `AudioRecordingService` within the given `ARView`
    /// - Parameter view: The `ARView` in which the scene takes place
    init(_ view: ARView) {
        self.view = view
        guard let detectorUnwrapped = YOLOv8ObjectDetect(view) else {
            fatalError("Error Initializing object detector")
        }
        self.objectDetector = detectorUnwrapped
    }
    
    // MARK: - Public Methods
    
    /// Toggles the audio recording.
    func toggleRecording() {
        isProcessing = true
        isRecording.toggle()
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    /// Retrieves the recorded audio data as a `Data` buffer.
    /// - Returns: The recorded audio data as a `Data` buffer, or `nil` if an error occurs.
    func getRecordedAudioData() -> Data? {
        let fileURL = audioFileURL()
        do {
            // Read the contents of the recorded audio file into a `Data` buffer
            let audioData = try Data(contentsOf: fileURL)
            return audioData
        } catch {
            log.error("Error retrieving recorded audio data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the recording
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure audio session for recording
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            // Set up audio recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            
            // Create and start audio recorder
            audioRecorder = try AVAudioRecorder(url: audioFileURL(), settings: settings)
            audioRecorder?.record()
            log.debug("Recording started")
        } catch {
            log.error("Error starting recording: \(error.localizedDescription)")
        }
        isProcessing = false
    }
    
    /// Stops the recording
    private func stopRecording() {
        
        // Stops the audio recording
        audioRecorder?.stop()
        audioRecorder = nil
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Deactivate audio session
            try audioSession.setActive(false)
            log.debug("Recording stopped")
        } catch {
            log.error("Error stopping recording: \(error.localizedDescription)")
        }
        
        // Performs all the API calls
        Task {
            var transcription: String
            if let potentialAudio = getRecordedAudioData() {
                transcription = try await openAI.sendTranscritpion(data: potentialAudio, fileName: audioFilename)
            } else {
                transcription = ""
                log.error("Transcription not available")
            }
            let description = try objectDetector.performVision(view).joined(separator: ", ")
            if (transcription != ""){
                let response = try await openAI.sendChat(prompt: transcription, description: description)
                log.debug("SUCCESS: \(response)")
            }
            isProcessing = false
        }
        
    }
    
    /// Gets the `URL` for the save location for the file
    /// - Returns: `URL` of file save location
    private func audioFileURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(audioFilename)
    }
}
