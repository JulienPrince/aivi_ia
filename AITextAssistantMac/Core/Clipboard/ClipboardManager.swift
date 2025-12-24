//
//  ClipboardManager.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Cocoa

class ClipboardManager {
    private var savedContent: String?
    
    // Sauvegarder le contenu actuel du presse-papier
    func saveCurrentContent() -> String? {
        let pasteboard = NSPasteboard.general
        savedContent = pasteboard.string(forType: .string)
        Logger.debug("Clipboard content saved: \(savedContent ?? "nil")")
        return savedContent
    }
    
    // Restaurer le contenu sauvegardé
    func restoreContent(_ content: String? = nil) {
        let pasteboard = NSPasteboard.general
        let contentToRestore = content ?? savedContent
        
        if let contentToRestore = contentToRestore {
            pasteboard.clearContents()
            pasteboard.setString(contentToRestore, forType: .string)
            Logger.debug("Clipboard content restored")
        } else {
            Logger.debug("No content to restore")
        }
    }
    
    // Copier du texte dans le presse-papier
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        Logger.debug("Text copied to clipboard")
    }
    
    // Obtenir le contenu actuel du presse-papier
    func getClipboardContent() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    // Vider le presse-papier
    func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        Logger.debug("Clipboard cleared")
    }
}
