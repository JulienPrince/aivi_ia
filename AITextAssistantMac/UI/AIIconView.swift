//
//  AIIconView.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import SwiftUI
import AppKit

// Vue SwiftUI pour l'icône AI (texte "Aivi" uniquement)
struct AIIconView: View {
    var size: CGFloat = 56
    var showShadow: Bool = true
    
    var body: some View {
        // Texte "Aivi" uniquement (pas le logo)
        Text("Aivi")
            .font(.system(size: size * 0.5, weight: .regular, design: .rounded))
            .foregroundColor(.primary)
            .frame(width: size, height: size)
    }
}

// Helper pour créer une NSImage avec le texte (pour le menu bar)
extension AIIconView {
    static func createNSImage(size: CGFloat = 28) -> NSImage? {
        // Créer une image avec le texte "Aivi" (pas le logo)
        // Ajouter un peu de padding pour éviter la coupure
        let padding: CGFloat = 4
        let imageSize = size + (padding * 2)
        let image = NSImage(size: NSSize(width: imageSize, height: imageSize))
        image.lockFocus()
        
        let fontSize = size * 0.55 // Ajusté pour mieux s'adapter
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor // S'adapte au thème
        ]
        
        let text = "Aivi"
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: (imageSize - textSize.width) / 2,
            y: (imageSize - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)
        
        image.unlockFocus()
        image.isTemplate = true // Monocrome, s'adapte au thème
        
        return image
    }
}
