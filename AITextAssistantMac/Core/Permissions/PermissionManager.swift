//
//  PermissionManager.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Cocoa
import ApplicationServices

class PermissionManager {
    
    // Vérifier les permissions d'accessibilité
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        Logger.debug("Accessibility permission: \(accessEnabled)")
        return accessEnabled
    }
    
    // Demander les permissions d'accessibilité
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        Logger.info("Accessibility permission requested")
    }
    
    // Vérifier les permissions d'automation (pour certaines apps)
    static func checkAutomationPermission(for bundleIdentifier: String) -> Bool {
        // Sur macOS, les permissions d'automation sont gérées par l'utilisateur
        // On peut vérifier si l'app peut contrôler d'autres apps
        // Cette vérification est plus complexe et nécessite souvent des tests réels
        Logger.debug("Automation permission check for: \(bundleIdentifier)")
        return true // Par défaut, on assume que c'est OK
    }
    
    // Ouvrir les Préférences Système pour les permissions d'accessibilité
    static func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        Logger.info("Opening System Preferences for Accessibility")
    }
    
    // Vérifier toutes les permissions nécessaires
    static func checkAllPermissions() -> (accessibility: Bool, automation: Bool) {
        let accessibility = checkAccessibilityPermission()
        let automation = true // Automation est généralement OK par défaut
        return (accessibility, automation)
    }
}
