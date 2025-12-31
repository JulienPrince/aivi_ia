# Guide de Portage vers Windows

Ce document présente les différentes options pour porter l'application **AI Text Assistant** vers Windows.

## 📊 Analyse des Dépendances macOS Spécifiques

Votre application utilise actuellement :

- **Cocoa/AppKit** : Interface utilisateur native macOS
- **ApplicationServices** : Raccourcis clavier globaux (CGEvent)
- **Accessibility API** : Lecture du texte sélectionné
- **Keychain Services** : Stockage sécurisé de la clé API
- **NSStatusItem** : Icône dans la barre de menu
- **NSWorkspace** : Gestion de l'application frontale

## 🎯 Options de Portage

### Option 1 : C# / .NET avec WPF ou WinUI 3 ⭐ **RECOMMANDÉE**

**Technologie :** C# + WPF (Windows Presentation Foundation) ou WinUI 3

**Avantages :**

- ✅ Performance native Windows
- ✅ Intégration native avec Windows (systray, raccourcis globaux)
- ✅ API Windows Accessible (UI Automation) pour lire le texte sélectionné
- ✅ DPAPI (Data Protection API) pour stocker la clé API de manière sécurisée
- ✅ Hotkeys globaux via `RegisterHotKey` ou `GlobalKeyboardHook`
- ✅ Interface moderne avec WinUI 3 ou Material Design avec WPF
- ✅ Bonne documentation et communauté

**Inconvénients :**

- ❌ Réécriture complète de l'UI (mais la logique métier peut être partagée)
- ❌ Nécessite Visual Studio et connaissances C#

**Équivalences Windows :**

- `NSStatusItem` → `NotifyIcon` (System Tray)
- `CGEvent` → `RegisterHotKey` ou `LowLevelKeyboardHook`
- `Accessibility API` → `UI Automation` (UIA)
- `Keychain` → `DPAPI` ou `Windows Credential Manager`
- `NSWorkspace` → `Process.GetForegroundWindow()`

**Structure proposée :**

```
AITextAssistantWindows/
├── Core/                    # Logique métier partagée (peut être en C#)
│   ├── AI/
│   │   ├── OpenAIClient.cs
│   │   └── PromptBuilder.cs
│   └── Models/
│       └── TextAction.cs
├── Windows/
│   ├── Services/
│   │   ├── SelectionService.cs      # UI Automation
│   │   ├── KeyboardService.cs       # Global hotkeys
│   │   ├── StorageService.cs         # DPAPI pour clé API
│   │   └── SystemTrayService.cs     # NotifyIcon
│   └── UI/
│       ├── MainWindow.xaml
│       ├── ActionPopup.xaml
│       ├── SettingsWindow.xaml
│       └── OnboardingWindow.xaml
└── Utils/
    └── Logger.cs
```

**Bibliothèques recommandées :**

- `Hardcodet.NotifyIcon.Wpf` pour le system tray
- `GlobalLowLevelHooks` pour les raccourcis clavier
- `System.Windows.Automation` pour UI Automation
- `Newtonsoft.Json` pour les requêtes API

---

### Option 2 : Tauri (Rust + Web Frontend)

**Technologie :** Rust (backend) + HTML/CSS/JavaScript ou framework web (React, Vue, Svelte)

**Avantages :**

- ✅ Application native légère (~5-10 MB)
- ✅ Partage du code frontend entre macOS et Windows (si vous réécrivez macOS aussi)
- ✅ Sécurité native (sandboxing)
- ✅ API système via Rust
- ✅ Performance native
- ✅ Hot reload pour le développement

**Inconvénients :**

- ❌ Courbe d'apprentissage Rust
- ❌ Nécessite de réécrire l'UI en web
- ❌ Écosystème moins mature que .NET

**Structure proposée :**

```
AITextAssistant/
├── src-tauri/
│   ├── src/
│   │   ├── main.rs
│   │   ├── commands.rs          # Commandes exposées au frontend
│   │   ├── keyboard.rs          # Raccourcis clavier
│   │   ├── selection.rs          # Lecture texte sélectionné
│   │   └── storage.rs            # Stockage sécurisé
│   └── Cargo.toml
└── src/                          # Frontend web
    ├── index.html
    ├── main.js (ou React/Vue)
    └── styles.css
```

**Bibliothèques Rust recommandées :**

- `global-hotkey` pour les raccourcis clavier
- `windows` crate pour les API Windows
- `rdev` pour la simulation de touches
- `keyring` pour le stockage sécurisé

---

### Option 3 : Electron

**Technologie :** Node.js + Chromium

**Avantages :**

- ✅ Partage du code frontend entre macOS et Windows
- ✅ Écosystème JavaScript/TypeScript riche
- ✅ Développement rapide
- ✅ Beaucoup de bibliothèques disponibles

**Inconvénients :**

- ❌ Taille importante (~100-150 MB)
- ❌ Consommation mémoire élevée
- ❌ Performance moins bonne que native
- ❌ Nécessite Node.js

**Bibliothèques recommandées :**

- `electron-globalshortcut` pour les raccourcis
- `robotjs` ou `nut-js` pour la simulation de touches
- `electron-store` pour le stockage
- `keytar` pour le stockage sécurisé

---

### Option 4 : Flutter Desktop

**Technologie :** Dart + Flutter

**Avantages :**

- ✅ Code partagé entre macOS et Windows
- ✅ UI moderne et performante
- ✅ Hot reload
- ✅ Bonne documentation

**Inconvénients :**

- ❌ Écosystème desktop moins mature
- ❌ Taille de l'application (~50-80 MB)
- ❌ Nécessite des plugins natifs pour certaines fonctionnalités

**Plugins recommandés :**

- `global_hotkey` pour les raccourcis clavier
- `system_tray` pour le system tray
- `window_manager` pour la gestion des fenêtres
- `flutter_secure_storage` pour le stockage sécurisé

---

### Option 5 : .NET MAUI (Multi-platform)

**Technologie :** C# + .NET MAUI

**Avantages :**

- ✅ Code partagé entre macOS, Windows, iOS, Android
- ✅ Native sur chaque plateforme
- ✅ Supporté par Microsoft
- ✅ Performance native

**Inconvénients :**

- ❌ Encore relativement nouveau (mais stable)
- ❌ Certaines fonctionnalités desktop peuvent nécessiter du code spécifique
- ❌ Nécessite .NET 8+

---

## 🏆 Recommandation

**Pour Windows uniquement :** **Option 1 (C# / WPF ou WinUI 3)**

**Pour multi-plateforme (macOS + Windows) :** **Option 2 (Tauri)** ou **Option 5 (.NET MAUI)**

### Pourquoi C# / WPF est recommandé pour Windows :

1. **Performance native** : Aucune surcharge d'interprétation
2. **Intégration système** : Accès complet aux API Windows
3. **Maturité** : Écosystème très mature et documenté
4. **Outils** : Visual Studio offre une excellente expérience de développement
5. **Communauté** : Grande communauté et beaucoup de ressources

## 🔧 Implémentation des Fonctionnalités Clés en Windows

### 1. Raccourci Clavier Global

**C# avec GlobalLowLevelHooks :**

```csharp
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class GlobalKeyboardHook
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook,
        LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    // Implémentation du hook...
}
```

### 2. Lecture du Texte Sélectionné

**UI Automation (C#) :**

```csharp
using System.Windows.Automation;

public class SelectionService
{
    public string GetSelectedText()
    {
        var focusedElement = AutomationElement.FocusedElement;
        var textPattern = focusedElement.GetCurrentPattern(
            TextPattern.Pattern) as TextPattern;

        if (textPattern != null)
        {
            var selection = textPattern.GetSelection();
            return string.Join("", selection.Select(r => r.GetText(-1)));
        }

        // Fallback: méthode clipboard
        return GetSelectedTextViaClipboard();
    }
}
```

### 3. Stockage Sécurisé de la Clé API

**DPAPI (C#) :**

```csharp
using System.Security.Cryptography;
using System.Text;

public class SecureStorage
{
    public static void SaveAPIKey(string apiKey)
    {
        byte[] encrypted = ProtectedData.Protect(
            Encoding.UTF8.GetBytes(apiKey),
            null,
            DataProtectionScope.CurrentUser);

        // Sauvegarder dans les settings
        Properties.Settings.Default.APIKey = Convert.ToBase64String(encrypted);
        Properties.Settings.Default.Save();
    }

    public static string GetAPIKey()
    {
        if (string.IsNullOrEmpty(Properties.Settings.Default.APIKey))
            return null;

        byte[] encrypted = Convert.FromBase64String(
            Properties.Settings.Default.APIKey);

        byte[] decrypted = ProtectedData.Unprotect(
            encrypted,
            null,
            DataProtectionScope.CurrentUser);

        return Encoding.UTF8.GetString(decrypted);
    }
}
```

### 4. System Tray (NotifyIcon)

**WPF :**

```csharp
using System.Windows.Forms;

public class SystemTrayService
{
    private NotifyIcon notifyIcon;

    public void Initialize()
    {
        notifyIcon = new NotifyIcon
        {
            Icon = Properties.Resources.AppIcon,
            Visible = true,
            Text = "AI Text Assistant"
        };

        notifyIcon.ContextMenuStrip = CreateContextMenu();
    }

    private ContextMenuStrip CreateContextMenu()
    {
        var menu = new ContextMenuStrip();
        menu.Items.Add("Corriger/Améliorer", null, OnActionClick);
        menu.Items.Add("Paramètres", null, OnSettingsClick);
        menu.Items.Add("Quitter", null, OnQuitClick);
        return menu;
    }
}
```

## 📦 Structure de Projet Recommandée (C# / WPF)

```
AITextAssistantWindows/
├── AITextAssistantWindows.sln
├── AITextAssistantWindows/
│   ├── Core/
│   │   ├── AI/
│   │   │   ├── OpenAIClient.cs
│   │   │   └── PromptBuilder.cs
│   │   ├── Models/
│   │   │   └── TextAction.cs
│   │   └── Services/
│   │       ├── ISelectionService.cs
│   │       ├── SelectionService.cs
│   │       ├── IKeyboardService.cs
│   │       ├── KeyboardService.cs
│   │       ├── IStorageService.cs
│   │       └── StorageService.cs
│   ├── Windows/
│   │   ├── Views/
│   │   │   ├── MainWindow.xaml
│   │   │   ├── ActionPopup.xaml
│   │   │   ├── SettingsWindow.xaml
│   │   │   └── OnboardingWindow.xaml
│   │   ├── ViewModels/
│   │   │   ├── MainViewModel.cs
│   │   │   └── ActionPopupViewModel.cs
│   │   └── Services/
│   │       ├── SystemTrayService.cs
│   │       └── WindowManager.cs
│   ├── Utils/
│   │   ├── Logger.cs
│   │   └── Constants.cs
│   ├── App.xaml
│   └── App.xaml.cs
└── AITextAssistantWindows.Tests/
    └── ...
```

## 🚀 Étapes de Migration

1. **Créer le projet Windows** (C# WPF ou WinUI 3)
2. **Migrer la logique métier** :
   - `OpenAIClient` → C# avec `HttpClient`
   - `PromptBuilder` → C# (logique identique)
   - `TextAction` enum → C# enum
3. **Implémenter les services Windows** :
   - `SelectionService` avec UI Automation
   - `KeyboardService` avec Global Hook
   - `StorageService` avec DPAPI
   - `SystemTrayService` avec NotifyIcon
4. **Créer les vues** :
   - Recréer l'UI en XAML (WPF) ou WinUI 3
   - Adapter le design pour Windows
5. **Tester et optimiser**

## 📚 Ressources

### C# / WPF

- [Documentation WPF](https://docs.microsoft.com/fr-fr/dotnet/desktop/wpf/)
- [UI Automation](https://docs.microsoft.com/fr-fr/dotnet/framework/ui-automation/)
- [Global Keyboard Hook](https://github.com/gmamaladze/globalmousekeyhook)

### Tauri

- [Documentation Tauri](https://tauri.app/)
- [Tauri + React](https://tauri.app/v1/guides/getting-started/setup/react)

### Electron

- [Documentation Electron](https://www.electronjs.org/)
- [Electron Forge](https://www.electronforge.io/)

## 💡 Conclusion

Pour une application Windows native performante, **C# avec WPF ou WinUI 3** est le meilleur choix. Si vous souhaitez partager du code entre macOS et Windows, considérez **Tauri** ou **.NET MAUI**.

Le code métier (OpenAI client, prompt builder) peut être facilement porté dans n'importe quelle option, car il s'agit principalement de logique métier indépendante de la plateforme.

