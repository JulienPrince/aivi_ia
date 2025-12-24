//
//  KeyboardShortcutManager.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Cocoa
import ApplicationServices

struct KeyboardShortcut: Codable {
    var keyCode: UInt16
    var modifiers: UInt // NSEvent.ModifierFlags rawValue
    
    static let `default` = KeyboardShortcut(
        keyCode: 0x00, // A key
        modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue
    )
    
    var displayString: String {
        var parts: [String] = []
        
        let modifierFlags = NSEvent.ModifierFlags(rawValue: modifiers)
        
        if modifierFlags.contains(.command) {
            parts.append("⌘")
        }
        if modifierFlags.contains(.shift) {
            parts.append("⇧")
        }
        if modifierFlags.contains(.option) {
            parts.append("⌥")
        }
        if modifierFlags.contains(.control) {
            parts.append("⌃")
        }
        
        // Convertir keyCode en caractère
        if let keyChar = keyCodeToCharacter(keyCode) {
            parts.append(keyChar.uppercased())
        }
        
        return parts.joined()
    }
    
    private func keyCodeToCharacter(_ keyCode: UInt16) -> String? {
        // Mapping simplifié des keyCodes courants
        let mapping: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";",
            0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N", 0x2E: "M",
            0x2F: ".", 0x32: "`", 0x41: ".", 0x43: "*", 0x45: "+",
            0x47: "Clear", 0x4C: "Enter", 0x4E: "-", 0x51: "=",
            0x52: "0", 0x53: "1", 0x54: "2", 0x55: "3", 0x56: "4",
            0x57: "5", 0x58: "6", 0x59: "7", 0x5B: "8", 0x5C: "9"
        ]
        return mapping[keyCode]
    }
}

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    
    private let userDefaultsKey = "keyboardShortcut"
    
    private init() {}
    
    // Charger le raccourci depuis UserDefaults
    func loadShortcut() -> KeyboardShortcut {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) else {
            return .default
        }
        return shortcut
    }
    
    // Sauvegarder le raccourci dans UserDefaults
    func saveShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        guard let data = try? JSONEncoder().encode(shortcut) else {
            Logger.error("Failed to encode keyboard shortcut")
            return false
        }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        Logger.info("Keyboard shortcut saved: \(shortcut.displayString)")
        return true
    }
    
    // Réinitialiser au raccourci par défaut
    func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        Logger.info("Keyboard shortcut reset to default")
    }
}

