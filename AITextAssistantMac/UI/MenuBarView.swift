//
//  MenuBarView.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Action principale
            Button(action: {
                Logger.info("Action triggered from menu bar")
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    DispatchQueue.main.async {
                        appDelegate.handleKeyboardShortcut()
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("Corriger/Améliorer")
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 0)
            .frame(height: 22)
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Divider()
                .frame(height: 1)

            // Paramètres
            Button(action: showSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("Paramètres")
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 0)
            .frame(height: 22)

            Divider()
                .frame(height: 1)

            // Statut (seulement si problème)
            if !appState.hasAccessibilityPermission || !appState.hasAPIKey {
                VStack(alignment: .leading, spacing: 2) {
                    if !appState.hasAccessibilityPermission {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 9))
                            Text("Permissions requises")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    if !appState.hasAPIKey {
                        HStack(spacing: 4) {
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 9))
                            Text("Clé API manquante")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 0)
                .frame(height: 22)
                
                Divider()
                    .frame(height: 1)
            }

            // Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                        .frame(width: 12)
                    Text("Quitter")
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 0)
            .frame(height: 22)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
    
    private func showSettings() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Paramètres"
        window.center()
        window.isReleasedWhenClosed = false
        
        let hostingView = NSHostingView(rootView: SettingsView(onDismiss: { [weak window] in
            DispatchQueue.main.async {
                window?.close()
            }
        }).environmentObject(appState))
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 420, height: 400)
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
    
    private func resetApplication() {
        let alert = NSAlert()
        alert.messageText = "Réinitialiser l'application"
        alert.informativeText = "Cela supprimera toutes les préférences et vous redemandera la clé API. Continuer ?"
        alert.addButton(withTitle: "Réinitialiser")
        alert.addButton(withTitle: "Annuler")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            Logger.info("Starting application reset")
            
            // Supprimer UserDefaults
            UserDefaults.standard.removeObject(forKey: Constants.hasCompletedOnboardingKey)
            UserDefaults.standard.synchronize()
            
            // Supprimer la clé API du Keychain
            KeychainManager.deleteAPIKey()
            
            // Réinitialiser l'état sur le main thread
            DispatchQueue.main.async {
                // Utiliser la référence statique au lieu de NSApplication.shared.delegate
                guard let appDelegate = AppDelegate.shared else {
                    Logger.error("AppDelegate.shared is nil, trying NSApplication.shared.delegate")
                    // Fallback vers la méthode classique
                    if let delegate = NSApplication.shared.delegate as? AppDelegate {
                        self.performReset(with: delegate)
                    } else {
                        Logger.error("AppDelegate not found via both methods")
                    }
                    return
                }
                
                self.performReset(with: appDelegate)
            }
        }
    }
    
    private func performReset(with appDelegate: AppDelegate) {
        // Fermer toutes les fenêtres d'onboarding existantes
        appDelegate.closeOnboarding()
        
        // Réinitialiser l'état AVANT d'afficher l'onboarding
        self.appState.hasCompletedOnboarding = false
        self.appState.hasAPIKey = false
        self.appState.checkAPIKey()
        
        Logger.info("State reset - hasCompletedOnboarding: \(self.appState.hasCompletedOnboarding), hasAPIKey: \(self.appState.hasAPIKey)")
        
        // Forcer l'affichage de l'onboarding après un court délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Logger.info("Force showing onboarding after reset")
            // Vérifier que l'état est bien réinitialisé
            if !self.appState.hasCompletedOnboarding {
                Logger.info("hasCompletedOnboarding is false, showing onboarding")
                appDelegate.showOnboarding()
            } else {
                Logger.warning("hasCompletedOnboarding is still true after reset, forcing show")
                // Forcer l'affichage même si l'état n'est pas correct
                appDelegate.showOnboarding()
            }
        }
        
        Logger.info("Application reset completed")
    }
}

