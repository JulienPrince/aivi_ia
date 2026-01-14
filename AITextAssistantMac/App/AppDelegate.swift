import Cocoa
import SwiftUI
import ApplicationServices
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Référence statique pour accéder à l'instance depuis n'importe où
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var eventTap: CFMachPort?
    private var popupWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private let appState = AppState()
    private var cancellables = Set<AnyCancellable>()

    func applicationWillFinishLaunching(_ notification: Notification) {
        Logger.info("Application will finish launching")
        // Enregistrer la référence statique
        AppDelegate.shared = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.info("Application did finish launching")
        
        // NE PAS changer l'activation policy immédiatement
        // Créer le statusItem d'abord en mode normal
        setupStatusItem()
        
        // Attendre que le statusItem soit bien créé et visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            // Maintenant changer l'activation policy
            NSApp.setActivationPolicy(.accessory)
            
            // Forcer plusieurs refreshes après le changement
            self?.refreshStatusItem()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.refreshStatusItem()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshStatusItem()
            }
        }
        
        // Vérifier les permissions
        appState.checkPermissions()
        
        // Observer les changements de showOnboarding (seulement si déclenché manuellement)
        appState.$showOnboarding
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] show in
                if show && self?.onboardingWindow == nil {
                    Logger.info("showOnboarding changed to true, displaying window")
                    self?.showOnboarding()
                }
            }
            .store(in: &cancellables)
        
        // Vérifier l'onboarding
        if !appState.hasCompletedOnboarding {
            Logger.info("Onboarding not completed, showing onboarding window")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.showOnboarding()
            }
        } else {
            Logger.info("Onboarding already completed")
        }
        
        // Configurer le raccourci clavier global
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.setupGlobalKeyboardShortcut()
        }
        
        Logger.info("Application setup complete")
    }
    
    // Recharger le raccourci clavier (appelé après modification)
    func reloadKeyboardShortcut() {
        Logger.info("Reloading keyboard shortcut")
        setupGlobalKeyboardShortcut()
    }
    
    private func setupStatusItem() {
        // S'assurer qu'on ne crée pas plusieurs statusItems
        if statusItem != nil {
            Logger.warning("Status item already exists, skipping creation")
            return
        }
        
        // Créer le statusItem avec une longueur fixe pour garantir l'espace
        statusItem = NSStatusBar.system.statusItem(withLength: 28.0)
        
        guard let statusItem = statusItem, let button = statusItem.button else {
            Logger.error("Failed to create status item or button")
            return
        }
        
        // Utiliser le texte "Aivi" pour le menu bar
        if let customImage = AIIconView.createNSImage(size: 28) {
            button.image = customImage
            button.image?.isTemplate = true
        } else {
            // Fallback vers SF Symbol si la création échoue
            if let image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "AI Text Assistant") {
                image.isTemplate = true
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                if let configuredImage = image.withSymbolConfiguration(config) {
                    button.image = configuredImage
                } else {
                    button.image = image
                }
            }
        }
        button.title = ""
        button.imagePosition = .imageOnly
        button.toolTip = "AI Text Assistant"
        
        // Créer le menu avec MenuBarView (de manière asynchrone pour éviter les problèmes de layout)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let statusItem = self.statusItem else { return }
            
            let menu = NSMenu()
            let menuItem = NSMenuItem()
            let menuBarView = MenuBarView().environmentObject(self.appState)
            let hostingView = NSHostingView(rootView: menuBarView)
            
            // Forcer le calcul de la taille intrinsèque
            hostingView.layout()
            let fittingSize = hostingView.fittingSize
            
            // Calculer la hauteur exacte : 3 boutons (22px) + 2 dividers (1px) = 68px
            // Utiliser la taille calculée ou la taille minimale nécessaire
            let finalHeight = max(fittingSize.height, 68)
            hostingView.setFrameSize(NSSize(width: fittingSize.width, height: finalHeight))
            
            menuItem.view = hostingView
            menu.addItem(menuItem)
            
            statusItem.menu = menu
        }
        
        // Forcer l'affichage immédiatement
        button.needsDisplay = true
        statusItem.isVisible = true
        
        // Forcer l'activation de l'application
        NSApp.activate()
        
        // Notifier le système que la barre de menu a changé
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.apple.menuextra.battery"),
            object: nil
        )
        
        // Forcer plusieurs refreshes avec des délais différents
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem?.isVisible = true
            self?.statusItem?.button?.needsDisplay = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.statusItem?.isVisible = true
            self?.statusItem?.button?.needsDisplay = true
        }
        
        Logger.info("Status item setup complete")
    }
    
    // Fonction pour forcer le refresh de l'icône
    private func refreshStatusItem() {
        guard let statusItem = statusItem, let button = statusItem.button else {
            Logger.warning("Cannot refresh status item - not found")
            return
        }
        
        // Re-créer l'image pour forcer un refresh
        if let customImage = AIIconView.createNSImage(size: 18) {
            button.image = customImage
            button.image?.isTemplate = true
        }
        
        // Forcer plusieurs mises à jour
        button.needsDisplay = true
        statusItem.isVisible = true
        
        // Forcer l'activation pour s'assurer que l'app est active
        NSApp.activate()
        
        // Forcer un refresh du système sur le thread principal
        DispatchQueue.main.async { [weak self] in
            guard let button = self?.statusItem?.button else { return }
            button.needsDisplay = true
            self?.statusItem?.isVisible = true
            
            // Forcer un redraw complet
            if let window = button.window {
                window.display()
            }
        }
        
        Logger.info("Status item refreshed")
    }

    @objc private func sayHello() {
        let alert = NSAlert()
        alert.messageText = "Hello 👋"
        alert.informativeText = "AI Text Assistant is running"
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // Configurer le raccourci clavier global
    private func setupGlobalKeyboardShortcut() {
        // Désactiver l'ancien event tap s'il existe
        if let oldTap = eventTap {
            CGEvent.tapEnable(tap: oldTap, enable: false)
            eventTap = nil
        }
        
        // Vérifier les permissions d'accessibilité d'abord
        if !PermissionManager.checkAccessibilityPermission() {
            Logger.warning("Accessibility permission not granted - keyboard shortcut may not work")
            Logger.info("Please grant accessibility permission in System Preferences")
        }
        
        // Charger le raccourci configuré
        let shortcut = KeyboardShortcutManager.shared.loadShortcut()
        Logger.info("Setting up keyboard shortcut: \(shortcut.displayString)")
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
                
                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    let flags = event.flags
                    
                    // Charger le raccourci actuel (peut avoir changé)
                    let currentShortcut = KeyboardShortcutManager.shared.loadShortcut()
                    let expectedModifiers = NSEvent.ModifierFlags(rawValue: currentShortcut.modifiers)
                    
                    // Vérifier si le raccourci correspond
                    var matches = keyCode == currentShortcut.keyCode
                    matches = matches && flags.contains(.maskCommand) == expectedModifiers.contains(.command)
                    matches = matches && flags.contains(.maskShift) == expectedModifiers.contains(.shift)
                    matches = matches && flags.contains(.maskAlternate) == expectedModifiers.contains(.option)
                    matches = matches && flags.contains(.maskControl) == expectedModifiers.contains(.control)
                    
                    if matches {
                        Logger.debug("Keyboard shortcut detected: \(currentShortcut.displayString)")
                        
                        // CRITIQUE: Récupérer le texte dans un délai très court pour s'assurer
                        // que l'application frontale est toujours la bonne
                        // On utilise un DispatchQueue pour éviter de bloquer le callback
                        DispatchQueue.global(qos: .userInitiated).async {
                            // Attendre un court instant pour s'assurer que l'app frontale est stable
                            Thread.sleep(forTimeInterval: 0.05)
                            
                            // Sauvegarder l'application frontale originale AVANT de récupérer le texte
                            let originalFrontApp = NSWorkspace.shared.frontmostApplication
                            
                            let selectionManager = SelectionManager()
                            let selectedText = selectionManager.getSelectedText()
                            
                            DispatchQueue.main.async {
                                // Sauvegarder l'application frontale originale
                                appDelegate.appState.originalFrontApp = originalFrontApp
                                
                                // Toujours mettre à jour selectedText, même si vide (pour forcer la mise à jour)
                                if let text = selectedText, !text.isEmpty {
                                    Logger.info("Text retrieved in event tap: \(text.prefix(50))...")
                                    appDelegate.appState.selectedText = text
                                } else {
                                    Logger.warning("No text retrieved in event tap")
                                    appDelegate.appState.selectedText = nil
                                }
                                appDelegate.handleKeyboardShortcut()
                            }
                        }
                        
                        // Consommer l'événement pour éviter qu'il soit traité ailleurs
                        return nil
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            Logger.info("Global keyboard shortcut registered: \(shortcut.displayString)")
        } else {
            Logger.error("Failed to create event tap - accessibility permissions may be required")
            Logger.error("Please grant accessibility permission in System Preferences > Security & Privacy > Accessibility")
        }
    }
    
    // Gérer le raccourci clavier
    @objc func handleKeyboardShortcut() {
        Logger.info("Keyboard shortcut triggered")
        
        // Vérifier les permissions
        appState.checkPermissions()
        if !appState.hasAccessibilityPermission {
            Logger.warning("Accessibility permission missing")
            showPermissionAlert()
            return
        }
        
        // Vérifier la clé API
        appState.checkAPIKey()
        if !appState.hasAPIKey {
            Logger.warning("API key missing")
            showAPIKeyAlert()
            return
        }
        
        Logger.info("All checks passed, showing action popup")
        // Afficher le popup d'action (il vérifiera lui-même le texte sélectionné)
        showActionPopup()
    }
    
    // Afficher le popup d'action
    private func showActionPopup() {
        Logger.info("Showing action popup")
        
        // Vérifier s'il y a un popup existant
        let hadExistingPopup = popupWindow != nil
        
        // Fermer le popup existant s'il y en a un
        if hadExistingPopup {
            Logger.info("Closing existing popup before showing new one")
            closeActionPopup()
        }
        
        // Le texte devrait déjà être dans appState.selectedText si récupéré dans l'event tap
        // Sinon, essayer de le récupérer maintenant (mais ça peut échouer si l'app frontale a changé)
        if appState.selectedText == nil || appState.selectedText?.isEmpty == true {
            Logger.warning("No text in AppState, attempting to retrieve now (may fail)")
            let selectionManager = SelectionManager()
            let selectedText = selectionManager.getSelectedText()
            
            if let text = selectedText, !text.isEmpty {
                Logger.info("Text retrieved successfully: \(text.prefix(50))...")
                appState.selectedText = text
            } else {
                Logger.warning("No text retrieved - will show error in popup")
            }
        } else {
            Logger.info("Using text from AppState: \(appState.selectedText!.prefix(50))...")
        }
        
        // Attendre un court instant si on a fermé un popup, puis créer le nouveau popup
        let delay = hadExistingPopup ? 0.1 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.createAndShowPopup()
        }
    }
    
    private func createAndShowPopup() {
        let hostingView = NSHostingView(rootView: ActionPopupView(onDismiss: {
            self.closeActionPopup()
        }).environmentObject(appState))
        
        appState.showActionPopup = true
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 420)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.title = "Aivi"
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        popupWindow = window
        
        // Activer l'application APRÈS avoir récupéré le texte
        NSApp.activate()
        Logger.info("Action popup displayed")
    }
    
    // Fermer le popup d'action
    private func closeActionPopup() {
        Logger.info("Closing action popup")
        popupWindow?.close()
        popupWindow = nil
        appState.showActionPopup = false
        // Ne pas réinitialiser selectedText ici car on en a besoin pour le nouveau popup
        // Il sera mis à jour dans l'event tap callback
        Logger.debug("Action popup closed")
    }
    
    // Fermer l'onboarding
    func closeOnboarding() {
        Logger.info("Closing onboarding window")
        onboardingWindow?.close()
        onboardingWindow = nil
        appState.showOnboarding = false
    }
    
    // Afficher l'onboarding
    func showOnboarding() {
        Logger.info("showOnboarding called - hasCompletedOnboarding: \(appState.hasCompletedOnboarding), hasAPIKey: \(appState.hasAPIKey)")
        
        // Fermer la fenêtre existante si elle existe (pour forcer la réouverture)
        if onboardingWindow != nil {
            Logger.debug("Closing existing onboarding window before showing new one")
            closeOnboarding()
            // Attendre un peu pour que la fermeture soit complète
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.createOnboardingWindow()
            }
            return
        }
        
        // Créer directement la fenêtre
        createOnboardingWindow()
    }
    
    private func createOnboardingWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                Logger.error("Self is nil in createOnboardingWindow")
                return 
            }
            
            // Vérification finale
            if self.onboardingWindow != nil {
                Logger.debug("Onboarding window already exists, skipping creation")
                // Mais on peut quand même la réafficher
                self.onboardingWindow?.makeKeyAndOrderFront(nil)
                NSApp.activate()
                return
            }
            
            Logger.info("Creating onboarding window - hasCompletedOnboarding: \(self.appState.hasCompletedOnboarding)")
            let hostingView = NSHostingView(rootView: OnboardingView().environmentObject(self.appState))
            hostingView.frame = NSRect(x: 0, y: 0, width: 640, height: 560)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 560),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            window.contentView = hostingView
            window.title = "Configuration"
            window.center()
            window.makeKeyAndOrderFront(nil)
            window.isReleasedWhenClosed = false
            
            // Observer la fermeture de la fenêtre
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.onboardingWindow = nil
                    self.appState.showOnboarding = false
                    Logger.info("Onboarding window closed")
                }
            }
            
            self.onboardingWindow = window
            self.appState.showOnboarding = true
            NSApp.activate()
            Logger.info("Onboarding window displayed successfully")
        }
    }
    
    // Afficher une alerte pour les permissions
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permissions requises"
        alert.informativeText = Constants.permissionDeniedError
        alert.addButton(withTitle: "Ouvrir les Préférences")
        alert.addButton(withTitle: "Annuler")
        
        if alert.runModal() == .alertFirstButtonReturn {
            PermissionManager.openSystemPreferences()
        }
    }
    
    // Afficher une alerte pour la clé API
    private func showAPIKeyAlert() {
        let alert = NSAlert()
        alert.messageText = "Clé API manquante"
        alert.informativeText = Constants.apiKeyMissingError
        alert.addButton(withTitle: "Configurer")
        alert.addButton(withTitle: "Annuler")
        
        if alert.runModal() == .alertFirstButtonReturn {
            showOnboarding()
        }
    }
    
    // Empêcher la fermeture automatique de l'application
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
}
