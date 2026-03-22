//
//  FoodSearchService.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation

// MARK: - Public result model

struct FoodSearchResult: Identifiable {
    let id: String
    let name: String        // e.g. "Banana"
    let brand: String       // e.g. "Raw" / "Dried" / "Ripe, cooked"
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
}

// MARK: - USDA JSON models

private struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

private struct USDAFood: Decodable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let foodNutrients: [USDANutrient]
}

private struct USDANutrient: Decodable {
    let nutrientId: Int?
    let value: Double?
}

private enum NutrientID {
    static let calories = 1008
    static let protein  = 1003
    static let carbs    = 1005
    static let fat      = 1004
}

// MARK: - Service

@Observable
class FoodSearchService {
    var results: [FoodSearchResult] = []
    var isLoading = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?
    private var cache: [String: [FoodSearchResult]] = [:]

    private let apiKey = "3KF8C5Gm2UpuPYfBZUXlEesaa14nPll8NcH9DuPJ"

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        if let cached = cache[trimmed] {
            results = cached
            errorMessage = nil
            return
        }

        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    func clearResults() {
        results = []
        errorMessage = nil
        searchTask?.cancel()
    }

    @MainActor
    private func performSearch(_ query: String) async {
        isLoading = true
        errorMessage = nil

        // Fetch more results so we have enough to filter into meaningful variants
        async let wholeFoods = fetchUSDA(query: query, dataType: "SR Legacy,Foundation", pageSize: 20)
        async let survey     = fetchUSDA(query: query, dataType: "Survey (FNDDS)",       pageSize: 10)

        let (wf, sv) = await (wholeFoods, survey)
        let raw = wf + sv

        // Parse into clean (name, variant) pairs and deduplicate by variant
        let parsed = raw.compactMap { parseFood($0, query: query) }
        let deduped = deduplicate(parsed)

        cache[query] = deduped
        results = deduped

        if results.isEmpty {
            errorMessage = "No results found. Try a different name or add manually."
        }

        isLoading = false
    }

    // MARK: - Parse USDA description into clean name + variant

    private func parseFood(_ food: FoodSearchResult, query: String) -> FoodSearchResult? {
        guard food.caloriesPer100g > 0 || food.proteinPer100g > 0 else { return nil }

        let desc = food.name // already partially cleaned
        let lower = desc.lowercased()

        // Extract the variant from the description
        // USDA descriptions look like: "Bananas, raw" / "Bananas, dehydrated" / "Bananas, ripe, cooked"
        let variant = extractVariant(from: lower, query: query)

        // Clean display name — capitalize query word
        let displayName = query.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        return FoodSearchResult(
            id: food.id,
            name: displayName,
            brand: variant,
            caloriesPer100g: food.caloriesPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g
        )
    }

    private func extractVariant(from description: String, query: String) -> String {
        // Remove the query word itself from description to get the variant part
        var variant = description
        let queryWords = query.lowercased().split(separator: " ").map(String.init)
        for word in queryWords {
            variant = variant.replacingOccurrences(of: word, with: "")
        }

        // Clean up punctuation and extra spaces
        variant = variant
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Map common USDA terms to friendly labels
        let mappings: [(keywords: [String], label: String)] = [
            (["raw", "fresh"],                          "Raw"),
            (["dried", "dehydrated", "dry"],            "Dried"),
            (["cooked", "boiled", "steamed"],           "Cooked"),
            (["roasted", "baked", "oven"],              "Roasted"),
            (["fried", "stir-fried", "pan-fried"],      "Fried"),
            (["grilled", "broiled", "charbroiled"],     "Grilled"),
            (["ripe"],                                  "Ripe"),
            (["unripe", "green", "plantain"],           "Unripe / Green"),
            (["canned", "tinned"],                      "Canned"),
            (["frozen"],                                "Frozen"),
            (["powder", "flour"],                       "Powder / Flour"),
            (["juice"],                                 "Juice"),
            (["breast"],                                "Breast"),
            (["thigh", "leg"],                          "Thigh / Leg"),
            (["wing"],                                  "Wing"),
            (["skin"],                                  "With Skin"),
            (["boneless"],                              "Boneless"),
            (["whole"],                                 "Whole"),
            (["skinless"],                              "Skinless"),
            (["nendra", "nendran"],                     "Nendra (Kerala)"),
            (["robusta"],                               "Robusta"),
            (["cavendish"],                             "Cavendish"),
            (["red"],                                   "Red Variety"),
            (["wild"],                                  "Wild"),
            (["white"],                                 "White"),
            (["brown", "wholegrain", "whole grain"],    "Wholegrain"),
            (["basmati"],                               "Basmati"),
            (["jasmine"],                               "Jasmine"),
        ]

        let variantLower = variant.lowercased()
        for mapping in mappings {
            if mapping.keywords.contains(where: { variantLower.contains($0) }) {
                return mapping.label
            }
        }

        // If no mapping found, capitalize whatever variant text remains
        if variant.isEmpty { return "Standard" }
        return variant.prefix(1).uppercased() + variant.dropFirst()
    }

    // MARK: - Deduplicate by variant label, keep best calorie data

    private func deduplicate(_ foods: [FoodSearchResult]) -> [FoodSearchResult] {
        var seen = [String: FoodSearchResult]()

        for food in foods {
            let key = food.brand.lowercased()
            if seen[key] == nil {
                seen[key] = food
            }
        }

        // Sort: Raw first, then alphabetically by variant
        return seen.values.sorted {
            if $0.brand == "Raw" { return true }
            if $1.brand == "Raw" { return false }
            return $0.brand < $1.brand
        }
    }

    // MARK: - USDA fetch helper

    private func fetchUSDA(query: String, dataType: String, pageSize: Int) async -> [FoodSearchResult] {
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "query",    value: query),
            URLQueryItem(name: "dataType", value: dataType),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "api_key",  value: apiKey)
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }

            let decoded = try JSONDecoder().decode(USDASearchResponse.self, from: data)

            return decoded.foods.compactMap { food in
                let nutrients = food.foodNutrients

                func value(for id: Int) -> Double {
                    nutrients.first(where: { $0.nutrientId == id })?.value ?? 0
                }

                let calories = value(for: NutrientID.calories)
                let protein  = value(for: NutrientID.protein)
                let carbs    = value(for: NutrientID.carbs)
                let fat      = value(for: NutrientID.fat)

                return FoodSearchResult(
                    id: "\(food.fdcId)",
                    name: food.description.capitalized,
                    brand: "",
                    caloriesPer100g: calories,
                    proteinPer100g: protein,
                    carbsPer100g: carbs,
                    fatPer100g: fat
                )
            }
        } catch {
            return []
        }
    }
}
