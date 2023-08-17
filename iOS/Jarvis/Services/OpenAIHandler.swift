//
//  OpenAIService.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 6/30/23.
//

import Foundation
import OpenAI
import os

/// Service for accessing OpenAI API
actor OpenAIHandler{
    
    // MARK: - Error Handling
    
    /// Error definitons for `OpenAIHandler`
    enum OpenAIError: LocalizedError {
        case chatRequestFailed
        case transcriptionRequestFailed
        case noChatResponse
        case noAPIKey
        
        /// Error message assoicated with `OpenAIError`
        var errorDescription: String? {
            switch self {
            case .chatRequestFailed:
                return NSLocalizedString("An error occurred while sending the OpenAI chat request", comment: "")
            case .transcriptionRequestFailed:
                return NSLocalizedString("An error occurred while sending the OpenAI whisper request", comment: "")
            case .noChatResponse:
                return NSLocalizedString("No chat request was returned by the OpenAI chat request", comment: "")
            case .noAPIKey:
                return NSLocalizedString("No OpenAI API key was given in Config.xcconfig", comment: "")
            }
        }
    }
    
    // MARK: - Properties
    
    /// App Subsystem for logging
    private static let subsytem = "com.rjanamsetty.jarvis"
    /// System message to send to instruct the user
    private static let systemMessage = "You're Jarvis, a concise and helpful voice assistant. In addition to questions, the user may provide an image with labels in the variable UserImage: {list of labels describing the objects in a real-life image}. Answer questions in the context of the latest image, using the language the question was asked in. Provide your best possible response without indicating any limitations. Begin!"
    /// API endpoint to connect to OpenAI to
    private var openAI: OpenAI! = nil
    /// Agent language used for responses as a two letter code
    private let lang: String
    /// `Logger` to log any issues in this class
    private let log = Logger(subsystem: subsytem, category: "OpenAIService")
    /// Message histroy sent to agent
    var messages = [Chat(role: .system, content: systemMessage)]
    
    // MARK: - Initialization
    
    /// Creates a OpenAI service session with the desired agent language
    /// - Parameter lang: The language of the agent
    init(lang: String) {
        self.lang = lang
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else {
            log.error("Error: Info.plist not found")
            return
        }
        guard let apiKey: String = infoDictionary["OpenAPIKey"] as? String else {
            log.error("Error: OpenAPIKey not found")
            return
        }
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    // MARK: - Public Methods
    
    /// Sends a chat request to ChatGPT
    /// - Parameters:
    ///   - prompt: Prompt given by the user
    ///   - description: Scene description provided by the object detection algorithm
    /// - Returns: description
    func sendChat(prompt: String, description: String = "") async throws -> String {
        
        // Create chat request to send
        let message = description.isEmpty ? prompt : "UserImage: \(description)\n\n\(prompt)"
        messages.append(Chat(role: .user, content: message))
        let query = ChatQuery(model: .gpt3_5Turbo, messages: self.messages)
        guard let openAI = self.openAI else {
            throw logAndThrow(OpenAIError.noAPIKey)
        }
        
        // Send request and get the returned message
        var chatMessage: Chat
        do {
            let result = try await openAI.chats(query: query)
            chatMessage = result.choices[0].message
            messages.append(chatMessage)
        } catch {
            throw logAndThrow(OpenAIError.chatRequestFailed)
        }
        
        // Retrieve the chat response
        if let unwrapped = chatMessage.content {
            self.log.debug("Chat Request: \(unwrapped)")
            return unwrapped
        } else {
            throw logAndThrow(OpenAIError.noChatResponse)
        }
    }
    
    /// Sends a transcription request to Whisper
    /// - Parameter data: Raw data contained in the audio file
    /// - Returns: The transcribed audio
    func sendTranscritpion(data: Data, fileName: String) async throws -> String {
        let query = AudioTranscriptionQuery(file: data, fileName: fileName, model: .whisper_1, language: lang)
        guard let openAI = self.openAI else {
            throw logAndThrow(OpenAIError.noAPIKey)
        }
        do {
            let result = try await openAI.audioTranscriptions(query: query)
            self.log.debug("Transcription: \(result.text)")
            return result.text
        } catch {
            throw logAndThrow(OpenAIError.transcriptionRequestFailed)
        }
    }
    
    // MARK: - Private Methods
    
    /// Logs the `Error` and throws it
    /// - Parameter error: The `Error` to be logged
    /// - Returns: The given `Error` to be able to thrown in one line
    nonisolated private func logAndThrow(_ error: Error) -> Error {
        return SystemMonitor.logAndThrow(with: error, at: "OpenAIHandler")
    }
    
}

