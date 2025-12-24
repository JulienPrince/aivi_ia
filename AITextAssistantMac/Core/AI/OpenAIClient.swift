//
//  OpenAIClient.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Foundation

enum OpenAIError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return Constants.apiKeyMissingError
        case .invalidURL:
            return "URL invalide"
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return "Pas de connexion internet. Vérifiez votre connexion réseau."
            } else if nsError.code == NSURLErrorCannotFindHost {
                return "Impossible de contacter le serveur OpenAI. Vérifiez votre connexion internet et que l'URL est correcte."
            } else if nsError.code == NSURLErrorTimedOut {
                return "La requête a expiré. Vérifiez votre connexion internet."
            } else {
                return "Erreur réseau: \(error.localizedDescription)"
            }
        case .invalidResponse:
            return "Réponse invalide de l'API"
        case .apiError(let message):
            return "Erreur API: \(message)"
        }
    }
}

class OpenAIClient {
    
    // Récupérer la clé API depuis le Keychain
    func getAPIKey() -> String? {
        return KeychainManager.getAPIKey()
    }
    
    // Sauvegarder la clé API dans le Keychain
    func saveAPIKey(_ key: String) -> Bool {
        return KeychainManager.saveAPIKey(key)
    }
    
    // Envoyer une requête à l'API OpenAI
    func sendRequest(prompt: String, action: TextAction, completion: @escaping (Result<String, Error>) -> Void) {
        // Vérifier la clé API
        guard let apiKey = getAPIKey() else {
            Logger.error("API key missing")
            completion(.failure(OpenAIError.apiKeyMissing))
            return
        }
        
        // Construire l'URL
        let urlString = Constants.openAIBaseURL + Constants.openAIChatEndpoint
        Logger.info("Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid URL: \(urlString)")
            completion(.failure(OpenAIError.invalidURL))
            return
        }
        
        Logger.info("URL is valid: \(url.absoluteString)")
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.apiRequestTimeout
        
        Logger.info("Request created for URL: \(url.absoluteString)")
        Logger.debug("API key length: \(apiKey.count) characters")
        
        // Construire le body JSON
        let body: [String: Any] = [
            "model": Constants.defaultModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3, // Basse température pour des réponses déterministes
            "max_tokens": 1000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            Logger.error("Failed to serialize request body: \(error)")
            completion(.failure(error))
            return
        }
        
        Logger.debug("Sending request to OpenAI API")
        
        // Envoyer la requête
        Logger.info("Sending request to OpenAI API: \(url.absoluteString)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Gérer les erreurs réseau
            if let error = error {
                let nsError = error as NSError
                Logger.error("Network error: \(error.localizedDescription)")
                Logger.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                Logger.error("Error userInfo: \(nsError.userInfo)")
                
                // Message d'erreur plus détaillé
                var errorMessage = "Erreur réseau: \(error.localizedDescription)"
                if nsError.code == NSURLErrorNotConnectedToInternet {
                    errorMessage = "Pas de connexion internet. Vérifiez votre connexion réseau."
                } else if nsError.code == NSURLErrorCannotFindHost {
                    errorMessage = "Impossible de contacter le serveur OpenAI. Vérifiez votre connexion internet."
                } else if nsError.code == NSURLErrorTimedOut {
                    errorMessage = "La requête a expiré. Vérifiez votre connexion internet."
                }
                
                completion(.failure(OpenAIError.networkError(error)))
                return
            }
            
            // Vérifier la réponse HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.error("Invalid HTTP response")
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            // Vérifier le code de statut
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                Logger.error("API error: \(httpResponse.statusCode) - \(errorMessage)")
                completion(.failure(OpenAIError.apiError("Status code: \(httpResponse.statusCode)")))
                return
            }
            
            // Parser la réponse
            guard let data = data else {
                Logger.error("No data in response")
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let choices = jsonResponse?["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    Logger.error("Invalid response structure")
                    completion(.failure(OpenAIError.invalidResponse))
                    return
                }
                
                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                Logger.info("Successfully received response from OpenAI")
                completion(.success(trimmedContent))
                
            } catch {
                Logger.error("Failed to parse response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
