//
//  PromptBuilder.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Foundation
import NaturalLanguage

enum TextAction {
    case correct
    case improve
}

class PromptBuilder {
    
    // Détecter la langue du texte
    static func detectLanguage(of text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominantLanguage = recognizer.dominantLanguage {
            let languageCode = dominantLanguage.rawValue
            
            // Mapper les codes de langue vers des noms complets pour les langues courantes
            let languageMap: [String: String] = [
                "en": "English",
                "fr": "French",
                "es": "Spanish",
                "de": "German",
                "it": "Italian",
                "pt": "Portuguese",
                "ru": "Russian",
                "ja": "Japanese",
                "ko": "Korean",
                "zh": "Chinese",
                "ar": "Arabic",
                "nl": "Dutch",
                "sv": "Swedish",
                "pl": "Polish",
                "tr": "Turkish"
            ]
            
            return languageMap[languageCode] ?? languageCode.uppercased()
        }
        
        return "Unknown"
    }
    
    // Construire un prompt pour corriger le texte
    static func buildCorrectPrompt(text: String) -> String {
        let detectedLanguage = detectLanguage(of: text)
        let languageInstruction = detectedLanguage != "Unknown" ? "Le texte est en \(detectedLanguage). " : ""
        
        return """
        \(languageInstruction)Corrige les erreurs grammaticales, orthographiques et de ponctuation dans le texte suivant. 
        Préserve le sens original et le style. Réponds uniquement avec le texte corrigé dans la même langue, sans explications.
        
        Texte à corriger:
        \(text)
        """
    }
    
    // Construire un prompt pour améliorer le texte
    static func buildImprovePrompt(text: String) -> String {
        let detectedLanguage = detectLanguage(of: text)
        let languageInstruction = detectedLanguage != "Unknown" ? "Le texte est en \(detectedLanguage). " : ""
        
        return """
        \(languageInstruction)Améliore le texte suivant en le rendant plus clair, fluide et professionnel. 
        Améliore la structure, la clarté et la fluidité tout en préservant le sens original et le ton.
        Réponds uniquement avec le texte amélioré dans la même langue, sans explications.
        
        Texte à améliorer:
        \(text)
        """
    }
    
    // Construire le prompt selon l'action
    static func buildPrompt(text: String, action: TextAction) -> String {
        switch action {
        case .correct:
            return buildCorrectPrompt(text: text)
        case .improve:
            return buildImprovePrompt(text: text)
        }
    }
}
