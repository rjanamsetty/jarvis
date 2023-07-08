//
//  TranslationService.swift
//  Jarvis
//
//  Created by Ritvik Janamsetty on 7/1/23.
//

import Foundation
import MLKit
import os

/// Service for accessing GoogleTranslate on device API
class TranslationService{
    
    /// Language to translate from
    private var fromLang: String!
    /// Language to translate to
    private var toLang: String!
    /// Translator currently used
    private var translator: Translator!
    /// Logger to log any issues
    private let log = Logger(subsystem: AppDelegate.subsystem, category: "TranslationService")
    
    /// Initializes the translation service and dowloads the model, if necesary
    /// - Parameters:
    ///   - fromRequest: Language to translate from as a two letter code
    ///   - toRequest: Language to translate to as a two letter code
    init(from fromRequest: String = "en", to toRequest: String = "en") {
        loadTranslator(from: fromRequest, to: toRequest)
    }
    
    /// Translates the given string from the given language to the desired language
    /// - Parameter message: Message to translate
    /// - Returns: Returns the translated string. If an error occurs, then the original message is returned
    func translate(_ message: String) -> String! {
        var translated = message
        if (self.toLang != self.fromLang) {
            translator.translate(message) { translatedText, error in
                guard error == nil else {
                    self.log.error("\(error.debugDescription)")
                    return
                }
                if let unwrapped = translatedText {
                    translated = unwrapped
                    self.log.debug("Translation: \(unwrapped)")
                } else {
                    self.log.debug("No Translation Returned")
                }
            }
        }
        return translated
    }
    
    /// Loads a translator to translate between the two given languages. Discards current translator
    /// - Parameters:
    ///   - fromRequest: Language to translate from as a two letter code
    ///   - toRequest: Language to translate to as a two letter code
    func loadTranslator(from fromRequest: String, to toRequest: String){
        
        // If the language is the same, then don't do anything
        if (fromRequest == toRequest){
            return
        }
        
        // Change current languages
        self.fromLang = fromRequest
        self.toLang = toRequest
        
        // Delete existing translator for cacheing purposes
        if (translator != nil) {
            if (fromRequest != "en"){ unloadTranslator(fromLang) }
            if (toRequest != "en"){ unloadTranslator(toLang) }
        }
        
        // Create the translator for the requested languages
        let options = TranslatorOptions(sourceLanguage: TranslateLanguage(rawValue: fromRequest), targetLanguage: TranslateLanguage(rawValue: toRequest))
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: true,
            allowsBackgroundDownloading: true
        )
        translator = Translator.translator(options: options)
        translator.downloadModelIfNeeded(with: conditions) { error in
            guard error == nil else {
                self.log.error("\(error.debugDescription)")
                return
            }
            self.log.debug("Model for \(self.fromLang) to \(self.toLang) dowloaded successfully. Okay to start translating.")
        }
    }
    
    /// Unloads the translator from the given language, if language model is downloaded
    /// - Parameter language: Language model to delete
    private func unloadTranslator(_ language: String){
        let deleteModel = TranslateRemoteModel.translateRemoteModel(language: TranslateLanguage(rawValue: language))
        ModelManager.modelManager().deleteDownloadedModel(deleteModel) { error in
            guard error == nil else {
                self.log.error("\(error.debugDescription)")
                return
            }
            self.log.debug("Model for \(language) succesfully deleted.")
        }
    }
}
