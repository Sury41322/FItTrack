//import Foundation
//
//struct FoodResult: Identifiable {
//    let id = UUID()
//    let name: String
//    let calories: Double
//    let protein: Double
//    let carbs: Double
//    let fat: Double
//    let servingSize: String
//}
//
//import Observation
//
//@Observable
//class NutritionService {
//
//    // 🔑 Paste your Anthropic API key here
//    private let apiKey = "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"
//    private let apiURL = "https://api.anthropic.com/v1/messages"
//
//    func searchFoods(query: String) async throws -> [FoodResult] {
//        guard !query.isEmpty else { return [] }
//
//        let prompt = """
//        The user is searching for "\(query)" in a fitness nutrition app.
//
//        Return a JSON array of up to 6 matching foods — include both Indian and international variations if relevant.
//        Focus on common serving sizes actually eaten (not always 100g).
//
//        Respond ONLY with a valid JSON array, no explanation, no markdown, no extra text.
//        Format exactly like this:
//        [
//          {
//            "name": "Idli (2 pieces)",
//            "calories": 150,
//            "protein": 4,
//            "carbs": 32,
//            "fat": 0.5,
//            "servingSize": "2 pieces (120g)"
//          }
//        ]
//        """
//
//        let body: [String: Any] = [
//            "model": "claude-sonnet-4-20250514",
//            "max_tokens": 1000,
//            "messages": [
//                ["role": "user", "content": prompt]
//            ]
//        ]
//
//        guard let url = URL(string: apiURL) else {
//            throw URLError(.badURL)
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
//        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
//        request.httpBody = try JSONSerialization.data(withJSONObject: body)
//
//        let (data, _) = try await URLSession.shared.data(for: request)
//
//        // Parse Claude's response
//        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//              let content = json["content"] as? [[String: Any]],
//              let text = content.first?["text"] as? String else {
//            throw URLError(.cannotParseResponse)
//        }
//
//        // Extract JSON array from Claude's text response
//        guard let jsonData = text.data(using: .utf8),
//              let foods = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
//            throw URLError(.cannotParseResponse)
//        }
//
//        return foods.compactMap { food in
//            guard let name = food["name"] as? String else { return nil }
//            return FoodResult(
//                name: name,
//                calories: (food["calories"] as? Double) ?? Double(food["calories"] as? Int ?? 0),
//                protein: (food["protein"] as? Double) ?? Double(food["protein"] as? Int ?? 0),
//                carbs: (food["carbs"] as? Double) ?? Double(food["carbs"] as? Int ?? 0),
//                fat: (food["fat"] as? Double) ?? Double(food["fat"] as? Int ?? 0),
//                servingSize: food["servingSize"] as? String ?? "1 serving"
//            )
//        }
//    }
//}

//
//  NutritionService.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import Observation

@Observable
class NutritionService {

    // 🔑 Paste your Anthropic API key here
    private let apiKey = "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"
    private let apiURL = "https://api.anthropic.com/v1/messages"

    func searchFoods(query: String) async throws -> [FoodResult] {
        guard !query.isEmpty else { return [] }

        let prompt = """
        The user is searching for "\(query)" in a fitness nutrition app.

        Return a JSON array of up to 6 matching foods — include both Indian and international variations if relevant.
        Focus on common serving sizes actually eaten (not always 100g).

        Respond ONLY with a valid JSON array, no explanation, no markdown, no extra text.
        Format exactly like this:
        [
          {
            "name": "Idli (2 pieces)",
            "calories": 150,
            "protein": 4,
            "carbs": 32,
            "fat": 0.5,
            "servingSize": "2 pieces (120g)"
          }
        ]
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: apiURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse Claude's response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        // Extract JSON array from Claude's text response
        guard let jsonData = text.data(using: .utf8),
              let foods = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        return foods.compactMap { food in
            guard let name = food["name"] as? String else { return nil }
            return FoodResult(
                name: name,
                calories: (food["calories"] as? Double) ?? Double(food["calories"] as? Int ?? 0),
                protein: (food["protein"] as? Double) ?? Double(food["protein"] as? Int ?? 0),
                carbs: (food["carbs"] as? Double) ?? Double(food["carbs"] as? Int ?? 0),
                fat: (food["fat"] as? Double) ?? Double(food["fat"] as? Int ?? 0),
                servingSize: food["servingSize"] as? String ?? "1 serving"
            )
        }
    }
}

// Data model for a single food search result
struct FoodResult: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
}
