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
class OpenAIService{
    
    /// System message to send to instruct the user
    private static let systemMessage = "You are Jarvis, a helpful voice assistant. You talk briefly and to the point. In addition to any questions, the user you serve will, at times, give you an input in the variable UserImage: {list of labels describing the objects in a real-life image}. At those times, answer the user's questions in context of that latest image. Reply as a voice assistant would and in the language that the question was asked in. Do not say you cannot do something. Instead, give it your best shot. Begin!"
    /// API endpoint to connect to OpenAI to
    private let openAI = OpenAI(apiToken: API.openAI)
    /// Agent language used for responses as a two letter code
    private let lang: String
    /// Creates a translator for use in translation
    private let translator: TranslationService
    /// Message histroy sent to agent
    private var messages = [Chat(role: .system, content: systemMessage)]
    /// `Logger` to log any issues in this class
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "OpenAIService")
    
    /// Creates a OpenAI service session with the desired agent language
    /// - Parameter lang: The language of the agent
    init(lang: String) {
        self.lang = lang
        self.translator = TranslationService(to:lang)
    }
    
    /// Sends a chat request to ChatGPT
    /// - Parameters:
    ///   - prompt: Prompt given by the user
    ///   - description: Scene description provided by the object detection algorithm
    /// - Returns: description
    func sendChat(prompt: String, description: String = "") async -> String {
        
        // Create chat request to send
        var message: String
        if (lang == "en"){
            message = description == "" ? prompt : "UserImage: \(description)\n\n\(prompt)"
        } else {
            message = description == "" ? translator.translate(prompt) : "UserImage: \(translator.translate(description) ?? "")\n\n\(translator.translate(prompt) ?? "")"
        }
        messages.append(Chat(role: .user, content: message))
        let query = ChatQuery(model: .gpt3_5Turbo, messages: self.messages)
        
        // Send request and get the returned message
        do {
            let result = try await openAI.chats(query: query)
            let chatMessage = result.choices[0].message
            messages.append(chatMessage)
            if let unwrapped = chatMessage.content {
                self.log.debug("Chat Request: \(unwrapped)")
                return unwrapped
            } else {
                self.log.debug("No Chat Response")
                return ""
            }
        } catch {
            self.log.error("Error occured while sending OpenAI chat request ")
            return ""
        }
    }
    
    /// Sends a transcription request to Whisper
    /// - Parameter data: Raw data contained in the audio file
    /// - Returns: The transcribed audio
    func sendTranscritpion(data: Data, fileName: String) async -> String {
        let query = AudioTranscriptionQuery(file: data, fileName: fileName, model: .whisper_1, language: lang)
        do {
            let result = try await openAI.audioTranscriptions(query: query)
            self.log.debug("Transcription: \(result.text)")
            return result.text
        } catch {
            self.log.error("Error occured while sending OpenAI whisper request ")
            return ""
        }
    }
}

