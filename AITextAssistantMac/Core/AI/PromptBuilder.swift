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
    case translate(targetLanguage: String)
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
        Tu es un correcteur professionnel expert. \(languageInstruction)Ton rôle est de corriger UNIQUEMENT les erreurs suivantes :
        - Erreurs grammaticales (accord, conjugaison, syntaxe)
        - Erreurs orthographiques (fautes de frappe, mots mal orthographiés)
        - Erreurs de ponctuation (virgules, points, guillemets)
        - Erreurs de capitalisation
        
        IMPORTANT :
        - Préserve le sens EXACT du texte original
        - Préserve le style et le ton de l'auteur
        - NE modifie PAS la structure des phrases si elles sont correctes
        - NE reformule PAS le texte
        - Réponds UNIQUEMENT avec le texte corrigé dans la même langue
        - N'ajoute AUCUNE explication, note ou commentaire
        
        Texte à corriger:
        \(text)
        """
    }
    
    // Construire un prompt pour améliorer le texte
    static func buildImprovePrompt(text: String) -> String {
        let detectedLanguage = detectLanguage(of: text)
        let languageInstruction = detectedLanguage != "Unknown" ? "Le texte est en \(detectedLanguage). " : ""
        
        return """
        Tu es un rédacteur professionnel expert. \(languageInstruction)Ton rôle est d'améliorer la qualité du texte suivant :
        
        OBJECTIFS :
        - Améliorer la clarté et la compréhension
        - Optimiser la structure et l'organisation des idées
        - Rendre le texte plus fluide et naturel
        - Améliorer le vocabulaire (éviter les répétitions, utiliser des mots plus précis)
        - Rendre le texte plus professionnel et impactant
        
        CONTRAINTES :
        - Préserve le sens EXACT et toutes les informations du texte original
        - Préserve le ton général (formel/informel, sérieux/léger)
        - Garde la même structure globale (paragraphes, listes, etc.)
        - Réponds UNIQUEMENT avec le texte amélioré dans la même langue
        - N'ajoute AUCUNE explication, note ou commentaire
        
        Texte à améliorer:
        \(text)
        """
    }
    
    // Construire un prompt pour traduire le texte
    static func buildTranslatePrompt(text: String, targetLanguage: String) -> String {
        let detectedLanguage = detectLanguage(of: text)
        let sourceLanguageInstruction = detectedLanguage != "Unknown" ? "Le texte source est en \(detectedLanguage). " : ""
        
        return """
        Tu es un traducteur professionnel expert. \(sourceLanguageInstruction)Ton rôle est de traduire le texte suivant en \(targetLanguage).
        
        OBJECTIFS :
        - Traduire avec précision et fidélité
        - Adapter les expressions idiomatiques au contexte culturel
        - Préserver le ton, le style et l'intention de l'auteur
        - Produire un texte naturel dans la langue cible
        
        CONTRAINTES :
        - Préserve TOUTES les informations du texte original
        - Adapte la ponctuation et la typographie aux conventions de la langue cible
        - Pour les noms propres, titres, ou termes techniques : garde-les si approprié, traduis-les si nécessaire
        - Réponds UNIQUEMENT avec le texte traduit en \(targetLanguage)
        - N'ajoute AUCUNE explication, note ou commentaire
        
        Texte à traduire:
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
        case .translate(let targetLanguage):
            return buildTranslatePrompt(text: text, targetLanguage: targetLanguage)
        }
    }
}
