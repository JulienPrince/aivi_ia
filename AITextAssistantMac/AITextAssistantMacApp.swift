import SwiftUI

@main
struct AITextAssistantMacApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        // Pour une app menu bar pure, on peut utiliser Settings masqué
        // ou WindowGroup masqué - les deux fonctionnent
        Settings {
            EmptyView()
        }
        .commands {
            // Retirer les commandes par défaut qui pourraient interférer
            CommandGroup(replacing: .appSettings) {}
        }
    }
}
