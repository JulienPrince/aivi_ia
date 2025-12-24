//
//  SettingsView.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack {
                Text("Paramètres")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Section Clé API
                    settingsSection(title: "Clé API OpenAI") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Group {
                                    if showAPIKey {
                                        TextField("sk-...", text: $apiKey)
                                    } else {
                                        SecureField("sk-...", text: $apiKey)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                                
                                Button {
                                    showAPIKey.toggle()
                                } label: {
                                    Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            HStack {
                                if appState.hasAPIKey {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 10))
                                        Text("Configurée")
                                            .font(.system(size: 11))
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Spacer()
                                
                                Button("Enregistrer") {
                                    saveAPIKey()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            
                            Link("Obtenir une clé API", destination: URL(string: "https://platform.openai.com/api-keys")!)
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Section Permissions
                    settingsSection(title: "Permissions") {
                        permissionRow(
                            title: "Accessibilité",
                            description: "Nécessaire pour lire et modifier le texte sélectionné",
                            isGranted: appState.hasAccessibilityPermission,
                            action: {
                                if !appState.hasAccessibilityPermission {
                                    PermissionManager.requestAccessibilityPermission()
                                    PermissionManager.openSystemPreferences()
                                }
                            }
                        )
                    }
                    
                    // Messages d'erreur/succès
                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 10))
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.orange.opacity(0.1))
                        )
                    }
                    
                    if let success = successMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 10))
                            Text(success)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.green.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Bouton Fermer
            Button("Fermer") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.bottom, 16)
        }
        .frame(width: 420, height: 400)
        .onAppear {
            loadExistingData()
        }
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            content()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.2))
        )
    }
    
    private func permissionRow(title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                    
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                    }
                }
                
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if !isGranted {
                Button("Activer") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private func loadExistingData() {
        let openAIClient = OpenAIClient()
        if let existingKey = openAIClient.getAPIKey() {
            apiKey = existingKey
        }
        appState.checkPermissions()
        appState.checkAPIKey()
    }
    
    private func saveAPIKey() {
        errorMessage = nil
        successMessage = nil
        
        if apiKey.isEmpty {
            errorMessage = "Veuillez entrer une clé API"
            return
        }
        
        let success = appState.saveAPIKey(apiKey)
        if success {
            appState.checkAPIKey()
            successMessage = "Clé API enregistrée avec succès"
            errorMessage = nil
        } else {
            errorMessage = "Impossible de sauvegarder la clé API"
            successMessage = nil
        }
    }
    
    private func showShortcutConfig() {
        let shortcut = KeyboardShortcutManager.shared.loadShortcut()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Configurer le raccourci clavier"
        window.center()
        window.isReleasedWhenClosed = false
        
        let hostingView = NSHostingView(rootView: ShortcutConfigView(
            shortcut: shortcut,
            onSave: { [weak window] newShortcut in
                Logger.info("Shortcut saved callback: \(newShortcut.displayString)")
                DispatchQueue.main.async {
                    window?.close()
                }
            },
            onCancel: { [weak window] in
                Logger.info("Shortcut cancel callback")
                DispatchQueue.main.async {
                    window?.close()
                }
            }
        ).environmentObject(appState))
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 300)
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

