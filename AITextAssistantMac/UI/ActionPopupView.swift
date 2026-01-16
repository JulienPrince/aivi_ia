//
//  ActionPopupView.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import SwiftUI

struct ActionPopupView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAction: TextAction? = nil
    @State private var originalText: String = ""
    @State private var resultText: String = ""
    @State private var errorMessage: String? = nil
    @State private var showLanguageSelector: Bool = false
    @State private var targetLanguage: String = "English"
    @State private var textHistory: [(text: String, action: String)] = []
    
    let onDismiss: () -> Void
    
    private let selectionManager = SelectionManager()
    private let openAIClient = OpenAIClient()
    
    private let availableLanguages = [
        "English", "French", "Spanish", "German", "Italian",
        "Portuguese", "Russian", "Japanese", "Korean", "Chinese",
        "Arabic", "Dutch", "Swedish", "Polish", "Turkish"
    ]
    
    var body: some View {
        ZStack {
            // Fond avec effet de flou
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if selectedAction == nil {
                    actionSelectionView
                } else if appState.isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if !resultText.isEmpty {
                    previewView
                }
            }
            .frame(width: 520, height: 420)
            .background(
                .regularMaterial
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 20,
                    bottomTrailingRadius: 20,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
        }
        .onAppear {
            loadSelectedText()
        }
    }
    
    // Vue de sélection d'action
    private var actionSelectionView: some View {
        VStack(spacing: 24) {
            // En-tête
            VStack(spacing: 12) {
                // Icône AI personnalisée (monocrome)
                AIIconView(size: 48, showShadow: false)
                
                Text("AI Text Assistant")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            if originalText.isEmpty {
                // État vide
                VStack(spacing: 16) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse)
                    
                    Text("Aucun texte sélectionné")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Sélectionnez du texte et appuyez sur ⌘⇧A")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical, 60)
            } else {
                // Texte sélectionné
                VStack(spacing: 20) {
                    // Aperçu du texte
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Texte sélectionné")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        ScrollView {
                            Text(originalText)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.quaternary.opacity(0.5))
                                )
                        }
                        .frame(height: 100)
                    }
                    
                    // Boutons d'action
                    if !showLanguageSelector {
                        VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        actionButton(
                            title: "Corriger",
                            subtitle: "Grammaire et orthographe",
                            icon: "checkmark.circle.fill",
                            color: .blue,
                            action: .correct
                        )
                        
                        actionButton(
                            title: "Améliorer",
                            subtitle: "Clarté et fluidité",
                            icon: "wand.and.stars",
                            color: .purple,
                            action: .improve
                                )
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showLanguageSelector = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)
                                        .frame(width: 18)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Traduire")
                                            .font(.system(size: 13, weight: .medium))
                                        
                                        Text("Vers une autre langue")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(originalText.isEmpty)
                        }
                    } else {
                        // Sélecteur de langue
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Langue cible")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Button("Annuler") {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showLanguageSelector = false
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            }
                            
                            Picker("Langue", selection: $targetLanguage) {
                                ForEach(availableLanguages, id: \.self) { language in
                                    Text(language).tag(language)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedAction = .translate(targetLanguage: targetLanguage)
                                    showLanguageSelector = false
                                    processAction(.translate(targetLanguage: targetLanguage))
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Traduire")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.quaternary.opacity(0.3))
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    // Bouton d'action natif macOS
    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: TextAction
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedAction = action
                processAction(action)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 18)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .disabled(originalText.isEmpty)
    }
    
    // Vue de chargement
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            VStack(spacing: 8) {
                Text("Traitement en cours")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("L'IA analyse votre texte...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Vue d'erreur
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red.gradient)
            
            VStack(spacing: 8) {
                Text("Erreur")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            HStack(spacing: 12) {
                Button("Réessayer") {
                    if let action = selectedAction {
                        processAction(action)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // Vue de prévisualisation
    private var previewView: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prévisualisation")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(actionTitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Bouton retour au texte original
                if !textHistory.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            restoreOriginalText()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 11))
                            Text("Original")
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            // Comparaison
            HStack(spacing: 16) {
                // Original (éditable)
                editableComparisonColumn(
                    title: "Original (éditable)",
                    text: $originalText,
                    color: .secondary
                )
                
                // Résultat
                comparisonColumn(
                    title: resultTitle,
                    text: resultText,
                    color: .blue
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Retour") {
                    returnToSelection()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
                
                Button(action: {
                    if let action = selectedAction {
                        processAction(action)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text("Réappliquer")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(appState.isLoading)
                
                Spacer()
                
                Button("Remplacer") {
                    confirmReplacement()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
    
    // Colonne de comparaison
    private func comparisonColumn(title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            ScrollView {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(color.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .frame(height: 220)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Colonne de comparaison éditable
    private func editableComparisonColumn(title: String, text: Binding<String>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            NoScrollTextEditor(text: text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(color.opacity(0.2), lineWidth: 1)
                        )
                )
                .frame(height: 220)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Titre de l'action
    private var actionTitle: String {
        guard let action = selectedAction else { return "" }
        switch action {
        case .correct:
            return "Correction"
        case .improve:
            return "Amélioration"
        case .translate(let targetLanguage):
            return "Traduction vers \(targetLanguage)"
        }
    }
    
    // Titre du résultat
    private var resultTitle: String {
        guard let action = selectedAction else { return "" }
        switch action {
        case .correct:
            return "Corrigé"
        case .improve:
            return "Amélioré"
        case .translate(let targetLanguage):
            return "Traduit en \(targetLanguage)"
        }
    }
    
    // Restaurer le texte original
    private func restoreOriginalText() {
        guard !textHistory.isEmpty else { return }
        
        resultText = originalText
        textHistory.removeAll()
        selectedAction = nil
        
        Logger.info("Text restored to original")
    }
    
    // Retourner à la sélection d'action
    private func returnToSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedAction = nil
            resultText = ""
            errorMessage = nil
            showLanguageSelector = false
        }
        Logger.info("Returned to action selection")
    }
    
    // Charger le texte sélectionné
    private func loadSelectedText() {
        Logger.debug("Loading selected text in ActionPopupView")
        
        // Réinitialiser l'état à chaque chargement
        selectedAction = nil
        resultText = ""
        errorMessage = nil
        textHistory = []
        showLanguageSelector = false
        
        // Utiliser le texte déjà récupéré par AppDelegate si disponible
        if let text = appState.selectedText, !text.isEmpty {
            Logger.info("Using text from AppState: \(text.prefix(50))...")
            originalText = text
            return
        }
        
        // Sinon, essayer de le récupérer maintenant
        guard let text = selectionManager.getSelectedText(), !text.isEmpty else {
            Logger.warning("No text selected in ActionPopupView")
            errorMessage = Constants.noTextSelectedError
            originalText = ""
            return
        }
        
        Logger.info("Text loaded successfully: \(text.prefix(50))...")
        originalText = text
        appState.selectedText = text
    }
    
    // Traiter l'action
    private func processAction(_ action: TextAction) {
        guard !originalText.isEmpty else {
            errorMessage = Constants.noTextSelectedError
            return
        }
        
        guard appState.hasAPIKey else {
            errorMessage = Constants.apiKeyMissingError
            return
        }
        
        appState.isLoading = true
        errorMessage = nil
        resultText = ""
        
        let prompt = PromptBuilder.buildPrompt(text: originalText, action: action)
        
        openAIClient.sendRequest(prompt: prompt, action: action) { result in
            DispatchQueue.main.async {
                appState.isLoading = false
                
                switch result {
                case .success(let text):
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        // Sauvegarder dans l'historique avant de modifier
                        if !resultText.isEmpty {
                            textHistory.append((text: resultText, action: actionTitle))
                        }
                        resultText = text
                    }
                    appState.lastResult = text
                    appState.lastActionDescription = actionTitle
                    Logger.info("Action completed successfully")
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    Logger.error("Action \(action) failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Confirmer le remplacement
    private func confirmReplacement() {
        selectionManager.replaceSelectedText(with: resultText, originalApp: appState.originalFrontApp)
        onDismiss()
        Logger.info("Text replacement confirmed")
    }
}

// Vue d'effet visuel pour le fond
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// Alias pour compatibilité
typealias AIIcon = AIIconView

// TextView personnalisé sans scrollbar visible
struct NoScrollTextEditor: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configuration du textView
        textView.font = .systemFont(ofSize: 13)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.delegate = context.coordinator
        
        // Configuration de la scrollbar (apparaît seulement si nécessaire)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true  // Se cache automatiquement si pas nécessaire
        scrollView.scrollerStyle = .overlay    // Style overlay discret
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        
        // Configuration du container
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoScrollTextEditor
        
        init(_ parent: NoScrollTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
