//
//  Constants.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Foundation
import AppKit

enum Constants {
    // OpenAI API
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let openAIChatEndpoint = "/chat/completions"
    static let defaultModel = "gpt-4o-mini"
    static let fallbackModel = "gpt-3.5-turbo"
    
    // Keychain
    static let keychainService = "com.prince.AITextAssistantMac"
    static let apiKeyKey = "openai_api_key"
    
    // Keyboard Shortcut
    static let defaultKeyboardShortcut = "⌘⇧A"
    static let keyboardShortcutKeyCode: UInt16 = 0x00 // A key
    static let keyboardShortcutFlags: NSEvent.ModifierFlags = [.command, .shift]
    
    // UserDefaults
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let keyboardShortcutKey = "keyboardShortcut"
    
    // Error Messages
    static let noTextSelectedError = "Aucun texte sélectionné. Veuillez sélectionner du texte avant d'utiliser cette fonctionnalité."
    static let apiKeyMissingError = "Clé API OpenAI manquante. Veuillez configurer votre clé API dans les paramètres."
    static let apiErrorGeneric = "Une erreur est survenue lors de la communication avec l'API OpenAI."
    static let permissionDeniedError = "Les permissions d'accessibilité sont requises pour cette fonctionnalité."
    
    // Timeouts
    static let apiRequestTimeout: TimeInterval = 30.0
    static let clipboardWaitTime: TimeInterval = 0.1
}
