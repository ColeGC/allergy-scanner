import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var store: UserAllergenStore
    @State private var newCustomTerm: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Select allergens to flag") {
                    ForEach(AllergenCatalog.items) { allergen in
                        Toggle(isOn: bindingForAllergen(allergen.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(allergen.displayName)
                                Text(allergen.terms.prefix(4).joined(separator: ", ") + (allergen.terms.count > 4 ? "…" : ""))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Custom keywords") {
                    HStack {
                        TextField("e.g., annatto, carmine", text: $newCustomTerm)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("Add") {
                            addCustomTerm()
                        }
                        .disabled(newCustomTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if store.customTerms.isEmpty {
                        Text("No custom keywords yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.customTerms, id: \.self) { term in
                            Text(term)
                        }
                        .onDelete(perform: deleteCustomTerms)
                    }
                }
            }
            .navigationTitle("Allergens")
            .toolbar {
                EditButton()
            }
        }
    }

    private func bindingForAllergen(_ id: String) -> Binding<Bool> {
        Binding(
            get: { store.selectedAllergenIDs.contains(id) },
            set: { isOn in
                if isOn { store.selectedAllergenIDs.insert(id) }
                else { store.selectedAllergenIDs.remove(id) }
            }
        )
    }

    private func addCustomTerm() {
        let trimmed = newCustomTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !store.customTerms.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            store.customTerms.append(trimmed)
        }
        newCustomTerm = ""
    }

    private func deleteCustomTerms(at offsets: IndexSet) {
        store.customTerms.remove(atOffsets: offsets)
    }
}
