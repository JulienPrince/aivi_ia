# AI Text Assistant Mac

Une application macOS native qui utilise l'intelligence artificielle pour corriger et améliorer votre texte directement depuis n'importe quelle application.

## 🎯 Fonctionnalités

- **Correction automatique** : Corrige la grammaire et l'orthographe de votre texte sélectionné
- **Amélioration du texte** : Améliore la clarté et la fluidité de votre écriture
- **Raccourci clavier global** : Utilisez `⌘⇧A` (configurable) depuis n'importe quelle application
- **Prévisualisation** : Visualisez les modifications avant de les appliquer
- **Application menu bar** : Fonctionne discrètement depuis la barre de menu
- **Sécurisé** : Votre clé API est stockée de manière sécurisée dans le Keychain macOS

## 📋 Prérequis

- macOS 13.0 (Ventura) ou supérieur
- Une clé API OpenAI valide
- Permissions d'accessibilité (requises pour lire et modifier le texte sélectionné)

## 🚀 Installation

1. Clonez ce dépôt :

```bash
git clone https://github.com/votre-username/Aivi_ia.git
cd Aivi_ia
```

2. Ouvrez le projet dans Xcode :

```bash
open AITextAssistantMac.xcodeproj
```

3. Compilez et exécutez le projet depuis Xcode (⌘R)

## ⚙️ Configuration

### Première utilisation

Lors du premier lancement, l'application vous guidera à travers un processus d'onboarding :

1. **Permissions d'accessibilité** : L'application vous demandera d'accorder les permissions d'accessibilité dans les Réglages Système. Ces permissions sont nécessaires pour :

   - Lire le texte que vous sélectionnez
   - Remplacer le texte sélectionné par le texte corrigé/amélioré

2. **Clé API OpenAI** : Vous devrez entrer votre clé API OpenAI. Cette clé est stockée de manière sécurisée dans le Keychain macOS.

### Accéder aux paramètres

- Cliquez sur l'icône de l'application dans la barre de menu
- Sélectionnez "Paramètres"

Dans les paramètres, vous pouvez :

- Modifier votre clé API OpenAI
- Configurer le raccourci clavier personnalisé
- Réinitialiser l'application

## 🎮 Utilisation

1. **Sélectionnez du texte** dans n'importe quelle application (éditeur de texte, navigateur, email, etc.)

2. **Appuyez sur `⌘⇧A`** (ou votre raccourci personnalisé)

3. **Choisissez une action** :

   - **Corriger** : Corrige la grammaire et l'orthographe
   - **Améliorer** : Améliore la clarté et la fluidité du texte

4. **Prévisualisez** le résultat dans la fenêtre popup

5. **Cliquez sur "Remplacer"** pour appliquer les modifications

## 🏗️ Architecture

Le projet est organisé en plusieurs modules :

```
AITextAssistantMac/
├── App/                    # Point d'entrée et gestion d'état
│   ├── AppDelegate.swift
│   └── AppState.swift
├── Core/                   # Logique métier
│   ├── AI/                 # Intégration OpenAI
│   │   ├── OpenAIClient.swift
│   │   └── PromptBuilder.swift
│   ├── Clipboard/          # Gestion du presse-papier
│   │   └── ClipboardManager.swift
│   ├── Keyboard/           # Gestion des raccourcis clavier
│   │   └── KeyboardShortcutManager.swift
│   ├── Permissions/        # Gestion des permissions
│   │   └── PermissionManager.swift
│   └── Selection/          # Gestion de la sélection de texte
│       └── SelectionManager.swift
├── UI/                     # Interfaces utilisateur
│   ├── ActionPopupView.swift
│   ├── MenuBarView.swift
│   ├── OnboardingView.swift
│   ├── SettingsView.swift
│   └── ShortcutConfigView.swift
└── Utils/                  # Utilitaires
    ├── Constants.swift
    ├── KeychainManager.swift
    └── Logger.swift
```

## 🔧 Technologies utilisées

- **SwiftUI** : Interface utilisateur moderne
- **AppKit** : Intégration macOS native
- **OpenAI API** : Modèle GPT-4o-mini pour le traitement du texte
- **Keychain Services** : Stockage sécurisé de la clé API
- **Accessibility API** : Lecture et modification du texte sélectionné

## 🔐 Sécurité

- La clé API OpenAI est stockée dans le Keychain macOS, le système de stockage sécurisé d'Apple
- Aucune donnée n'est envoyée à des serveurs tiers autres qu'OpenAI
- Les permissions d'accessibilité sont utilisées uniquement pour lire et modifier le texte sélectionné

## 🐛 Dépannage

### L'application ne détecte pas le texte sélectionné

- Vérifiez que les permissions d'accessibilité sont accordées dans Réglages Système > Confidentialité et sécurité > Accessibilité
- Assurez-vous que l'application est bien listée et activée

### Erreur de connexion à l'API OpenAI

- Vérifiez votre connexion internet
- Vérifiez que votre clé API est correcte dans les paramètres
- Assurez-vous que votre compte OpenAI a des crédits disponibles

### Le raccourci clavier ne fonctionne pas

- Vérifiez qu'aucune autre application n'utilise le même raccourci
- Réinitialisez le raccourci dans les paramètres
- Redémarrez l'application après avoir modifié le raccourci

## 📝 Notes

- L'application utilise le modèle `gpt-4o-mini` par défaut (configurable dans `Constants.swift`)
- Le timeout des requêtes API est fixé à 30 secondes
- L'application fonctionne uniquement sur macOS

## 📄 Licence

Ce projet est sous licence **Non-Commerciale**. L'utilisation commerciale est interdite. Voir le fichier LICENSE pour plus de détails.

Pour toute demande de licence commerciale, veuillez contacter l'auteur.

## 👤 Auteur

Créé par Julien Prince

## 🙏 Remerciements

- OpenAI pour l'API GPT
- La communauté Swift/SwiftUI pour les ressources et l'inspiration
