import SwiftUI
import UIKit

struct ResultsView: View {
    let capturedImage: UIImage?
    let recognizedLines: [String]
    let matches: [Match]

    @Environment(\.dismiss) private var dismiss
    @State private var showFullText = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusRow
                }

                if let image = capturedImage {
                    Section("Captured image") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Section("Flagged matches") {
                    if matches.isEmpty {
                        Text("No selected allergens found in recognized text.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(matches) { m in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(displayKey(m.allergenKey))
                                    .font(.headline)

                                Text("Matched: \(m.matchedTerm)")
                                    .font(.subheadline)

                                Text(m.contextLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section {
                    Button(showFullText ? "Hide recognized text" : "Show recognized text") {
                        showFullText.toggle()
                    }

                    if showFullText {
                        Text(recognizedLines.joined(separator: "\n"))
                            .font(.footnote)
                            .textSelection(.enabled)
                            .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Results")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var statusRow: some View {
        let flagged = !matches.isEmpty
        return HStack(spacing: 12) {
            Image(systemName: flagged ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.system(size: 28))
                .foregroundStyle(flagged ? .yellow : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(flagged ? "Flagged" : "No matches found")
                    .font(.headline)
                Text(flagged ? summaryText() : "Based on recognized text from the label.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func summaryText() -> String {
        let keys = Set(matches.map { displayKey($0.allergenKey) })
        return "Found: " + keys.sorted().joined(separator: ", ")
    }

    private func displayKey(_ key: String) -> String {
        if key.hasPrefix("custom:") {
            return "Custom (\(key.replacingOccurrences(of: "custom:", with: "")))"
        }
        if let def = AllergenCatalog.items.first(where: { $0.id == key }) {
            return def.displayName
        }
        return key
    }
}
