# PRD - AI Text Assistant Windows (Rust)

**Version:** 1.0  
**Date:** 2025-12-25  
**Auteur:** Julien Prince  
**Statut:** À développer

---

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Objectifs](#objectifs)
3. [Fonctionnalités](#fonctionnalités)
4. [Architecture Technique](#architecture-technique)
5. [Stack Technologique](#stack-technologique)
6. [Structure du Projet](#structure-du-projet)
7. [Plan d'Implémentation](#plan-dimplémentation)
8. [Défis Techniques](#défis-techniques)
9. [Critères de Succès](#critères-de-succès)
10. [Timeline](#timeline)

---

## 🎯 Vue d'ensemble

### Description

Port Windows natif de l'application **AI Text Assistant** développée en Swift pour macOS. Cette version Windows reprend exactement la même logique métier et les mêmes fonctionnalités, mais implémentée en Rust avec une interface native Windows.

### Contexte

L'application macOS permet de corriger et améliorer du texte sélectionné via un raccourci clavier global en utilisant l'API OpenAI. Le port Windows doit offrir la même expérience utilisateur sur Windows 10/11.

### Portée

- ✅ Application Windows native (pas de framework cross-platform)
- ✅ Reprise de la logique métier identique
- ✅ Interface utilisateur native Windows
- ✅ Même fonctionnalités que la version macOS

---

## 🎯 Objectifs

### Objectifs Principaux

1. **Fonctionnalité Parité** : Offrir exactement les mêmes fonctionnalités que la version macOS
2. **Performance Native** : Application légère et performante grâce à Rust
3. **Expérience Utilisateur** : Interface native Windows intuitive
4. **Sécurité** : Stockage sécurisé de la clé API via Windows Credential Manager

### Objectifs Secondaires

- Code Rust propre et maintenable
- Documentation complète
- Gestion d'erreurs robuste
- Logs détaillés pour le débogage

---

## 🚀 Fonctionnalités

### Fonctionnalités Core (MVP)

#### 1. Raccourci Clavier Global
- **Description** : Détecter un raccourci clavier global (Ctrl+Shift+A par défaut)
- **Comportement** : Fonctionne depuis n'importe quelle application Windows
- **Configuration** : Raccourci personnalisable dans les paramètres
- **Priorité** : 🔴 Critique

#### 2. Lecture du Texte Sélectionné
- **Description** : Récupérer le texte sélectionné dans l'application active
- **Méthodes** :
  - Primaire : UI Automation (Windows Accessibility API)
  - Fallback : Méthode clipboard (simuler Ctrl+C)
- **Priorité** : 🔴 Critique

#### 3. Remplacement du Texte
- **Description** : Remplacer le texte sélectionné par le texte corrigé/amélioré
- **Méthode** : Simuler Ctrl+V après avoir mis le texte dans le clipboard
- **Priorité** : 🔴 Critique

#### 4. Intégration OpenAI
- **Description** : Envoyer des requêtes à l'API OpenAI pour corriger/améliorer le texte
- **Modèle** : GPT-4o-mini (par défaut)
- **Actions** :
  - Correction (grammaire, orthographe)
  - Amélioration (clarté, fluidité)
- **Priorité** : 🔴 Critique

#### 5. Stockage Sécurisé de la Clé API
- **Description** : Stocker la clé API de manière sécurisée
- **Méthode** : Windows Credential Manager (équivalent Keychain macOS)
- **Priorité** : 🔴 Critique

#### 6. Interface Utilisateur
- **Description** : Fenêtre popup pour sélectionner l'action et prévisualiser
- **États** :
  - Sélection d'action (Corriger/Améliorer)
  - Chargement
  - Prévisualisation (comparaison avant/après)
  - Erreur
- **Priorité** : 🔴 Critique

#### 7. System Tray
- **Description** : Icône dans la barre des tâches Windows
- **Menu contextuel** :
  - Corriger/Améliorer
  - Paramètres
  - Quitter
- **Priorité** : 🔴 Critique

#### 8. Onboarding
- **Description** : Guide de première utilisation
- **Étapes** :
  - Demander permissions d'accessibilité
  - Configurer la clé API OpenAI
  - Expliquer le raccourci clavier
- **Priorité** : 🟡 Important

#### 9. Paramètres
- **Description** : Fenêtre de configuration
- **Options** :
  - Modifier la clé API
  - Configurer le raccourci clavier
  - Réinitialiser l'application
- **Priorité** : 🟡 Important

### Fonctionnalités Futures (Post-MVP)

- Support de plusieurs modèles OpenAI
- Historique des corrections
- Personnalisation de l'interface
- Thèmes (clair/sombre)
- Statistiques d'utilisation

---

## 🏗️ Architecture Technique

### Architecture Globale

```
┌─────────────────────────────────────────────────┐
│              Application Rust                    │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐    ┌──────────────────────┐ │
│  │   UI Layer   │    │    Business Logic     │ │
│  │  (egui/tao)  │◄───┤   (Core Services)    │ │
│  └──────────────┘    └──────────────────────┘ │
│         │                      │                │
│         │                      │                │
│  ┌──────▼──────────────────────▼────────────┐ │
│  │        Windows System APIs                │ │
│  │  - UI Automation                          │ │
│  │  - Global Keyboard Hook                   │ │
│  │  - Credential Manager                     │ │
│  │  - System Tray                            │ │
│  └────────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Modules Principaux

1. **Core** : Logique métier (OpenAI client, prompt builder)
2. **Windows Services** : Intégration avec les API Windows
3. **UI** : Interface utilisateur
4. **Storage** : Gestion du stockage sécurisé
5. **Config** : Configuration et paramètres

---

## 🛠️ Stack Technologique

### Langage
- **Rust** (édition 2021, version stable)

### Bibliothèques Principales

#### UI Framework
- **Option 1 : egui** (recommandé)
  - UI immédiate mode, simple et performante
  - Cross-platform (mais on l'utilise seulement pour Windows)
  - Pas de dépendances système lourdes
  - Documentation : https://docs.rs/egui/

- **Option 2 : iced**
  - UI déclarative inspirée d'Elm
  - Plus moderne mais plus complexe
  - Documentation : https://docs.rs/iced/

#### Fenêtres et System Tray
- **tao** : Gestion des fenêtres natives Windows
  - Création de fenêtres
  - Gestion des événements
  - Documentation : https://docs.rs/tao/

- **tray-icon** : System tray (icône dans la barre des tâches)
  - Documentation : https://docs.rs/tray-icon/

#### Raccourcis Clavier Globaux
- **global-hotkey** : Raccourcis clavier globaux
  - Documentation : https://docs.rs/global-hotkey/

#### Windows APIs
- **windows** : Bindings Rust pour les API Windows
  - UI Automation
  - Credential Manager
  - Documentation : https://docs.rs/windows/

- **windows-rs** : Alternative (plus bas niveau)
  - Documentation : https://github.com/microsoft/windows-rs

#### HTTP Client
- **reqwest** : Client HTTP asynchrone
  - Pour les requêtes OpenAI
  - Support async/await
  - Documentation : https://docs.rs/reqwest/

#### JSON
- **serde** + **serde_json** : Sérialisation/désérialisation
  - Documentation : https://docs.rs/serde/

#### Stockage Sécurisé
- **keyring** : Interface pour Windows Credential Manager
  - Documentation : https://docs.rs/keyring/

#### Logging
- **tracing** : Système de logging structuré
  - Documentation : https://docs.rs/tracing/

#### Configuration
- **config** : Gestion de la configuration
  - Documentation : https://docs.rs/config/

#### Async Runtime
- **tokio** : Runtime asynchrone
  - Documentation : https://docs.rs/tokio/

### Structure Cargo.toml

```toml
[package]
name = "ai-text-assistant-windows"
version = "1.0.0"
edition = "2021"

[dependencies]
# UI
egui = "0.24"
eframe = { version = "0.24", default-features = false, features = ["default", "glow"] }

# Windows
tao = "0.1"
tray-icon = "0.10"
windows = { version = "0.52", features = [
    "Win32_Foundation",
    "Win32_UI_Accessibility",
    "Win32_UI_Input_KeyboardAndMouse",
    "Win32_Security_Credentials",
    "Win32_System_Threading",
] }

# Hotkeys
global-hotkey = "0.4"

# HTTP
reqwest = { version = "0.11", features = ["json"] }
tokio = { version = "1", features = ["full"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Storage
keyring = "2.0"

# Logging
tracing = "0.1"
tracing-subscriber = "0.3"

# Config
config = "0.13"

# Utils
anyhow = "1.0"
thiserror = "1.0"
```

---

## 📁 Structure du Projet

```
ai-text-assistant-windows/
├── Cargo.toml
├── Cargo.lock
├── README.md
├── LICENSE
│
├── src/
│   ├── main.rs                    # Point d'entrée
│   │
│   ├── core/                      # Logique métier
│   │   ├── mod.rs
│   │   ├── ai/
│   │   │   ├── mod.rs
│   │   │   ├── openai_client.rs   # Client OpenAI
│   │   │   ├── prompt_builder.rs  # Construction des prompts
│   │   │   └── models.rs          # TextAction enum, etc.
│   │   └── errors.rs              # Erreurs personnalisées
│   │
│   ├── windows/                   # Services Windows
│   │   ├── mod.rs
│   │   ├── selection.rs           # Lecture texte sélectionné (UI Automation)
│   │   ├── keyboard.rs            # Raccourcis clavier globaux
│   │   ├── storage.rs             # Stockage sécurisé (Credential Manager)
│   │   ├── clipboard.rs           # Gestion clipboard (fallback)
│   │   └── permissions.rs         # Vérification permissions
│   │
│   ├── ui/                        # Interface utilisateur
│   │   ├── mod.rs
│   │   ├── app.rs                 # Application principale (egui)
│   │   ├── action_popup.rs        # Fenêtre popup d'action
│   │   ├── settings_window.rs     # Fenêtre paramètres
│   │   ├── onboarding_window.rs   # Fenêtre onboarding
│   │   └── components/            # Composants réutilisables
│   │       ├── mod.rs
│   │       ├── action_button.rs
│   │       └── preview_panel.rs
│   │
│   ├── config/                    # Configuration
│   │   ├── mod.rs
│   │   ├── app_config.rs          # Configuration application
│   │   └── constants.rs           # Constantes
│   │
│   ├── state/                     # État de l'application
│   │   ├── mod.rs
│   │   └── app_state.rs           # État global
│   │
│   └── utils/                     # Utilitaires
│       ├── mod.rs
│       └── logger.rs              # Configuration logging
│
├── resources/                      # Ressources
│   ├── icon.ico                   # Icône application
│   └── icon_tray.ico              # Icône system tray
│
└── tests/                          # Tests
    ├── integration/
    └── unit/
```

---

## 📝 Plan d'Implémentation

### Phase 1 : Setup et Infrastructure (Jour 1 - Matin)

#### 1.1 Initialisation du Projet
- [ ] Créer le projet Rust avec `cargo new`
- [ ] Configurer `Cargo.toml` avec toutes les dépendances
- [ ] Créer la structure de dossiers
- [ ] Configurer le logging avec `tracing`

#### 1.2 Configuration de Base
- [ ] Créer `config/constants.rs` avec les constantes
- [ ] Créer `core/errors.rs` avec les types d'erreurs
- [ ] Créer `state/app_state.rs` avec la structure d'état
- [ ] Créer `utils/logger.rs` pour la configuration des logs

**Livrable** : Projet Rust fonctionnel avec structure de base

---

### Phase 2 : Core - Logique Métier (Jour 1 - Après-midi)

#### 2.1 Modèles de Données
- [ ] Créer `core/ai/models.rs` avec `TextAction` enum
- [ ] Créer les structures de données pour les requêtes OpenAI

#### 2.2 Client OpenAI
- [ ] Implémenter `core/ai/openai_client.rs`
  - [ ] Méthode `get_api_key()` (via storage service)
  - [ ] Méthode `save_api_key()` (via storage service)
  - [ ] Méthode `send_request()` avec gestion d'erreurs
  - [ ] Parsing de la réponse JSON

#### 2.3 Prompt Builder
- [ ] Implémenter `core/ai/prompt_builder.rs`
  - [ ] Détection de langue (utiliser une lib Rust ou API)
  - [ ] `build_correct_prompt()`
  - [ ] `build_improve_prompt()`
  - [ ] `build_prompt()` avec TextAction

**Livrable** : Logique métier OpenAI fonctionnelle

---

### Phase 3 : Services Windows - Stockage (Jour 2 - Matin)

#### 3.1 Stockage Sécurisé
- [ ] Implémenter `windows/storage.rs`
  - [ ] Utiliser `keyring` pour Windows Credential Manager
  - [ ] Méthode `get_api_key() -> Option<String>`
  - [ ] Méthode `save_api_key(key: &str) -> Result<()>`
  - [ ] Méthode `delete_api_key() -> Result<()>`

#### 3.2 Configuration
- [ ] Implémenter `config/app_config.rs`
  - [ ] Charger/sauvegarder la configuration
  - [ ] Gestion du raccourci clavier (keycode + modifiers)
  - [ ] État de l'onboarding

**Livrable** : Stockage sécurisé fonctionnel

---

### Phase 4 : Services Windows - Sélection de Texte (Jour 2 - Après-midi)

#### 4.1 UI Automation
- [ ] Implémenter `windows/selection.rs`
  - [ ] Utiliser Windows UI Automation API
  - [ ] Méthode `get_selected_text() -> Option<String>`
  - [ ] Récupérer l'élément focalisé
  - [ ] Extraire le texte sélectionné

#### 4.2 Fallback Clipboard
- [ ] Implémenter méthode fallback dans `windows/selection.rs`
  - [ ] Sauvegarder le contenu actuel du clipboard
  - [ ] Simuler Ctrl+C
  - [ ] Lire le clipboard
  - [ ] Restaurer le contenu original

#### 4.3 Remplacement de Texte
- [ ] Implémenter `replace_selected_text(text: &str)`
  - [ ] Mettre le texte dans le clipboard
  - [ ] Réactiver l'application originale
  - [ ] Simuler Ctrl+V

**Livrable** : Lecture et remplacement de texte fonctionnels

---

### Phase 5 : Services Windows - Raccourcis Clavier (Jour 3 - Matin)

#### 5.1 Global Hotkey
- [ ] Implémenter `windows/keyboard.rs`
  - [ ] Utiliser `global-hotkey` crate
  - [ ] Enregistrer le raccourci (Ctrl+Shift+A par défaut)
  - [ ] Callback quand le raccourci est pressé
  - [ ] Désenregistrer proprement

#### 5.2 Gestion de l'Application Frontale
- [ ] Sauvegarder l'application frontale avant action
- [ ] Réactiver l'application après traitement

**Livrable** : Raccourci clavier global fonctionnel

---

### Phase 6 : UI - System Tray (Jour 3 - Après-midi)

#### 6.1 System Tray
- [ ] Implémenter system tray avec `tray-icon`
  - [ ] Créer l'icône dans la barre des tâches
  - [ ] Menu contextuel :
    - Corriger/Améliorer
    - Paramètres
    - Quitter
  - [ ] Gestion des clics

**Livrable** : System tray fonctionnel

---

### Phase 7 : UI - Fenêtre Popup (Jour 4 - Matin)

#### 7.1 Fenêtre Popup avec egui
- [ ] Créer `ui/action_popup.rs`
  - [ ] Fenêtre flottante (520x420)
  - [ ] État : Sélection d'action
    - Afficher le texte sélectionné
    - Boutons "Corriger" et "Améliorer"
  - [ ] État : Chargement
    - Indicateur de progression
    - Message "Traitement en cours..."
  - [ ] État : Prévisualisation
    - Comparaison avant/après (côte à côte)
    - Bouton "Remplacer"
  - [ ] État : Erreur
    - Message d'erreur
    - Bouton "Réessayer"

**Livrable** : Fenêtre popup fonctionnelle

---

### Phase 8 : UI - Paramètres et Onboarding (Jour 4 - Après-midi)

#### 8.1 Fenêtre Paramètres
- [ ] Créer `ui/settings_window.rs`
  - [ ] Champ pour modifier la clé API
  - [ ] Configuration du raccourci clavier
  - [ ] Bouton "Réinitialiser"
  - [ ] Bouton "Fermer"

#### 8.2 Fenêtre Onboarding
- [ ] Créer `ui/onboarding_window.rs`
  - [ ] Étape 1 : Explication des permissions
  - [ ] Étape 2 : Configuration de la clé API
  - [ ] Étape 3 : Explication du raccourci clavier
  - [ ] Bouton "Terminer"

**Livrable** : Fenêtres de configuration complètes

---

### Phase 9 : Intégration et Tests (Jour 5)

#### 9.1 Intégration Complète
- [ ] Connecter tous les modules
- [ ] Gérer le flux complet :
  1. Raccourci clavier pressé
  2. Récupérer le texte sélectionné
  3. Afficher la popup
  4. Envoyer la requête OpenAI
  5. Afficher la prévisualisation
  6. Remplacer le texte

#### 9.2 Gestion d'Erreurs
- [ ] Vérifier les permissions d'accessibilité
- [ ] Vérifier la présence de la clé API
- [ ] Gérer les erreurs réseau
- [ ] Afficher des messages d'erreur clairs

#### 9.3 Tests
- [ ] Tester le raccourci clavier dans différentes applications
- [ ] Tester la lecture de texte dans différents éditeurs
- [ ] Tester le remplacement de texte
- [ ] Tester les cas d'erreur

**Livrable** : Application fonctionnelle complète

---

### Phase 10 : Polish et Documentation (Jour 6)

#### 10.1 Polish
- [ ] Améliorer le design de l'UI
- [ ] Ajouter des animations/transitions
- [ ] Optimiser les performances
- [ ] Gérer les cas limites

#### 10.2 Documentation
- [ ] Documenter le code (rustdoc)
- [ ] Créer un README complet
- [ ] Ajouter des commentaires pour les parties complexes

#### 10.3 Build et Distribution
- [ ] Configurer le build release
- [ ] Créer un installer Windows (.msi ou .exe)
- [ ] Tester l'installation sur une machine propre

**Livrable** : Application prête pour distribution

---

## ⚠️ Défis Techniques

### 1. UI Automation sur Windows

**Défi** : L'API UI Automation peut être complexe et ne fonctionne pas avec toutes les applications.

**Solution** :
- Utiliser le crate `windows` pour les bindings
- Implémenter un fallback robuste avec clipboard
- Tester avec plusieurs applications (Word, Notepad, Chrome, etc.)

### 2. Raccourcis Clavier Globaux

**Défi** : Certains raccourcis peuvent être capturés par d'autres applications.

**Solution** :
- Utiliser `global-hotkey` qui gère bien les conflits
- Permettre la configuration d'un raccourci personnalisé
- Afficher un avertissement si le raccourci est déjà utilisé

### 3. Réactivation de l'Application

**Défi** : S'assurer que l'application originale est réactivée après le traitement.

**Solution** :
- Sauvegarder le handle de la fenêtre avant l'action
- Utiliser `SetForegroundWindow` pour réactiver
- Ajouter des délais si nécessaire

### 4. Gestion Async avec egui

**Défi** : egui est synchrone mais les requêtes HTTP sont asynchrones.

**Solution** :
- Utiliser un channel pour communiquer entre le thread async et egui
- Utiliser `Context::request_repaint()` pour forcer le refresh
- Gérer l'état de chargement dans `AppState`

### 5. Stockage Sécurisé

**Défi** : S'assurer que la clé API est stockée de manière sécurisée.

**Solution** :
- Utiliser `keyring` qui utilise Windows Credential Manager
- Tester que les credentials sont bien protégés
- Gérer les erreurs de stockage

---

## ✅ Critères de Succès

### Fonctionnalités
- [x] Raccourci clavier global fonctionne depuis n'importe quelle application
- [x] Texte sélectionné est correctement récupéré
- [x] Texte est correctement remplacé après correction/amélioration
- [x] Requêtes OpenAI fonctionnent correctement
- [x] Clé API est stockée de manière sécurisée
- [x] Interface utilisateur est intuitive et responsive
- [x] System tray fonctionne correctement
- [x] Onboarding guide l'utilisateur

### Performance
- [x] Application démarre en < 2 secondes
- [x] Raccourci clavier répond en < 100ms
- [x] Requête OpenAI complète en < 5 secondes (selon réseau)
- [x] Consommation mémoire < 50 MB

### Qualité
- [x] Pas de crash en conditions normales
- [x] Gestion d'erreurs robuste avec messages clairs
- [x] Code documenté et maintenable
- [x] Logs utiles pour le débogage

### Compatibilité
- [x] Fonctionne sur Windows 10 (version 1903+)
- [x] Fonctionne sur Windows 11
- [x] Compatible avec les applications principales (Word, Notepad, Chrome, etc.)

---

## 📅 Timeline

| Phase | Durée | Date Estimée |
|-------|-------|--------------|
| Phase 1 : Setup | 0.5 jour | Jour 1 (Matin) |
| Phase 2 : Core | 0.5 jour | Jour 1 (Après-midi) |
| Phase 3 : Storage | 0.5 jour | Jour 2 (Matin) |
| Phase 4 : Selection | 0.5 jour | Jour 2 (Après-midi) |
| Phase 5 : Keyboard | 0.5 jour | Jour 3 (Matin) |
| Phase 6 : System Tray | 0.5 jour | Jour 3 (Après-midi) |
| Phase 7 : Popup UI | 0.5 jour | Jour 4 (Matin) |
| Phase 8 : Settings/Onboarding | 0.5 jour | Jour 4 (Après-midi) |
| Phase 9 : Integration | 1 jour | Jour 5 |
| Phase 10 : Polish | 1 jour | Jour 6 |

**Total estimé : 5-6 jours de développement**

---

## 📚 Ressources

### Documentation Rust
- [The Rust Book](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)

### Bibliothèques
- [egui Documentation](https://docs.rs/egui/)
- [tao Documentation](https://docs.rs/tao/)
- [global-hotkey Documentation](https://docs.rs/global-hotkey/)
- [windows crate Documentation](https://docs.rs/windows/)

### Windows APIs
- [UI Automation Documentation](https://docs.microsoft.com/en-us/windows/win32/winauto/entry-uiauto-win32)
- [Windows Credential Manager](https://docs.microsoft.com/en-us/windows/win32/api/wincred/)

### Exemples de Code
- [egui Examples](https://github.com/emilk/egui/tree/master/examples)
- [tao Examples](https://github.com/tauri-apps/tao/tree/dev/examples)

---

## 📝 Notes de Développement

### Ordre de Développement Recommandé

1. **Commencer par le Core** : Implémenter d'abord la logique métier (OpenAI client) car elle est indépendante de Windows
2. **Tester isolément** : Tester chaque module indépendamment avant l'intégration
3. **UI en dernier** : L'UI peut être développée en parallèle mais intégrée en dernier

### Bonnes Pratiques

- Utiliser `Result<T, E>` pour toutes les opérations qui peuvent échouer
- Utiliser `Option<T>` pour les valeurs optionnelles
- Documenter les fonctions publiques avec `///`
- Gérer les erreurs avec `anyhow` ou `thiserror`
- Utiliser `tracing` pour les logs structurés

### Points d'Attention

- **Permissions** : Vérifier les permissions d'accessibilité au démarrage
- **Thread Safety** : Faire attention aux accès concurrents (UI thread vs async tasks)
- **Memory Leaks** : S'assurer de libérer les ressources Windows correctement
- **Error Handling** : Toujours gérer les erreurs, ne pas utiliser `unwrap()` en production

---

## 🎯 Conclusion

Ce PRD définit un plan complet pour créer un port Windows natif de l'application AI Text Assistant en Rust. Le projet est structuré en 10 phases sur 5-6 jours, avec une architecture claire et une stack technologique moderne.

L'objectif est de créer une application Windows performante et native qui offre exactement les mêmes fonctionnalités que la version macOS, en reprenant la logique métier mais avec une implémentation Windows native.

**Prêt à démarrer le développement ! 🚀**


