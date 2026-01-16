import Foundation

struct Match: Hashable, Identifiable {
    let id = UUID()
    let allergenKey: String        // e.g. "milk" or "custom:annatto"
    let matchedTerm: String        // normalized term
    let contextLine: String        // original OCR line
}

final class AllergenMatcher {
    private let compiledTerms: [(key: String, term: String)]

    init(selectedAllergens: [String: [String]], customTerms: [String]) {
        var terms: [(String, String)] = []

        for (key, list) in selectedAllergens {
            for t in list {
                let nt = Self.norm(t)
                if !nt.isEmpty { terms.append((key, nt)) }
            }
        }

        for c in customTerms {
            let nc = Self.norm(c)
            if !nc.isEmpty { terms.append(("custom:\(nc)", nc)) }
        }

        // Prefer longer terms first (reduces silly partial matches)
        self.compiledTerms = terms.sorted { $0.term.count > $1.term.count }
    }

    func findMatches(in lines: [String]) -> [Match] {
        let normalizedLines = lines.map { Self.norm($0) }
        var results = Set<Match>()

        for (idx, lineNorm) in normalizedLines.enumerated() {
            for (key, term) in compiledTerms {
                guard Self.containsWholeWordOrPhrase(lineNorm, term: term) else { continue }
                results.insert(Match(allergenKey: key, matchedTerm: term, contextLine: lines[idx]))
            }
        }

        return Array(results).sorted { $0.allergenKey < $1.allergenKey }
    }

    /// Normalize: lowercase, punctuation->spaces, collapse whitespace
    static func norm(_ s: String) -> String {
        let lower = s.lowercased()
        let replaced = lower.replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
        return replaced
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
    }

    /// Boundary-aware match after normalization (punctuation already spaces).
    static func containsWholeWordOrPhrase(_ text: String, term: String) -> Bool {
        if term.contains(" ") {
            return text.contains(term)
        } else {
            let padded = " \(text) "
            return padded.contains(" \(term) ")
        }
    }
}
