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
            .map { sanitizedLine(String($0)) }
            .filter { !$0.isEmpty }

        for line in rawLines {
            if let serving = servingSize(from: line) {
                extractedServing = serving
            }
        }

        let candidateLines = ingredientCandidateLines(from: rawLines)
        for line in candidateLines {
            if let serving = servingSize(from: line) {
                extractedServing = serving
            }
        }

        let lines = candidateLines
            .filter { !isServingOnlyLine($0) }

        for (index, line) in lines.enumerated() {
            if let serving = servingSize(from: line) {
                extractedServing = serving
            }

            guard !shouldSkip(line) else { continue }

            if let probiotic = probioticEntry(from: line) {
                entries.append(.probiotic(probiotic))
            } else if let nutrient = nutrientEntry(from: line) {
                entries.append(.nutrient(UnitConversionService.convertIfNeeded(nutrient)))
            } else {
                entries.append(.unresolved(RawLine(text: line, lineNumber: index + 1)))
            }
        }

        return ParseResult(entries: entries, extractedServing: extractedServing)
    }

    /// Prepares OCR lines for deterministic parsing while preserving visible label order.
    private func ingredientCandidateLines(from rawLines: [String]) -> [String] {
        mergedContinuationLines(mergedTwoColumnLines(rawLines))
    }

    /// Merges consecutive pairs where the first is a name-only line and the second is an amount-only line
    /// or an equivalent-continuation line (e.g. name-only + "(providing elemental X 350mg) 1750mg").
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
                if isNameOnlyLine(current) && isEquivalentContinuation(next) {
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

    /// Merges compound rows with their following elemental or equivalent continuation row.
    /// Uses isPureContinuationLine to avoid merging consecutive (providing...) rows that each
    /// carry their own compound name+amount (e.g. two-column OCR layout).
    private func mergedContinuationLines(_ lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let current = lines[i]
            if i + 1 < lines.count {
                let next = lines[i + 1]
                if amountMatch(in: current) != nil, isPureContinuationLine(next) {
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

    /// True when a line is a pure elemental/equiv continuation with no embedded compound name.
    /// "(providing elemental magnesium 13mg) 210mg" → pure (only a trailing amount after ")")
    /// "(providing elemental magnesium 12.2mg) Magnesium glycinate dihydrate 104mg" → NOT pure
    /// "(providing Magnesium 350 mg" (no closing paren) → pure
    private func isPureContinuationLine(_ line: String) -> Bool {
        guard isEquivalentContinuation(line) else { return false }
        guard let closeRange = line.range(of: ")") else { return true }
        let afterClose = String(line[closeRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return afterClose.isEmpty || isAmountOnlyLine(afterClose)
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
        if let match = cfuMatch(in: line) {
            let prefix = String(line[..<match.range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return prefix.isEmpty || prefix.count <= 2
        }

        guard let match = amountMatch(in: line) else { return false }
        let prefix = String(line[..<match.range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix.isEmpty || prefix.count <= 2
    }

    private func probioticEntry(from line: String) -> ProbioticEntry? {
        guard let cfuMatch = cfuMatch(in: line) else { return nil }
        let prefix = String(line[..<cfuMatch.range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if isTotalLine(line), !containsProbioticScientificName(prefix) {
            return ProbioticEntry(
                genus: "Total",
                species: "probiotics",
                cfuBillions: cfuMatch.cfuBillions,
                isTotalLine: true,
                reviewFlags: [.totalLineAmbiguous]
            )
        }

        guard let name = probioticName(from: prefix) else { return nil }
        return ProbioticEntry(
            genus: name.genus,
            species: name.species,
            strain: name.strain,
            cfuBillions: cfuMatch.cfuBillions,
            isTotalLine: isTotalLine(line),
            reviewFlags: isTotalLine(line) ? [.totalLineAmbiguous] : []
        )
    }

    private func nutrientEntry(from line: String) -> NutrientEntry? {
        if let nutrient = compoundEquivalentEntry(from: line) {
            return nutrient
        }

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
        guard !shouldRejectCandidateName(nameAndForm.name, line: line, unit: amountMatch?.unit) else { return nil }

        let canonical = canonicalName(for: nameAndForm.name)
        let inferred = canonical != nameAndForm.name
        let totalFlags: [ReviewFlag] = isTotalLine(line) ? [.totalLineAmbiguous] : []
        let flags = appended(
            inferred ? [.canonicalNameInferred] : [],
            to: appended(totalFlags, to: appended(amountMatch?.flags ?? [], to: extraFlags))
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

    private func compoundEquivalentEntry(from line: String) -> NutrientEntry? {
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)^(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\b\s*\(?\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\b\)?"#
        ) {
            return makeCompoundEquivalentEntry(
                compoundName: match.captures[0],
                compoundAmountText: match.captures[1],
                compoundUnitText: match.captures[2],
                activeNameText: match.captures[3],
                activeAmountText: match.captures[4],
                activeUnitText: match.captures[5],
                sourceLine: line
            )
        }

        if let match = firstMatch(
            in: line,
            pattern: #"(?i)^(.+?)\s+(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\b"#
        ) {
            return makeCompoundEquivalentEntry(
                compoundName: match.captures[0],
                compoundAmountText: nil,
                compoundUnitText: nil,
                activeNameText: match.captures[1],
                activeAmountText: match.captures[2],
                activeUnitText: match.captures[3],
                sourceLine: line
            )
        }

        // Pattern 3: COMPOUND_NAME (providing ACTIVE_NAME ACTIVE_AMT) COMPOUND_AMT
        // e.g. "Magnesium amino acid chelate (providing elemental magnesium 350mg) 1750mg"
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)^(.+?)\s+\(\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\b\s*\)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\b"#
        ) {
            return makeCompoundEquivalentEntry(
                compoundName: match.captures[0],
                compoundAmountText: match.captures[4],
                compoundUnitText: match.captures[5],
                activeNameText: match.captures[1],
                activeAmountText: match.captures[2],
                activeUnitText: match.captures[3],
                sourceLine: line
            )
        }

        // Pattern 4: (providing ACTIVE_NAME ACTIVE_AMT) COMPOUND_NAME COMPOUND_AMT
        // e.g. "(providing elemental magnesium 12.2mg) Magnesium glycinate dihydrate 104mg"
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)^\(\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\s*\)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|μg|µg|ug|g)\b"#
        ) {
            return makeCompoundEquivalentEntry(
                compoundName: match.captures[3],
                compoundAmountText: match.captures[4],
                compoundUnitText: match.captures[5],
                activeNameText: match.captures[0],
                activeAmountText: match.captures[1],
                activeUnitText: match.captures[2],
                sourceLine: line
            )
        }

        return nil
    }

    private func makeCompoundEquivalentEntry(
        compoundName: String,
        compoundAmountText: String?,
        compoundUnitText: String?,
        activeNameText: String,
        activeAmountText: String,
        activeUnitText: String,
        sourceLine: String
    ) -> NutrientEntry? {
        var activeFlags: [ReviewFlag] = []
        let cleanedActiveText = cleanedEquivalentText(activeNameText)
        let activeNameAndForm = extractNameAndForm(from: cleanedActiveText)
        guard !activeNameAndForm.name.isEmpty else { return nil }

        let canonical = canonicalName(for: activeNameAndForm.name)
        let inferred = canonical != activeNameAndForm.name
        let compoundBaseName = cleanName(compoundName)
        let form = compoundForm(from: compoundBaseName, canonicalName: canonical) ?? activeNameAndForm.form

        let amount = decimalAmount(activeAmountText, flags: &activeFlags)
        let compoundAmount = compoundAmountText.flatMap { decimalAmount($0, flags: &activeFlags) }
        let totalFlags: [ReviewFlag] = isTotalLine(sourceLine) ? [.totalLineAmbiguous] : []
        let flags = appended(
            inferred ? [.canonicalNameInferred] : [],
            to: appended(totalFlags, to: appended(activeFlags, to: [.extractEquivalent]))
        )

        return NutrientEntry(
            canonicalName: canonical,
            displayName: titleCased(activeNameAndForm.name),
            form: form,
            amount: amount,
            unit: unit(from: activeUnitText),
            isElemental: true,
            compoundAmount: compoundAmount,
            compoundUnit: compoundUnitText.map { unit(from: $0) },
            isTotalLine: isTotalLine(sourceLine),
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
            if let inlineForm = firstMatch(in: working, pattern: #"(?i)^(.+?)\s+(as|from)\s+(.+)$"#) {
                return (cleanName(inlineForm.captures[0]), normalizedForm(inlineForm.captures[2]))
            }
            return (cleanName(working), nil)
        }

        let parenthetical = String(working[working.index(after: open)..<close])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let form = normalizedForm(parenthetical)
        working.removeSubrange(open...close)

        return (cleanName(working), form)
    }

    private func cleanedEquivalentText(_ text: String) -> String {
        replacing(
            pattern: #"(?i)^\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+"#,
            in: text,
            with: ""
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func compoundForm(from compoundName: String, canonicalName: String) -> String? {
        let normalizedCanonical = Self.normalizedKey(canonicalName)
        let lowerCompound = compoundName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lowerCompound.isEmpty else { return nil }

        if Self.normalizedKey(lowerCompound).hasPrefix(normalizedCanonical) {
            let wordsToDrop = normalizedCanonical.split(separator: " ").count
            let form = lowerCompound
                .split(separator: " ")
                .dropFirst(wordsToDrop)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return form.isEmpty ? nil : form.lowercased()
        }

        return lowerCompound.lowercased()
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
        replacing(pattern: #"(?i)\b(total|elemental|contains|per|each|tablet|capsule)\b"#, in: text, with: "")
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

    private func cfuMatch(in line: String) -> CFUMatch? {
        guard let match = firstMatch(
            in: line,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*(billion|million)?\s*cfu\b"#
        ) else {
            return nil
        }

        var flags: [ReviewFlag] = []
        guard let amount = decimalAmount(match.captures[0], flags: &flags) else {
            return nil
        }

        let scale = match.captures.count > 1 ? match.captures[1].lowercased() : ""
        let cfuBillions: Double
        if scale == "million" {
            cfuBillions = amount / 1_000
        } else if scale == "billion" || scale.isEmpty {
            cfuBillions = amount
        } else {
            cfuBillions = amount
        }

        return CFUMatch(cfuBillions: cfuBillions, range: match.range)
    }

    private func decimalAmount(_ rawValue: String, flags: inout [ReviewFlag]) -> Double? {
        if rawValue.contains(",") {
            if rawValue.range(of: #"^\d{1,3}(,\d{3})+$"#, options: .regularExpression) != nil {
                return Double(rawValue.replacingOccurrences(of: ",", with: ""))
            }
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
        let lower = line.lowercased()
        let servingKeywords = ["serv", "each", "teaspoon", "tablespoon", "scoop", "sachet"]
        guard servingKeywords.contains(where: { lower.contains($0) }) else {
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

    private func isServingOnlyLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.contains("amount per serving") || lower.contains("amount per serve") {
            return true
        }
        if lower.contains("level metric teaspoon") || lower.contains("serving size") {
            return true
        }
        return false
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

        let alwaysSkippedHeaders = [
            "supplement facts", "nutrition information", "active ingredients",
            "amount per serve", "amount per serving", "amount per capsule",
            "amount per tablet", "% daily value", "% rdi", "% nrv"
        ]
        if alwaysSkippedHeaders.contains(where: { lower.contains($0) }) {
            return true
        }

        let ingredientSectionHeaders = [
            "each tablet contains", "each capsule contains", "each dose contains"
        ]
        if ingredientSectionHeaders.contains(where: { lower.contains($0) }), amountMatch(in: trimmed) == nil {
            return true
        }

        let nonIngredientPhrases = [
            "directions for use", "recommended use", "for general health",
            "for muscle", "for joint", "take ", "with food", "directed by",
            "health professional", "doctor", "pregnancy", "pregnant",
            "lactating", "warning", "do not", "symptoms persist",
            "does not contain", "contains egg", "contains gluten",
            "contains milk", "contains peanut", "contains soy", "contains tree nuts",
            "artificial colours", "artificial flavours", "store below",
            "store in", "batch", "expiry", " exp ", " lot "
        ]
        if nonIngredientPhrases.contains(where: { lower.contains($0) }) {
            return true
        }

        // Company, address, and contact rows — common OCR spill from label back/sides.
        let companyAddressFragments = [
            "pty ltd", " ltd", "p/l", " abn ", " acn ", "tel:", "tel.",
            "www.", ".com", ".com.au", "@", " rd,", " st,", " ave,",
            "postcode", "po box", "distributor", "manufactured by", "imported by"
        ]
        if companyAddressFragments.contains(where: { lower.contains($0) }) {
            return true
        }

        return false
    }

    private func isBlendLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("blend") || lower.contains("complex")
            || lower.contains("matrix") || lower.contains("proprietary")
    }

    private func isTotalLine(_ line: String) -> Bool {
        line.lowercased().contains("total")
    }

    private func isEquivalentContinuation(_ line: String) -> Bool {
        line.range(
            of: #"(?i)^\(?\s*(providing|equiv\.?|equivalent(?:\s+to)?)\b"#,
            options: .regularExpression
        ) != nil
    }

    private func containsProbioticScientificName(_ line: String) -> Bool {
        probioticName(from: line) != nil
    }

    private func probioticName(from text: String) -> (genus: String, species: String, strain: String?)? {
        let cleaned = replacing(pattern: #"(?i)\beach\s+capsule\s+contains\b|\bcontains\b|:"#, in: text, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let match = firstMatch(
            in: cleaned,
            pattern: #"(?i)\b(bifidobacterium|lactobacillus|lactococcus|bacillus|saccharomyces|streptococcus)\s+([a-z][a-z-]+)\b\s*([^()]*)?"#
        ) else {
            return nil
        }

        let genus = titleCased(match.captures[0])
        let species = match.captures[1].lowercased()
        let strain = match.captures.count > 2
            ? normalizedStrain(match.captures[2])
            : nil
        return (genus, species, strain)
    }

    private func normalizedStrain(_ text: String) -> String? {
        let trimmed = text
            .replacingOccurrences(of: #"^[\s,;:()]+|[\s,;:()]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func shouldRejectCandidateName(_ name: String, line: String, unit: NutrientUnit?) -> Bool {
        let key = Self.normalizedKey(name)
        guard !key.isEmpty else { return true }

        // Reject bare continuation keywords when they appear as the entire name with no
        // associated compound (e.g., an isolated "Providing" or "Elemental" row).
        // NOTE: Do NOT reject "(providing Magnesium" — that still carries elemental dose data.
        // The compound-merge step should have merged these; a reject would silently discard
        // the elemental amount. Fixing the merge is the correct path (see debug bundle).
        let continuationOnly: Set<String> = ["providing", "equiv", "equivalent"]
        if continuationOnly.contains(key) { return true }

        let rejectedExactNames: Set<String> = [
            "level metric teaspoon", "metric teaspoon", "teaspoon",
            "tablet", "capsule", "adults and children over", "children over"
        ]
        if rejectedExactNames.contains(key) {
            return true
        }

        let rejectedNameFragments = [
            "directions", "recommended", "take", "daily", "health professional",
            "adult", "children", "serving", "level metric", "teaspoon"
        ]
        if rejectedNameFragments.contains(where: { key.contains($0) }) {
            return true
        }

        if unit == .unknown {
            let lower = line.lowercased()
            let rejectedUnknownUnits = [" year", "years", "day", "days", "time", "times", "pack"]
            if rejectedUnknownUnits.contains(where: { lower.contains($0) }) {
                return true
            }
        }

        // Reject OCR artifact where "TOTAL ELEMENTAL X" was misread as "f elemental X".
        // cleanName strips "elemental", leaving a single-char prefix before the real name
        // (e.g. "f magnesium"). Safe guard: only fires when source line contains "elemental"
        // so it never touches legitimate D-Biotin, L-Glutamine, N-Acetyl prefixes.
        let nameParts = name.split(separator: " ")
        if nameParts.count >= 2, nameParts[0].count == 1,
           line.localizedCaseInsensitiveContains("elemental") {
            return true
        }

        return false
    }

    private func sanitizedLine(_ rawLine: String) -> String {
        rawLine
            .precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "®", with: "")
            .replacingOccurrences(of: "™", with: "")
            .replacingOccurrences(of: "✓", with: "")
            .replacingOccurrences(of: #"[…·•]{2,}|[.]{3,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

nonisolated private struct CFUMatch {
    let cfuBillions: Double
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

#if DEBUG
// MARK: - Debug decision tracing

extension ParserService {
    /// Returns per-row parse decisions for debug bundle construction.
    func debugDecisions(for rawText: String) -> [OCRDebugParserDecision] {
        let rawLines = rawText
            .split(whereSeparator: \.isNewline)
            .map { sanitizedLine(String($0)) }
            .filter { !$0.isEmpty }

        let candidateLines = ingredientCandidateLines(from: rawLines)
        var decisions: [OCRDebugParserDecision] = []

        for line in candidateLines {
            if isServingOnlyLine(line) {
                decisions.append(OCRDebugParserDecision(
                    rawRow: line, decision: "serving",
                    reason: "matches serving-only pattern", extractedName: nil, amount: nil, unit: nil
                ))
                continue
            }
            if shouldSkip(line) {
                decisions.append(OCRDebugParserDecision(
                    rawRow: line, decision: "skipped",
                    reason: "matches non-ingredient skip rule", extractedName: nil, amount: nil, unit: nil
                ))
                continue
            }
            if let probiotic = probioticEntry(from: line) {
                decisions.append(OCRDebugParserDecision(
                    rawRow: line, decision: "probiotic",
                    reason: "CFU match + scientific name",
                    extractedName: "\(probiotic.genus) \(probiotic.species)",
                    amount: probiotic.cfuBillions, unit: "B CFU"
                ))
            } else if let nutrient = nutrientEntry(from: line) {
                decisions.append(OCRDebugParserDecision(
                    rawRow: line, decision: "nutrient",
                    reason: "amount match accepted",
                    extractedName: nutrient.displayName,
                    amount: nutrient.amount,
                    unit: nutrient.unit.rawValue
                ))
            } else {
                let amtNil = amountMatch(in: line) == nil
                decisions.append(OCRDebugParserDecision(
                    rawRow: line, decision: "unresolved",
                    reason: amtNil ? "no amount found" : "name rejected by gatekeeping",
                    extractedName: nil, amount: nil, unit: nil
                ))
            }
        }
        return decisions
    }
}
#endif
