//
//  OnboardingView.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var errorMessage: String? = nil
    @State private var currentStep: Int = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // En-tête avec progression
                VStack(spacing: 16) {
                    // Icône AI personnalisée
                    AIIconView(size: 64, showShadow: false)
                        .padding(.top, 40)
                
                Text("Bienvenue")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Configurez AI Text Assistant en quelques étapes")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Indicateur de progression
                HStack(spacing: 8) {
                    ForEach(0..<2) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
            
            // Contenu
            ScrollView {
                VStack(spacing: 32) {
                    if currentStep == 0 {
                        apiKeyStep
                    } else {
                        permissionsStep
                    }
                }
                .padding(.horizontal, 60)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button("Précédent") {
                        withAnimation(.spring(response: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if !appState.hasCompletedOnboarding {
                    Button("Passer") {
                        completeOnboarding()
                    }
                    .keyboardShortcut(.escape)
                    .foregroundColor(.secondary)
                }
                
                Button(currentStep == 0 ? "Continuer" : "Terminer") {
                    if currentStep == 0 {
                        saveAPIKeyAndContinue()
                    } else {
                        completeOnboarding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(currentStep == 0 && !canContinue)
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
            }
            
            // Bouton de fermeture (croix) en haut à droite
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
                Spacer()
            }
        }
        .frame(width: 640, height: 560)
        .background(.regularMaterial)
        .onAppear {
            loadExistingData()
        }
    }
    
    // Étape clé API
    private var apiKeyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Clé API OpenAI")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Entrez votre clé API OpenAI pour activer les fonctionnalités d'IA")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Group {
                        if showAPIKey {
                            TextField("sk-...", text: $apiKey)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14, design: .monospaced))
                    
                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if appState.hasAPIKey {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Clé API configurée")
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    }
                }
                
                Link("Obtenir une clé API", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.3))
            )
            
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.1))
                )
            }
        }
    }
    
    // Étape permissions
    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions requises")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("AI Text Assistant a besoin d'accéder à votre texte pour fonctionner")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                permissionCard(
                    icon: "hand.raised.fill",
                    title: "Accessibilité",
                    description: "Permet de lire et modifier le texte sélectionné dans d'autres applications",
                    isGranted: appState.hasAccessibilityPermission,
                    action: {
                        if !appState.hasAccessibilityPermission {
                            PermissionManager.requestAccessibilityPermission()
                            PermissionManager.openSystemPreferences()
                        }
                    }
                )
            }
        }
    }
    
    // Carte de permission
    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        isGranted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            // Icône
            ZStack {
                Circle()
                    .fill(isGranted ? .green.opacity(0.2) : .orange.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isGranted ? .green : .orange)
            }
            
            // Contenu
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                    }
                }
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isGranted {
                Button("Activer") {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isGranted ? .green.opacity(0.3) : .orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var canContinue: Bool {
        if !apiKey.isEmpty {
            return true
        }
        return appState.hasAPIKey
    }
    
    private func loadExistingData() {
        let openAIClient = OpenAIClient()
        if let existingKey = openAIClient.getAPIKey() {
            apiKey = existingKey
        }
        appState.checkPermissions()
    }
    
    private func saveAPIKeyAndContinue() {
        errorMessage = nil
        
        if !apiKey.isEmpty {
            let success = appState.saveAPIKey(apiKey)
            if !success {
                errorMessage = "Impossible de sauvegarder la clé API"
                return
            }
        }
        
        appState.checkAPIKey()
        if !appState.hasAPIKey {
            errorMessage = Constants.apiKeyMissingError
            return
        }
        
        withAnimation(.spring(response: 0.3)) {
            currentStep = 1
        }
    }
    
    private func completeOnboarding() {
        Logger.info("Completing onboarding")
        appState.hasCompletedOnboarding = true
        appState.showOnboarding = false
        
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first(where: { $0.title == "Configuration" }) {
                window.close()
            }
        }
    }
}
