// ParserService.swift
// SuppliScan
//
// Deterministic OCR text parser. It never uses AI and never silently drops
// unclassified content; unclear lines become RawLine entries for review.

import Foundation

nonisolated struct ParserService: Sendable {
    private let aliasesByVariant: [String: String]

    init(aliasesByVariant: [String: String] = [:]) {
        self.aliasesByVariant = aliasesByVariant.reduce(into: [:]) { result, pair in
            result[Self.normalizedKey(pair.key)] = pair.value
        }
    }

    /// Creates a parser using the bundled alias table.
    static func makeDefault(bundle: Bundle = .main) throws -> ParserService {
        let file = try bundle.referenceData(named: "aliases", as: AliasDataFile.self)
        var aliases: [String: String] = [:]

        for entry in file.aliases {
            aliases[entry.canonical] = entry.canonical
            for variant in entry.variants {
                aliases[variant] = entry.canonical
            }
        }

        return ParserService(aliasesByVariant: aliases)
    }

    /// Parses raw OCR text into typed label entries and an optional serving size.
    func parse(_ rawText: String) -> ParseResult {
        var entries: [LabelEntry] = []
        var extractedServing: ServingSize?

        let rawLines = rawText
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Merge two-column OCR lines: nutrient name on one line, amount on the next.
        // Vision returns each table column as a separate observation when text is
        // spatially separated, producing "Taurine" then "1000mg" as separate lines.
        let lines = mergedTwoColumnLines(rawLines)

        for (index, line) in lines.enumerated() {
            if let serving = servingSize(from: line) {
                extractedServing = serving
            }

            guard !shouldSkip(line) else { continue }

            if let nutrient = nutrientEntry(from: line) {
                entries.append(.nutrient(UnitConversionService.convertIfNeeded(nutrient)))
            } else {
                entries.append(.unresolved(RawLine(text: line, lineNumber: index + 1)))
            }
        }

        return ParseResult(entries: entries, extractedServing: extractedServing)
    }

    /// Merges consecutive pairs where the first is a name-only line and the second is
    /// an amount-only line — the two-column supplement facts table pattern from Vision OCR.
    private func mergedTwoColumnLines(_ lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0
        while i < lines.count {
            let current = lines[i]
            if i + 1 < lines.count {
                let next = lines[i + 1]
                if isNameOnlyLine(current) && isAmountOnlyLine(next) {
                    result.append(current + " " + next)
                    i += 2
                    continue
                }
            }
            result.append(current)
            i += 1
        }
        return result
    }

    /// True when a line contains a recognisable name but no parseable amount.
    private func isNameOnlyLine(_ line: String) -> Bool {
        guard !shouldSkip(line) else { return false }
        guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return amountMatch(in: line) == nil
    }

    /// True when a line is purely an amount with no meaningful name prefix.
    /// e.g. "1000mg", "350 mcg", "< 1 mg" — the name must appear on the previous line.
    private func isAmountOnlyLine(_ line: String) -> Bool {
        guard let match = amountMatch(in: line) else { return false }
        let prefix = String(line[..<match.range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix.isEmpty || prefix.count <= 2
    }

    private func nutrientEntry(from line: String) -> NutrientEntry? {
        guard let amountMatch = amountMatch(in: line) else {
            if isBlendLine(line) {
                return makeNutrientEntry(from: line, amountMatch: nil, extraFlags: [.amountNotFound, .proprietaryBlend])
            }
            return nil
        }

        return makeNutrientEntry(
            from: line,
            amountMatch: amountMatch,
            extraFlags: isBlendLine(line) ? [.proprietaryBlend] : []
        )
    }

    private func makeNutrientEntry(
        from line: String,
        amountMatch: AmountMatch?,
        extraFlags: [ReviewFlag]
    ) -> NutrientEntry? {
        let prefix = amountMatch.map { String(line[..<$0.range.lowerBound]) } ?? line
        let nameAndForm = extractNameAndForm(from: prefix)
        guard !nameAndForm.name.isEmpty else { return nil }

        let canonical = canonicalName(for: nameAndForm.name)
        let inferred = canonical != nameAndForm.name
        let flags = appended(
            inferred ? [.canonicalNameInferred] : [],
            to: appended(amountMatch?.flags ?? [], to: extraFlags)
        )

        return NutrientEntry(
            canonicalName: canonical,
            displayName: titleCased(nameAndForm.name),
            form: nameAndForm.form,
            amount: amountMatch?.amount,
            unit: amountMatch?.unit ?? .unknown,
            isElemental: line.localizedCaseInsensitiveContains("elemental"),
            isTotalLine: isTotalLine(line),
            reviewFlags: flags
        )
    }

    private func extractNameAndForm(from text: String) -> (name: String, form: String?) {
        var working = text
            .replacingOccurrences(of: ":", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let open = working.firstIndex(of: "("),
            let close = working[open...].firstIndex(of: ")")
        else {
            return (cleanName(working), nil)
        }

        let parenthetical = String(working[working.index(after: open)..<close])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let form = normalizedForm(parenthetical)
        working.removeSubrange(open...close)

        return (cleanName(working), form)
    }

    private func normalizedForm(_ text: String) -> String? {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return nil }

        return replacing(
            pattern: #"(?i)^from\s+"#,
            in: replacing(pattern: #"(?i)^as\s+"#, in: lower, with: ""),
            with: ""
        )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanName(_ text: String) -> String {
        replacing(pattern: #"(?i)\b(elemental|contains|per|each)\b"#, in: text, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func amountMatch(in line: String) -> AmountMatch? {
        let normalized = line.replacingOccurrences(of: "I.U.", with: "IU", options: .caseInsensitive)

        if let match = firstMatch(
            in: normalized,
            pattern: #"(?i)<\s*1\s*(mg|mcg|μg|µg|ug|g|iu)\b"#
        ) {
            return AmountMatch(amount: 0.5, unit: unit(from: match.captures[0]), flags: [.subOneAmount], range: match.range)
        }

        if normalized.localizedCaseInsensitiveContains("trace"),
           let match = firstMatch(in: normalized, pattern: #"(?i)\btrace\s*(mg|mcg|μg|µg|ug|g|iu)\b"#) {
            return AmountMatch(amount: 0, unit: unit(from: match.captures[0]), flags: [.traceAmount], range: match.range)
        }

        if let match = firstMatch(
            in: normalized,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*[-–]\s*\d+(?:[\.,]\d+)?\s*(mg|mcg|μg|µg|ug|g|iu)\b"#
        ) {
            var flags: [ReviewFlag] = [.rangeAmount]
            let amount = decimalAmount(match.captures[0], flags: &flags)
            return AmountMatch(amount: amount, unit: unit(from: match.captures[1]), flags: flags, range: match.range)
        }

        if let match = firstMatch(
            in: normalized,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*(mg\s+(?:ne|re|rae|dfe)|mcg|μg|µg|ug|mg|g|iu)\b"#
        ) {
            var flags: [ReviewFlag] = []
            if line[match.range.upperBound...].localizedCaseInsensitiveContains("iu")
                || line[match.range.upperBound...].localizedCaseInsensitiveContains("mcg") {
                flags.append(.dualUnit)
            }
            let amount = decimalAmount(match.captures[0], flags: &flags)
            return AmountMatch(amount: amount, unit: unit(from: match.captures[1]), flags: flags, range: match.range)
        }

        if let match = firstMatch(in: normalized, pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*([a-zµμ]+)\b"#) {
            var flags: [ReviewFlag] = [.unitUnknown]
            let amount = decimalAmount(match.captures[0], flags: &flags)
            return AmountMatch(amount: amount, unit: .unknown, flags: flags, range: match.range)
        }

        return nil
    }

    private func decimalAmount(_ rawValue: String, flags: inout [ReviewFlag]) -> Double? {
        if rawValue.contains(",") {
            flags.append(.decimalCommaNormalised)
        }
        return Double(rawValue.replacingOccurrences(of: ",", with: "."))
    }

    private func unit(from rawUnit: String) -> NutrientUnit {
        let normalized = rawUnit
            .lowercased()
            .replacingOccurrences(of: "μ", with: "mc")
            .replacingOccurrences(of: "µ", with: "mc")
            .replacingOccurrences(of: " ", with: "")

        if normalized.hasPrefix("mg") { return .mg }
        if normalized == "mcg" || normalized == "ug" { return .mcg }
        if normalized == "g" { return .g }
        if normalized == "iu" { return .iu }
        return .unknown
    }

    private func servingSize(from line: String) -> ServingSize? {
        guard line.localizedCaseInsensitiveContains("serv") || line.localizedCaseInsensitiveContains("each") else {
            return nil
        }

        guard let match = firstMatch(
            in: line,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*(capsules?|tablets?|teaspoons?|tablespoons?|g|grams?|ml|sachets?|scoops?)\b"#
        ) else {
            return nil
        }

        let quantity = Double(match.captures[0].replacingOccurrences(of: ",", with: ".")) ?? 1
        return ServingSize(quantity: quantity, unit: servingUnit(from: match.captures[1]))
    }

    private func servingUnit(from rawUnit: String) -> ServingUnit {
        let lower = rawUnit.lowercased()
        if lower.hasPrefix("capsule") { return .capsule }
        if lower.hasPrefix("tablet") { return .tablet }
        if lower.hasPrefix("teaspoon") { return .teaspoon }
        if lower.hasPrefix("tablespoon") { return .tablespoon }
        if lower == "g" || lower.hasPrefix("gram") { return .gram }
        if lower == "ml" { return .ml }
        if lower.hasPrefix("sachet") { return .sachet }
        if lower.hasPrefix("scoop") { return .scoop }
        return .unknown
    }

    private func shouldSkip(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if trimmed.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." || $0 == "," }) {
            return true
        }

        if lower.contains("%") && firstMatch(in: lower, pattern: #"\d"#) != nil && amountMatch(in: lower) == nil {
            return true
        }

        let headers = [
            "supplement facts", "nutrition information", "active ingredients",
            "amount per serve", "amount per serving", "amount per capsule",
            "amount per tablet", "% daily value", "% rdi", "% nrv"
        ]
        return headers.contains { lower.contains($0) }
    }

    private func isBlendLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("blend") || lower.contains("complex")
            || lower.contains("matrix") || lower.contains("proprietary")
    }

    private func isTotalLine(_ line: String) -> Bool {
        line.lowercased().contains("total")
    }

    private func canonicalName(for extractedName: String) -> String {
        aliasesByVariant[Self.normalizedKey(extractedName)] ?? titleCased(extractedName)
    }

    private func titleCased(_ value: String) -> String {
        value
            .split(separator: " ")
            .map { word in
                let raw = String(word)
                if raw.range(of: #"^b\d+$"#, options: [.regularExpression, .caseInsensitive]) != nil {
                    return raw.uppercased()
                }
                if raw == raw.uppercased(), raw.count <= 5 { return raw }
                return raw.prefix(1).uppercased() + raw.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }

    private static func normalizedKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func appended(_ newFlags: [ReviewFlag], to existing: [ReviewFlag]) -> [ReviewFlag] {
        newFlags.reduce(existing) { flags, flag in
            flags.contains(flag) ? flags : flags + [flag]
        }
    }

    private func firstMatch(in text: String, pattern: String) -> RegexMatch? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              let range = Range(match.range, in: text)
        else {
            return nil
        }

        let captures = (1..<match.numberOfRanges).compactMap { index -> String? in
            guard let captureRange = Range(match.range(at: index), in: text) else { return nil }
            return String(text[captureRange])
        }

        return RegexMatch(range: range, captures: captures)
    }

    private func replacing(pattern: String, in text: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, range: nsRange, withTemplate: replacement)
    }
}

nonisolated private struct AmountMatch {
    let amount: Double?
    let unit: NutrientUnit
    let flags: [ReviewFlag]
    let range: Range<String.Index>
}

nonisolated private struct RegexMatch {
    let range: Range<String.Index>
    let captures: [String]
}

nonisolated private struct AliasDataFile: Decodable {
    let aliases: [AliasEntry]
}

nonisolated private struct AliasEntry: Decodable {
    let canonical: String
    let variants: [String]
}
