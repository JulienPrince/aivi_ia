//
//  ShortcutConfigView.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import SwiftUI
import AppKit
import Combine

class ShortcutRecorder: ObservableObject {
    @Published var shortcut: KeyboardShortcut
    @Published var isRecording: Bool = false
    @Published var currentDisplay: String = ""
    @Published var errorMessage: String? = nil
    
    private var eventMonitor: Any?
    
    init(shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
    }
    
    func startRecording() {
        guard eventMonitor == nil else { return } // Éviter les doublons
        
        isRecording = true
        currentDisplay = ""
        errorMessage = nil
        
        // Créer un monitor d'événements local
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }
            
            if !self.isRecording {
                return event
            }
            
            if event.type == .flagsChanged {
                // Affichez les touches de modification en temps réel.
                let modifiers = event.modifierFlags
                var parts: [String] = []
                
                if modifiers.contains(.command) { parts.append("⌘") }
                if modifiers.contains(.shift) { parts.append("⇧") }
                if modifiers.contains(.option) { parts.append("⌥") }
                if modifiers.contains(.control) { parts.append("⌃") }
                
                DispatchQueue.main.async { [weak self] in
                    self?.currentDisplay = parts.joined()
                }
                
                return event
            }
            
            // Pour keyDown, vérifier si c'est une combinaison valide
            let keyCode = event.keyCode
            let modifiers = event.modifierFlags
            
            // Vérifier qu'au moins une touche de modification est pressée
            guard modifiers.contains(.command) || 
                  modifiers.contains(.shift) || 
                  modifiers.contains(.option) || 
                  modifiers.contains(.control) else {
                return event
            }
            
            // Vérifier que ce n'est pas juste une touche de modification
            guard keyCode != 0x37, // Command
                  keyCode != 0x38, // Shift
                  keyCode != 0x3A, // Option
                  keyCode != 0x3B else { // Control
                return event
            }
            
            // Créer le raccourci
            let newShortcut = KeyboardShortcut(
                keyCode: keyCode,
                modifiers: modifiers.rawValue
            )
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.shortcut = newShortcut
                self.currentDisplay = ""
                self.isRecording = false
            }
            
            return nil // Consommer l'événement
        }
    }
    
    func stopRecording() {
        isRecording = false
        currentDisplay = ""
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    deinit {
        stopRecording()
    }
}

struct ShortcutConfigView: View {
    @StateObject private var recorder: ShortcutRecorder
    @State private var windowReference: NSWindow?
    
    let onSave: (KeyboardShortcut) -> Void
    let onCancel: () -> Void
    
    init(shortcut: KeyboardShortcut, onSave: @escaping (KeyboardShortcut) -> Void, onCancel: @escaping () -> Void) {
        _recorder = StateObject(wrappedValue: ShortcutRecorder(shortcut: shortcut))
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Configurer le raccourci clavier")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Appuyez sur la combinaison de touches souhaitée")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // Affichage du raccourci
                HStack {
                    Text(displayText)
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(recorder.isRecording ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.quaternary.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(recorder.isRecording ? .blue : .clear, lineWidth: 2)
                                )
                        )
                }
                
                if recorder.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .opacity(1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)
                        
                        Text("Enregistrement en cours...")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                if let error = recorder.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Réinitialiser") {
                    Logger.info("Reset button clicked")
                    recorder.stopRecording()
                    recorder.shortcut = .default
                    recorder.currentDisplay = ""
                    recorder.errorMessage = nil
                    recorder.startRecording()
                }
                .buttonStyle(.bordered)
                
                Button("Annuler") {
                    Logger.info("Cancel button clicked")
                    recorder.stopRecording()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onCancel()
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
                
                Button("Enregistrer") {
                    Logger.info("Save button clicked")
                    saveShortcut()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(recorder.isRecording)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 500, height: 300)
        .background(.regularMaterial)
        .onAppear {
            Logger.info("ShortcutConfigView appeared")
            recorder.startRecording()
        }
        .onDisappear {
            Logger.info("ShortcutConfigView disappeared")
            recorder.stopRecording()
        }
    }
    
    private var displayText: String {
        if recorder.isRecording && !recorder.currentDisplay.isEmpty {
            return recorder.currentDisplay
        }
        let text = recorder.shortcut.displayString
        return text.isEmpty ? "⌘⇧A" : text
    }
    
    private func saveShortcut() {
        Logger.info("saveShortcut called, shortcut: \(recorder.shortcut.displayString)")
        
        // Arrêter l'enregistrement d'abord
        recorder.stopRecording()
        
        // Vérifier que le raccourci est valide
        guard recorder.shortcut.modifiers != 0 else {
            Logger.warning("Invalid shortcut: no modifiers")
            recorder.errorMessage = "Veuillez inclure au moins une touche de modification (⌘, ⇧, ⌥, ou ⌃)"
            recorder.startRecording()
            return
        }
        
        Logger.info("Saving shortcut via KeyboardShortcutManager")
        if KeyboardShortcutManager.shared.saveShortcut(recorder.shortcut) {
            Logger.info("Shortcut saved successfully")
            
            // Reconfigurer le raccourci dans AppDelegate
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                Logger.info("Reloading keyboard shortcut in AppDelegate")
                appDelegate.reloadKeyboardShortcut()
            }
            
            // Appeler le callback de sauvegarde
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Logger.info("Calling onSave callback")
                onSave(recorder.shortcut)
            }
        } else {
            Logger.error("Failed to save shortcut")
            recorder.errorMessage = "Impossible de sauvegarder le raccourci"
            recorder.startRecording()
        }
    }
}
