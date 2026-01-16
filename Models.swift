import Foundation
import Combine

struct AllergenDefinition: Identifiable, Hashable {
    let id: String
    let displayName: String
    let terms: [String]
}

enum AllergenCatalog {
    static let items: [AllergenDefinition] = [
        .init(
            id: "milk",
            displayName: "Milk",
            terms: ["milk", "whey", "casein", "caseinate", "lactose", "butter", "cream", "ghee"]
        ),
        .init(
            id: "egg",
            displayName: "Egg",
            terms: ["egg", "albumin", "ovalbumin", "ovomucoid"]
        ),
        .init(
            id: "peanut",
            displayName: "Peanut",
            terms: ["peanut", "groundnut", "arachis"]
        ),
        .init(
            id: "tree_nut",
            displayName: "Tree Nuts",
            terms: ["almond", "walnut", "cashew", "pecan", "pistachio", "hazelnut", "macadamia", "brazil nut", "pine nut"]
        ),
        .init(
            id: "soy",
            displayName: "Soy",
            terms: ["soy", "soya", "soybean", "edamame", "miso", "tempeh", "tofu", "lecithin"]
        ),
        .init(
            id: "wheat",
            displayName: "Wheat / Gluten (basic)",
            terms: ["wheat", "gluten", "barley", "rye", "malt"]
        ),
        .init(
            id: "sesame",
            displayName: "Sesame",
            terms: ["sesame", "tahini", "benne", "gingelly"]
        ),
       .init(
            id: "coconut",
            displayName: "Coconut",
            terms: ["coconut", "cocos nucifera", "sodium cocoate", "coco betaine", "cocamide mipa", "coco glucoside"]
        ),
      .init(
            id: "annatto",
            displayName: "Annatto",
            terms: ["annatto", "achiote", "bixin", "norbixin"]
        )
    ]
}

/// Stores user selections in UserDefaults (simple MVP storage).
final class UserAllergenStore: ObservableObject {
    @Published var selectedAllergenIDs: Set<String>
    @Published var customTerms: [String]

    private var cancellables = Set<AnyCancellable>()

    private let selectedKey = "selectedAllergenIDs_v1"
    private let customKey = "customTerms_v1"

    init() {
        // Load
        let savedSelected = UserDefaults.standard.stringArray(forKey: selectedKey) ?? []
        self.selectedAllergenIDs = Set(savedSelected)

        let savedCustom = UserDefaults.standard.stringArray(forKey: customKey) ?? []
        self.customTerms = savedCustom

        // Save on change
        $selectedAllergenIDs
            .sink { [weak self] set in
                guard let self else { return }
                UserDefaults.standard.set(Array(set).sorted(), forKey: self.selectedKey)
            }
            .store(in: &cancellables)

        $customTerms
            .sink { [weak self] terms in
                guard let self else { return }
                let cleaned = terms
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                UserDefaults.standard.set(cleaned, forKey: self.customKey)
            }
            .store(in: &cancellables)
    }

    func compiledSelectedAllergensMap() -> [String: [String]] {
        let selected = AllergenCatalog.items.filter { selectedAllergenIDs.contains($0.id) }
        var map: [String: [String]] = [:]
        for a in selected {
            map[a.id] = a.terms
        }
        return map
    }
}
