//
//  AppState.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Combine
import SwiftUI

@MainActor
class AppState: ObservableObject {
    // Permissions
    @Published var hasAccessibilityPermission: Bool = false
    @Published var hasAutomationPermission: Bool = true
    
    // Configuration API
    @Published var hasAPIKey: Bool = false
    
    // État de chargement
    @Published var isLoading: Bool = false
    
    // Texte sélectionné
    @Published var selectedText: String? = nil
    
    // Application frontale originale (pour réactiver après le remplacement)
    var originalFrontApp: NSRunningApplication? = nil
    
    // Résultat de la dernière action
    @Published var lastResult: String? = nil
    @Published var lastAction: TextAction? = nil
    
    // Onboarding
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Constants.hasCompletedOnboardingKey)
        }
    }
    
    // Popup state
    @Published var showActionPopup: Bool = false
    @Published var showOnboarding: Bool = false
    
    init() {
        // Charger l'état depuis UserDefaults
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey)
        
        // Vérifier les permissions
        checkPermissions()
        
        // Vérifier la clé API
        checkAPIKey()
    }
    
    func checkPermissions() {
        let permissions = PermissionManager.checkAllPermissions()
        hasAccessibilityPermission = permissions.accessibility
        hasAutomationPermission = permissions.automation
        Logger.debug("Permissions checked - Accessibility: \(hasAccessibilityPermission), Automation: \(hasAutomationPermission)")
    }
    
    func checkAPIKey() {
        let openAIClient = OpenAIClient()
        hasAPIKey = openAIClient.getAPIKey() != nil
        Logger.debug("API key checked - Has key: \(hasAPIKey)")
    }
    
    func saveAPIKey(_ key: String) -> Bool {
        let openAIClient = OpenAIClient()
        let success = openAIClient.saveAPIKey(key)
        if success {
            hasAPIKey = true
        }
        return success
    }
}
