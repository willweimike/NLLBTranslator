import Foundation

class TranslationService {
    static let shared = TranslationService()
    private let baseURL = "http://127.0.0.1:8080/translate"
    
    private let sourceLanguageMap: [String: String] = [
        "en_US": "eng_Latn",
        "zh": "zho_Hant",
        "de": "deu_Latn",
        "fr": "fra_Latn",
        "pt": "eng_Latn",
        "es": "spa_Latn",
        "it": "eng_Latn"
    ]
    
    struct TranslationRequest: Codable {
        let src_lang: String
        let tgt_lang: String
        let source_text: String
    }
    
    struct TranslationResponse: Codable {
        let translation: String
    }
    
    func translate(sourceText: String, sourceLanguage: String, targetLanguage: String) async throws -> String {
        let mappedSourceLang = sourceLanguageMap[sourceLanguage] ?? "eng_Latn"
        
        let request = TranslationRequest(
            src_lang: mappedSourceLang,
            tgt_lang: targetLanguage,
            source_text: sourceText
        )
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let response = try JSONDecoder().decode(TranslationResponse.self, from: data)
        
        return response.translation
    }
}
