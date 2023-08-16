//
//  ServicesController.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/15/23.
//

import SwiftUI
import AVFoundation
import os
import RealityKit
import Foundation
import OpenAI

class ServicesController: NSObject, ObservableObject {
    
    // MARK: - Error Handling
    
    /// Error definitons for `ServicesController`
    enum ServicesControllerError: LocalizedError {
        case speechRecognizerFailed
        case noTranscription
        case objectDetectionFailed
        
        /// Error message assoicated with `ServicesControllerError`
        var errorDescription: String? {
            switch self {
            case .speechRecognizerFailed:
                return NSLocalizedString("Speech recognizer failed to initialize", comment: "")
            case .noTranscription:
                return NSLocalizedString("No transcription returned", comment: "")
            case .objectDetectionFailed:
                return NSLocalizedString("Object detection failed to initialize", comment: "")
            }
        }
    }
    
    // MARK: - Enum Definitions
    
    /// The status of the services
    enum ServicesStatus {
        case idle
        case recording
        case processing
        case error
    }
    
    // MARK: - Properties
    
    /// `Logger` to log any issues in this class
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "ServicesController")
    /// API Access for OpenAI APIs
    private let openAI = OpenAIHandler(lang: "en")
    /// Algorithim used for object detection
    private let objectDetector: ObjectDetectProtocol!
    /// Accesses speech recogniton
    private let speech: SpeechRecognizer!
    /// The transcription of the dictated speech
    private var transcription = ""
    /// Denotes whether or not there was an error in the speech recognizer
    private var recognizerError = false
    /// The status of the services
    @Published var status = ServicesStatus.idle
    /// The response given by app, whether it be by ChatGPT or otherwise
    @Published var response = ""
    /// Whether or not the settings is in view
    @Published var showSettings = false
    /// Whether or not the responses is in view
    @Published var showResponse = false
    
    // MARK: - Initialization
    
    /// Creates a controller for managing internal and external API requests
    /// - Parameter objectDetector: The alogrithm used for object detection
    init(_ objectDetector: ObjectDetectProtocol!) {
        self.objectDetector = objectDetector
        guard let _ = objectDetector else {
            self.speech = nil
            super.init()
            logError(ServicesControllerError.objectDetectionFailed)
            return
        }
        do {
            self.speech = try SpeechRecognizer()
            super.init()
        } catch {
            self.speech = nil
            super.init()
            logError(error, message: "Failed to initialize speech recognizer")
        }
        
    }
    
    // MARK: - Public Methods
    
    /// Toggles the audio recording.
    func toggleRecording() {
        if (status == .idle || status == .error) {
            status = .recording
            startRecording()
        } else if (status == .recording) {
            status = .processing
            stopRecording()
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the recording
    private func startRecording() {
        Task{
            do {
                try checkStartErrors()
                await speech.reset()
                try await speech.start()
                log.debug("Recording started")
            } catch {
                logError(error, message: "Failed to start recording")
            }
        }
    }
    
    /// Stops the recording
    private func stopRecording() {
        Task{
            do {
                transcription = await speech.reset()
                log.debug("Recording stopped")
                let description = try objectDetector.performVision().joined(separator: ", ")
                try checkStopErrors()
                response = try await openAI.sendChat(prompt: transcription, description: description)
                status = .idle
                showResponse = true
            } catch {
                logError(error, message: "Failed to process recording")
            }
        }
    }
    
    /// Logs the error and displays it to the user
    /// - Parameter error: The error to be logged and displayed
    /// - Parameter message: The acompanying message to the user in the log. Defaults to empty string
    private func logError(_ error: Error, message: String = "") {
        let combiner = message.isEmpty ? "" : ": "
        log.error("\(message)\(combiner)\(error.localizedDescription)")
        response = error.localizedDescription
        status = .error
    }
    
    /// Checks whether there are any errors while starting recording, and adjusts the error message as needed
    /// - Throws: The appropriate error if one exists
    private func checkStartErrors() throws {
        try checkCommonErrors()
        if speech == nil { throw ServicesControllerError.speechRecognizerFailed }
        if objectDetector == nil { throw ServicesControllerError.objectDetectionFailed }
    }
    
    /// Checks whether there are any errors while stopping recording, and adjusts the error message as needed
    /// - Throws: The appropriate error if one exists
    private func checkStopErrors() throws {
        try checkCommonErrors()
        if transcription.isEmpty { throw ServicesControllerError.noTranscription }
    }
    
    /// Checks whether there are any errors, and adjusts the error message as needed
    /// - Throws: The appropriate error if one exists
    private func checkCommonErrors() throws {
        
    }
}
