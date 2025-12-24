//
//  KeychainManager.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Foundation
import Security

class KeychainManager {
    
    // Sauvegarder la clé API dans le Keychain
    static func saveAPIKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else {
            Logger.error("Failed to convert API key to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: Constants.apiKeyKey,
            kSecValueData as String: data
        ]
        
        // Supprimer l'ancienne clé si elle existe
        SecItemDelete(query as CFDictionary)
        
        // Ajouter la nouvelle clé
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            Logger.info("API key saved to Keychain")
            return true
        } else {
            Logger.error("Failed to save API key to Keychain: \(status)")
            return false
        }
    }
    
    // Récupérer la clé API depuis le Keychain
    static func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: Constants.apiKeyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            Logger.debug("API key retrieved from Keychain")
            return key
        } else {
            Logger.debug("No API key found in Keychain")
            return nil
        }
    }
    
    // Supprimer la clé API du Keychain
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: Constants.apiKeyKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            Logger.info("API key deleted from Keychain")
            return true
        } else {
            Logger.error("Failed to delete API key from Keychain: \(status)")
            return false
        }
    }
}

