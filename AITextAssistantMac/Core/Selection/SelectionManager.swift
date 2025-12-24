//
//  SelectionManager.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Cocoa
import ApplicationServices

class SelectionManager {

    // Récupère le texte sélectionné dans l'app active
    func getSelectedText() -> String? {
        Logger.debug("Getting selected text")
        
        // Essayer d'abord avec l'API d'accessibilité (plus fiable)
        if let text = getSelectedTextViaAccessibility() {
            Logger.info("Text retrieved via Accessibility API: \(text.prefix(50))...")
            return text
        }
        
        Logger.debug("Accessibility API failed, trying clipboard method")
        
        // Fallback: méthode clipboard
        return getSelectedTextViaClipboard()
    }
    
    // Méthode 1: Via l'API d'accessibilité (plus fiable)
    private func getSelectedTextViaAccessibility() -> String? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let pid = frontApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        // Obtenir l'élément focalisé
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            Logger.debug("No focused element found")
            return nil
        }
        
        // Obtenir le texte sélectionné
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            return text
        }
        
        // Essayer avec kAXSelectedTextRange et kAXValue
        var selectedRange: CFTypeRef?
        if AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &selectedRange) == .success {
            var value: CFTypeRef?
            if AXUIElementCopyAttributeValue(element as! AXUIElement, kAXValueAttribute as CFString, &value) == .success,
               let fullText = value as? String {
                // Extraire la sélection (simplifié - dans un vrai cas il faudrait parser la range)
                return fullText
            }
        }
        
        return nil
    }
    
    // Méthode 2: Via clipboard (fallback)
    private func getSelectedTextViaClipboard() -> String? {
        // Sauvegarder le contenu actuel du presse-papier
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        
        Logger.debug("Previous clipboard content saved")
        
        // Obtenir l'application frontale AVANT de simuler Cmd+C
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            Logger.error("No frontmost application")
            // Restaurer le contenu précédent
            if let previous = previousContent {
                pasteboard.setString(previous, forType: .string)
            }
            return nil
        }
        
        let frontAppPID = frontApp.processIdentifier
        Logger.debug("Frontmost app: \(frontApp.localizedName ?? "unknown") (PID: \(frontAppPID))")
        
        // Simuler Cmd+C pour copier la sélection
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) else {
            Logger.error("Failed to create keyboard events")
            // Restaurer le contenu précédent
            if let previous = previousContent {
                pasteboard.setString(previous, forType: .string)
            }
            return nil
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        // Post les événements
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        Logger.debug("Cmd+C simulated")
        
        // Attendre plus longtemps pour que la copie se fasse (certaines apps sont lentes)
        var attempts = 0
        var copied: String? = nil
        
        while attempts < 15 && copied == nil {
            Thread.sleep(forTimeInterval: 0.05) // 50ms entre chaque tentative
            
            // Vérifier que l'application frontale n'a pas changé
            if let currentFrontApp = NSWorkspace.shared.frontmostApplication,
               currentFrontApp.processIdentifier != frontAppPID {
                Logger.warning("Frontmost app changed during copy operation")
                // Restaurer le contenu précédent
                if let previous = previousContent {
                    pasteboard.setString(previous, forType: .string)
                }
                return nil
            }
            
            copied = pasteboard.string(forType: .string)
            if let text = copied, !text.isEmpty {
                // Vérifier que le texte copié est différent du contenu précédent
                // (pour éviter de copier l'ancien contenu du presse-papier)
                if text != previousContent {
                    break
                } else {
                    // Le texte est le même que l'ancien contenu, continuer à attendre
                    copied = nil
                }
            }
            attempts += 1
        }
        
        // Lire le texte copié
        if let copied = copied, !copied.isEmpty {
            Logger.info("Text copied successfully after \(attempts + 1) attempts: \(copied.prefix(50))...")
            return copied
        } else {
            Logger.warning("No text was copied after \(attempts + 1) attempts - nothing selected or copy failed")
            // Restaurer le contenu précédent si rien n'a été copié
            if let previous = previousContent {
                pasteboard.setString(previous, forType: .string)
            }
            return nil
        }
    }

    // Remplacer le texte sélectionné
    func replaceSelectedText(with text: String, originalApp: NSRunningApplication? = nil) {
        guard !text.isEmpty else {
            Logger.warning("Attempted to replace with empty text")
            return
        }
        
        Logger.info("Replacing selected text with: \(text.prefix(50))...")
        
        // Réactiver l'application originale si fournie
        if let originalApp = originalApp {
            Logger.debug("Reactivating original app: \(originalApp.localizedName ?? "unknown")")
            originalApp.activate(options: [.activateIgnoringOtherApps])
            // Attendre un court instant pour que l'application soit activée
            Thread.sleep(forTimeInterval: 0.15)
            
            // Vérifier que l'application est bien active
            if NSWorkspace.shared.frontmostApplication?.processIdentifier != originalApp.processIdentifier {
                Logger.warning("Failed to activate original app, retrying...")
                Thread.sleep(forTimeInterval: 0.1)
                originalApp.activate(options: [.activateIgnoringOtherApps])
            }
        } else {
            // Sinon, essayer de réactiver l'application frontale actuelle
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                Logger.debug("Reactivating current front app: \(frontApp.localizedName ?? "unknown")")
                frontApp.activate(options: [.activateIgnoringOtherApps])
                Thread.sleep(forTimeInterval: 0.15)
            } else {
                Logger.error("No frontmost application available for text replacement")
                return
            }
        }
        
        // Mettre le texte dans le presse-papier avec retry
        let pasteboard = NSPasteboard.general
        var pasteSuccess = false
        for attempt in 0..<3 {
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            // Vérifier que le texte a bien été copié
            if pasteboard.string(forType: .string) == text {
                pasteSuccess = true
                break
            }
            
            if attempt < 2 {
                Logger.warning("Failed to set clipboard content, retrying... (attempt \(attempt + 1))")
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        
        guard pasteSuccess else {
            Logger.error("Failed to set clipboard content after 3 attempts")
            return
        }
        
        Logger.debug("Text copied to clipboard, simulating Cmd+V")
        
        // Simuler Cmd+V pour coller (cela remplace le texte sélectionné dans la plupart des apps)
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true), // V key
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            Logger.error("Failed to create keyboard events for paste")
            return
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        // Post les événements avec un petit délai entre les deux
        keyDown.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.02)
        keyUp.post(tap: .cghidEventTap)
        
        Logger.info("Paste command simulated successfully")
    }
}
