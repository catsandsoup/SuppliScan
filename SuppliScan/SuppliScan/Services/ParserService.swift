// ParserService.swift
// SuppliScan
//
// Deterministic OCR text parser. It never uses AI and never silently drops
// unclassified content; unclear lines become RawLine entries for review.

import Foundation

nonisolated struct ParserService: Sendable {
    private let aliasesByVariant: [String: String]
    private let formsByVariant: [String: String]
    private let semanticProfilesByCanonical: [String: NutritionSemanticProfile]
    private let botanicalCanonicalByVariant: [String: String]

    init(
        aliasesByVariant: [String: String] = [:],
        formsByVariant: [String: String] = [:],
        semanticProfilesByCanonical: [String: NutritionSemanticProfile] = [:],
        botanicalCanonicalByVariant: [String: String] = [:]
    ) {
        self.aliasesByVariant = aliasesByVariant.reduce(into: [:]) { result, pair in
            result[Self.normalizedKey(pair.key)] = pair.value
        }
        self.formsByVariant = formsByVariant.reduce(into: [:]) { result, pair in
            result[Self.normalizedKey(pair.key)] = pair.value
        }
        self.semanticProfilesByCanonical = semanticProfilesByCanonical.reduce(into: [:]) { result, pair in
            result[Self.normalizedKey(pair.key)] = pair.value
        }
        self.botanicalCanonicalByVariant = botanicalCanonicalByVariant.reduce(into: [:]) { result, pair in
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

        var forms: [String: String] = [:]
        var semanticProfiles: [String: NutritionSemanticProfile] = [:]
        var botanicalAliases: [String: String] = [:]

        if let lexicon = try? NutritionLexicon.load(bundle: bundle) {
            for (variant, canonical) in lexicon.aliasesByVariant {
                aliases[variant] = canonical
            }
            for (variant, canonical) in lexicon.botanicalAliasesByVariant {
                botanicalAliases[variant] = canonical
            }
            forms = lexicon.formsByVariant
            semanticProfiles = lexicon.semanticProfilesByCanonical
        }

        if let knowledge = try? SupplementKnowledgeService.load(bundle: bundle) {
            for (variant, canonical) in knowledge.botanicalCanonicalByVariant {
                botanicalAliases[variant] = canonical
            }
        }

        return ParserService(
            aliasesByVariant: aliases,
            formsByVariant: forms,
            semanticProfilesByCanonical: semanticProfiles,
            botanicalCanonicalByVariant: botanicalAliases
        )
    }

    /// Parses raw OCR text into typed label entries and an optional serving size.
    func parse(_ rawText: String) -> ParseResult {
        parse(rawText, reviewFlagsByLine: [:])
    }

    /// Parses OCR output while propagating uncertainty from the recognition layer.
    func parse(_ ocrResult: OCRResult) -> ParseResult {
        let reviewFlags = ocrResult.lines.reduce(into: [String: [ReviewFlag]]()) { result, line in
            let key = Self.normalizedKey(line.text)
            guard !key.isEmpty else { return }
            result[key] = appended(Self.reviewFlags(from: line.qualityFlags), to: result[key] ?? [])
        }
        return parse(ocrResult.rawText, reviewFlagsByLine: reviewFlags)
    }

    private func parse(_ rawText: String, reviewFlagsByLine: [String: [ReviewFlag]]) -> ParseResult {
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
            let ocrFlags = reviewFlags(for: line, in: reviewFlagsByLine)

            if let probiotic = probioticEntry(from: line) {
                entries.append(appendingReviewFlags(ocrFlags, to: .probiotic(probiotic)))
            } else if let herbal = herbalEntry(from: line) {
                entries.append(appendingReviewFlags(ocrFlags, to: .herbal(herbal)))
            } else if let nutrient = nutrientEntry(from: line) {
                entries.append(appendingReviewFlags(ocrFlags, to: .nutrient(UnitConversionService.convertIfNeeded(nutrient))))
            } else {
                entries.append(.unresolved(RawLine(text: line, lineNumber: index + 1)))
            }
        }

        return ParseResult(entries: entries, extractedServing: extractedServing)
    }

    private func reviewFlags(for line: String, in reviewFlagsByLine: [String: [ReviewFlag]]) -> [ReviewFlag] {
        let key = Self.normalizedKey(line)
        if let exact = reviewFlagsByLine[key] {
            return exact
        }

        return reviewFlagsByLine.reduce(into: []) { result, pair in
            guard !pair.key.isEmpty else { return }
            if key.contains(pair.key) || pair.key.contains(key) {
                result = appended(pair.value, to: result)
            }
        }
    }

    private static func reviewFlags(from ocrFlags: Set<OCRLineQualityFlag>) -> [ReviewFlag] {
        var flags: [ReviewFlag] = []
        if ocrFlags.contains(.lowConfidence)
            || ocrFlags.contains(.lowConfidenceAccepted) {
            flags.append(.ocrUncertain)
        }
        if ocrFlags.contains(.conflictingCandidates) {
            flags.append(.ocrConflict)
        }
        if ocrFlags.contains(.singlePassEvidence) {
            flags.append(.ocrSinglePassEvidence)
        }
        return flags
    }

    private func appendingReviewFlags(_ flags: [ReviewFlag], to entry: LabelEntry) -> LabelEntry {
        guard !flags.isEmpty else { return entry }
        switch entry {
        case .nutrient(var nutrient):
            nutrient.reviewFlags = appended(flags, to: nutrient.reviewFlags)
            return .nutrient(nutrient)
        case .herbal(var herbal):
            herbal.reviewFlags = appended(flags, to: herbal.reviewFlags)
            return .herbal(herbal)
        case .probiotic(var probiotic):
            probiotic.reviewFlags = appended(flags, to: probiotic.reviewFlags)
            return .probiotic(probiotic)
        case .unresolved:
            return entry
        }
    }

    /// Prepares OCR lines for deterministic parsing while preserving visible label order.
    private func ingredientCandidateLines(from rawLines: [String]) -> [String] {
        let reconstructedLines = reconstructedColumnarRows(rawLines)
        let mergedLines = mergedContinuationLines(
            deduplicatedAdjacentVariantLines(
                mergedTwoColumnLines(reconstructedLines)
            )
        )
        return repairedDisplacedCompoundEquivalentRows(mergedLines)
    }

    /// Repairs common Vision reading-order failures on dense supplement tables where
    /// the left ingredient column and right amount column are interleaved.
    private func reconstructedColumnarRows(_ lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let current = lines[i]

            if i + 4 < lines.count,
               isKnownNutrientNameOnlyLine(current),
               isKnownNutrientNameOnlyLine(lines[i + 1]),
               let firstEquivalent = leadingEquivalentLine(in: lines[i + 2]),
               equivalentLine(firstEquivalent, targets: current),
               isAmountOnlyLine(lines[i + 3]),
               let secondEquivalent = leadingEquivalentLine(in: lines[i + 4]),
               equivalentLine(secondEquivalent, targets: lines[i + 1]) {
                result.append(compoundEquivalentRow(compoundName: current, equivalent: firstEquivalent, compoundAmountLine: lines[i + 3]))
                result.append(compoundEquivalentRow(compoundName: lines[i + 1], equivalent: secondEquivalent, compoundAmountLine: nil))
                i += 5
                continue
            }

            if i + 3 < lines.count,
               isKnownNutrientNameOnlyLine(current),
               isKnownNutrientNameOnlyLine(lines[i + 1]),
               isAmountOnlyLine(lines[i + 2]),
               let firstEquivalent = leadingEquivalentLine(in: lines[i + 3]),
               equivalentLine(firstEquivalent, targets: current) {
                result.append("\(lines[i + 1]) \(lines[i + 2])")
                result.append(compoundEquivalentRow(compoundName: current, equivalent: firstEquivalent, compoundAmountLine: nil))
                i += 4
                continue
            }

            if i + 2 < lines.count,
               latinIdentity(from: current) != nil,
               isStandardisationLine(lines[i + 1]),
               isExtractEquivalentRowWithoutIdentity(lines[i + 2]) {
                result.append("\(current) \(lines[i + 2]) \(lines[i + 1])")
                i += 3
                continue
            }

            if i + 1 < lines.count,
               isExtractEquivalentRowWithoutIdentity(current),
               latinIdentity(from: lines[i + 1]) != nil {
                result.append("\(lines[i + 1]) \(current)")
                i += 2
                continue
            }

            if i + 1 < lines.count,
               latinIdentity(from: current) != nil,
               isExtractEquivalentRowWithoutIdentity(lines[i + 1]) {
                result.append("\(current) \(lines[i + 1])")
                i += 2
                continue
            }

            if i + 1 < lines.count,
               let split = splitKnownNutrientPairWithAmount(current),
               isAmountOnlyLine(lines[i + 1]) {
                result.append("\(split.firstName) \(split.firstAmount)")
                result.append("\(split.secondName) \(lines[i + 1])")
                i += 2
                continue
            }

            result.append(current)
            i += 1
        }

        return result
    }

    private func isExtractEquivalentRowWithoutIdentity(_ line: String) -> Bool {
        let lower = line.lowercased()
        guard lower.contains("extract") || lower.contains("concentrate") else { return false }
        guard lower.contains("equiv") || lower.contains("equivalent") else { return false }
        return botanicalIdentity(from: line) == nil && latinIdentity(from: line) == nil
    }

    private func isKnownNutrientNameOnlyLine(_ line: String) -> Bool {
        guard isNameOnlyLine(line) else { return false }
        let name = extractNameAndForm(from: line).name
        return isKnownNutrientName(name)
    }

    private func splitKnownNutrientPairWithAmount(_ line: String) -> (firstName: String, secondName: String, firstAmount: String)? {
        guard let amountMatch = amountMatch(in: line) else { return nil }
        let prefix = String(line[..<amountMatch.range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let words = Self.normalizedKey(prefix).split(separator: " ").map(String.init)
        guard words.count >= 2 else { return nil }

        for splitIndex in 1..<words.count {
            let first = words[..<splitIndex].joined(separator: " ")
            let second = words[splitIndex...].joined(separator: " ")
            guard isKnownNutrientName(first), isKnownNutrientName(second) else { continue }
            return (
                firstName: canonicalName(for: first),
                secondName: canonicalName(for: second),
                firstAmount: String(line[amountMatch.range])
            )
        }

        return nil
    }

    private func leadingEquivalentLine(in line: String) -> LeadingEquivalentLine? {
        guard let match = firstMatch(
            in: line,
            pattern: #"(?i)^\(?\s*(?:equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b(?:\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b)?"#
        ) else { return nil }

        return LeadingEquivalentLine(
            activeName: match.captures[0],
            activeAmountText: match.captures[1],
            activeUnitText: match.captures[2],
            compoundAmountText: match.captures.count > 3 && !match.captures[3].isEmpty ? match.captures[3] : nil,
            compoundUnitText: match.captures.count > 4 && !match.captures[4].isEmpty ? match.captures[4] : nil
        )
    }

    private func equivalentLine(_ line: LeadingEquivalentLine, targets compoundName: String) -> Bool {
        let compoundCandidate = extractNameAndForm(from: compoundName).name
        return Self.normalizedKey(canonicalName(for: line.activeName))
            == Self.normalizedKey(canonicalName(for: compoundCandidate))
    }

    private func compoundEquivalentRow(
        compoundName: String,
        equivalent: LeadingEquivalentLine,
        compoundAmountLine: String?
    ) -> String {
        let compoundAmount: String
        if let compoundAmountLine {
            compoundAmount = compoundAmountLine
        } else if let amountText = equivalent.compoundAmountText,
                  let unitText = equivalent.compoundUnitText {
            compoundAmount = "\(amountText) \(unitText)"
        } else {
            compoundAmount = ""
        }

        let equivalentText = "equivalent to \(equivalent.activeName) \(equivalent.activeAmountText) \(equivalent.activeUnitText)"
        return [compoundName, compoundAmount, equivalentText]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
    }

    private func repairedDisplacedCompoundEquivalentRows(_ lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let current = lines[i]

            if i + 2 < lines.count,
               isKnownNutrientNameOnlyLine(current),
               let displaced = displacedCompoundEquivalentLine(in: lines[i + 1]),
               equivalentLine(displaced.equivalent, targets: current),
               let amountPrefixed = amountPrefixedEquivalentLine(in: lines[i + 2]),
               equivalentLine(amountPrefixed.equivalent, targets: displaced.compoundName) {
                result.append(
                    compoundEquivalentRow(
                        compoundName: current,
                        equivalent: displaced.equivalent,
                        compoundAmountLine: amountPrefixed.compoundAmountLine
                    )
                )
                result.append(
                    compoundEquivalentRow(
                        compoundName: displaced.compoundName,
                        equivalent: amountPrefixed.equivalent,
                        compoundAmountLine: nil
                    )
                )
                i += 3
                continue
            }

            result.append(current)
            i += 1
        }

        return result
    }

    private func displacedCompoundEquivalentLine(
        in line: String
    ) -> (compoundName: String, equivalent: LeadingEquivalentLine)? {
        guard let range = line.range(
            of: #"(?i)\b(?:equiv\.?|equivalent(?:\s+to)?)\s+"#,
            options: .regularExpression
        ) else { return nil }

        let compoundName = String(line[..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard isKnownNutrientName(extractNameAndForm(from: compoundName).name),
              let equivalent = leadingEquivalentLine(in: String(line[range.lowerBound...]))
        else { return nil }

        return (compoundName, equivalent)
    }

    private func amountPrefixedEquivalentLine(
        in line: String
    ) -> (compoundAmountLine: String, equivalent: LeadingEquivalentLine)? {
        guard let match = firstMatch(
            in: line,
            pattern: #"(?i)^(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b\s+((?:equiv\.?|equivalent(?:\s+to)?).+)$"#
        ) else { return nil }

        let amountLine = "\(match.captures[0]) \(match.captures[1])"
        guard let equivalent = leadingEquivalentLine(in: match.captures[2]) else {
            return nil
        }
        return (amountLine, equivalent)
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
                if isNameOnlyLine(current) && isEquivalentContinuation(next) && !isGenericDerivationLine(current) {
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
                if amountMatch(in: current) != nil,
                   isPureContinuationLine(next),
                   !shouldKeepEquivalentContinuationSeparate(after: current, next: next) {
                    result.append(current + " " + next)
                    i += 2
                    continue
                }
                // Merge "standardised to contain X Ymg" into the preceding ingredient line so
                // herbalEntry() can capture it as HerbalStandardisation (otherwise shouldSkip drops it).
                if amountMatch(in: current) != nil, isStandardisationLine(next) {
                    result.append(current + " " + next)
                    i += 2
                    continue
                }
                if amountMatch(in: current) != nil, isParentheticalFormLine(next) {
                    result.append(current + " " + next)
                    i += 2
                    continue
                }
                if amountMatch(in: current) != nil, isRetinolEquivalentQualifier(next) {
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

    private func deduplicatedAdjacentVariantLines(_ lines: [String]) -> [String] {
        var result: [String] = []

        for line in lines {
            guard let previous = result.last, areAdjacentOCRVariantDuplicates(previous, line) else {
                result.append(line)
                continue
            }

            result[result.count - 1] = preferredOCRVariantLine(previous, line)
        }

        return result
    }

    private func areAdjacentOCRVariantDuplicates(_ lhs: String, _ rhs: String) -> Bool {
        if ocrVariantKey(lhs) == ocrVariantKey(rhs) {
            return true
        }
        guard let lhsEquivalent = equivalentActiveDuplicateKey(lhs),
              let rhsEquivalent = equivalentActiveDuplicateKey(rhs) else {
            return false
        }
        return lhsEquivalent == rhsEquivalent
    }

    private func preferredOCRVariantLine(_ lhs: String, _ rhs: String) -> String {
        let lhsScore = equivalentActiveObservedNameScore(lhs)
        let rhsScore = equivalentActiveObservedNameScore(rhs)
        if lhsScore != rhsScore {
            return lhsScore > rhsScore ? lhs : rhs
        }

        let lhsUnit = amountMatch(in: lhs)?.unit
        let rhsUnit = amountMatch(in: rhs)?.unit
        if lhsUnit != .unknown, rhsUnit == .unknown { return lhs }
        if rhsUnit != .unknown, lhsUnit == .unknown { return rhs }
        return lhs.count >= rhs.count ? lhs : rhs
    }

    private func ocrVariantKey(_ line: String) -> String {
        replacing(
            pattern: #"(?<=\d)l\s*u\b"#,
            in: Self.normalizedKey(line),
            with: "iu"
        )
    }

    private func equivalentActiveDuplicateKey(_ line: String) -> String? {
        guard isStandaloneEquivalentActiveLine(line) else { return nil }
        let cleanedLine = cleanedEquivalentText(line)
        guard let amountMatch = degradedMilligramAmountMatch(in: cleanedLine) ?? amountMatch(in: cleanedLine),
              let amount = amountMatch.amount else {
            return nil
        }

        let prefix = String(cleanedLine[..<amountMatch.range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let activeName = equivalentActiveNameAndForm(from: prefix, sourceLine: line).name
        let roundedAmount = (amount * 1_000).rounded() / 1_000
        return [
            Self.normalizedKey(canonicalName(for: activeName)),
            String(roundedAmount),
            amountMatch.unit.rawValue,
        ].joined(separator: "|")
    }

    private func equivalentActiveObservedNameScore(_ line: String) -> Int {
        guard isStandaloneEquivalentActiveLine(line) else { return 0 }
        let cleanedLine = cleanedEquivalentText(line)
        let amount = degradedMilligramAmountMatch(in: cleanedLine) ?? amountMatch(in: cleanedLine)
        let prefix = amount.map { String(cleanedLine[..<$0.range.lowerBound]) } ?? cleanedLine
        let observedName = extractNameAndForm(from: prefix).name
        let key = Self.normalizedKey(observedName)
        if aliasesByVariant[key] != nil || formsByVariant[key] != nil {
            return 2
        }
        return key.isEmpty ? 0 : 1
    }

    private func shouldKeepEquivalentContinuationSeparate(after current: String, next: String) -> Bool {
        guard isEquivalentContinuation(next) else { return false }
        if isStandaloneEquivalentActiveLine(current), isStandaloneEquivalentActiveLine(next) {
            return true
        }
        if isGenericDerivationLine(current) {
            return true
        }
        return herbalEntry(from: current) != nil
    }

    /// True when a line is a herbal standardisation note that should be merged into the preceding ingredient line.
    private func isStandardisationLine(_ line: String) -> Bool {
        let lower = line
            .trimmingCharacters(in: CharacterSet(charactersIn: " ()\t\n\r"))
            .lowercased()
        return lower.hasPrefix("standardised to")   // AU/UK spelling
            || lower.hasPrefix("standardized to")   // US spelling
            || lower.hasPrefix("calc. as")
            || lower.hasPrefix("calculated as")
    }

    private func isStandaloneHerbalNoteLine(_ line: String) -> Bool {
        let lower = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return isStandardisationLine(line)
            || lower.hasPrefix("dry equivalent")
            || lower.hasPrefix("fresh equivalent")
            || isGenericDerivationLine(line)
    }

    private func isGenericDerivationLine(_ line: String) -> Bool {
        let lower = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return amountMatch(in: lower) == nil
            && (lower.hasPrefix("derived from dry") || lower.hasPrefix("derived from fresh"))
    }

    private func isRetinolEquivalentQualifier(_ line: String) -> Bool {
        let key = Self.normalizedKey(line)
        return key == "retinol equivalents" || key == "retinol equivalent"
    }

    private func isParentheticalFormLine(_ line: String) -> Bool {
        line.range(
            of: #"(?i)^\(?\s*(?:as|from)\s+[^)]+\)?$"#,
            options: .regularExpression
        ) != nil
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

        if let name = probioticName(from: prefix) {
            return ProbioticEntry(
                genus: name.genus,
                species: name.species,
                strain: name.strain,
                cfuBillions: cfuMatch.cfuBillions,
                isTotalLine: isTotalLine(line),
                reviewFlags: isTotalLine(line) ? [.totalLineAmbiguous] : []
            )
        }

        // Two-column label format uses abbreviated genera: "L. rhamnosus", "B. longum"
        if let name = abbreviatedProbioticName(from: prefix) {
            return ProbioticEntry(
                genus: name.genus,
                species: name.species,
                strain: name.strain,
                cfuBillions: cfuMatch.cfuBillions,
                isTotalLine: isTotalLine(line),
                reviewFlags: isTotalLine(line) ? [.totalLineAmbiguous] : []
            )
        }

        return nil
    }

    private func abbreviatedProbioticName(from text: String) -> (genus: String, species: String, strain: String?)? {
        let abbreviationMap: [String: String] = [
            "l": "Lactobacillus", "b": "Bifidobacterium",
            "s": "Streptococcus",  "e": "Enterococcus",
        ]
        guard let match = firstMatch(
            in: text,
            pattern: #"(?i)\b([A-Za-z])\.\s+([a-z][a-z-]+(?:\s+(?:ssp\.|subsp\.)\s+[a-z][a-z-]+)?)\b\s*([\w\s\-]*)"#
        ) else { return nil }

        let abbrev = match.captures[0].lowercased()
        guard let genus = abbreviationMap[abbrev] else { return nil }
        let species = match.captures[1].lowercased()
        let strain = match.captures.count > 2 ? normalizedStrain(match.captures[2]) : nil
        return (genus, species, strain)
    }

    private func herbalEntry(from line: String) -> HerbalEntry? {
        let lower = line.lowercased()

        // Must contain extract/concentrate/herb keywords — key discriminator from nutrients
        let herbalKeywords = ["extract", "concentrate", "tincture", "dried herb", "dry herb"]
        guard herbalKeywords.contains(where: { lower.contains($0) }) else { return nil }

        guard let identity = botanicalIdentity(from: line) ?? latinIdentity(from: line) else { return nil }

        // Reject nutrient compounds that start with a capitalised word (Calcium citrate etc.)
        let genus = identity.latinName.split(separator: " ").first.map(String.init) ?? ""
        let knownNutrientPrefixes: Set<String> = [
            "Calcium", "Magnesium", "Zinc", "Iron", "Copper", "Sodium", "Potassium",
            "Riboflavin", "Thiamine", "Pyridoxal", "Levomefolate", "Mecobalamin",
            "Coenzyme", "Alpha", "Ferrous", "Ferric", "Vitamin", "Chromium",
            "Citrus",
        ]
        guard !knownNutrientPrefixes.contains(genus) else { return nil }

        // Extract type from keywords present in the line
        let extractType: ExtractType
        if lower.contains("soft concentrate") || lower.contains("soft extract") {
            extractType = .softConcentrate
        } else if lower.contains("dry concentrate") || lower.contains("dry extract")
                  || lower.contains("dried extract") || lower.contains("fruit extract")
                  || lower.contains("seed extract") || lower.contains("stem extract")
                  || lower.contains("leaf extract") || lower.contains("root extract")
                  || lower.contains("berry extract") || lower.contains("flower extract") {
            extractType = .dryConcExtract
        } else if lower.contains("dried herb") || lower.contains("dried powder")
                  || lower.contains("dry herb") {
            extractType = .driedHerb
        } else if lower.contains("tincture") {
            extractType = .tincture
        } else {
            extractType = .unknown
        }

        // Split on "equiv." to separate extract amount from dry-equivalent amount
        let equivSplit = line.range(
            of: #"(?i)\bequiv\.?\b|\bequivalent\b"#,
            options: .regularExpression
        )

        let extractAmount: Double?
        let extractUnit: NutrientUnit?
        let dryEquivalentAmount: Double?
        let dryEquivalentUnit: NutrientUnit?

        if let split = equivSplit {
            let before = String(line[..<split.lowerBound])
            let after  = String(line[split.upperBound...])
            let beforeMatch = amountMatch(in: before)
            let afterMatch  = amountMatch(in: after)
            extractAmount       = beforeMatch?.amount
            extractUnit         = beforeMatch?.unit
            dryEquivalentAmount = afterMatch?.amount
            dryEquivalentUnit   = afterMatch?.unit
        } else {
            let match = amountMatch(in: line)
            extractAmount       = match?.amount
            extractUnit         = match?.unit
            dryEquivalentAmount = nil
            dryEquivalentUnit   = nil
        }

        // Require at least an extract amount — bare name lines are not useful
        guard extractAmount != nil else { return nil }

        return HerbalEntry(
            latinName: identity.latinName,
            commonName: identity.commonName,
            extractType: extractType,
            extractAmount: extractAmount,
            extractUnit: extractUnit,
            dryEquivalentAmount: dryEquivalentAmount,
            dryEquivalentUnit: dryEquivalentUnit,
            standardisation: parseStandardisation(from: line),
            reviewFlags: identity.inferred ? [.canonicalNameInferred] : []
        )
    }

    private func botanicalIdentity(from line: String) -> (latinName: String, commonName: String?, inferred: Bool)? {
        let lineKey = Self.normalizedKey(line)
        let nonIdentityFragments = ["standardised", "standardized", "equivalent", "calculated", "contain silicon"]
        let matches = botanicalCanonicalByVariant.compactMap { variantKey, canonical -> (String, String)? in
            guard !variantKey.isEmpty else { return nil }
            guard nonIdentityFragments.contains(where: { variantKey.contains($0) }) == false else { return nil }
            guard lineKey == variantKey || lineKey.contains(variantKey) else { return nil }
            return (variantKey, canonical)
        }

        guard let match = matches.max(by: { $0.0.count < $1.0.count }) else { return nil }
        let commonName = match.0 == Self.normalizedKey(match.1) ? nil : titleCased(match.0)
        return (latinName: match.1, commonName: commonName, inferred: commonName != nil)
    }

    private func latinIdentity(from line: String) -> (latinName: String, commonName: String?, inferred: Bool)? {
        guard let match = firstMatch(
            in: line,
            pattern: #"^([A-Z][a-z]{2,})\s+([a-z][a-z-]+)(?:\s+ssp\.\s+([a-z]+))?(?:\s+\(([^)]+)\))?"#
        ) else { return nil }

        let species = match.captures[1].lowercased()
        let rejectedSpeciesWords: Set<String> = [
            "aerial", "berry", "bulb", "concentrate", "dry", "dried", "extract",
            "flower", "fruit", "herb", "leaf", "liquid", "powder", "rhizome",
            "root", "seed", "soft", "stem", "whole"
        ]
        guard !rejectedSpeciesWords.contains(species) else { return nil }

        var latinName = "\(match.captures[0]) \(match.captures[1])"
        if match.captures.count > 2, !match.captures[2].isEmpty {
            latinName += " ssp. \(match.captures[2])"
        }
        let commonName = match.captures.count > 3 && !match.captures[3].isEmpty ? match.captures[3] : nil
        return (latinName: latinName, commonName: commonName, inferred: false)
    }

    /// Parses a HerbalStandardisation from a line that contains a standardisation clause.
    /// Handles "standardised/standardized to [contain] COMPOUND AMOUNTunit" and "calc[ulated]. as COMPOUND AMOUNTunit".
    private func parseStandardisation(from line: String) -> HerbalStandardisation? {
        let lower = line
            .lowercased()
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")

        // "standardised/standardized to [contain] silicon 14mg"
        if let match = firstMatch(
            in: lower,
            pattern: #"standardi[sz]ed\s+to\s+(?:contain\s+)?([a-z][a-z\s-]*?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b"#
        ), match.captures.count >= 3 {
            let compound = match.captures[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var flags: [ReviewFlag] = []
            if let amount = decimalAmount(match.captures[1], flags: &flags) {
                let unit = unit(from: match.captures[2])
                return HerbalStandardisation(compound: compound, calculatedAs: nil, amount: amount, unit: unit)
            }
        }

        // "calc. as silybin 140mg" / "calculated as silybin 140mg"
        if let match = firstMatch(
            in: lower,
            pattern: #"calc(?:ulated)?\.?\s+as\s+([a-z][a-z\s-]*?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b"#
        ), match.captures.count >= 3 {
            let compound = match.captures[0].trimmingCharacters(in: .whitespacesAndNewlines)
            var flags: [ReviewFlag] = []
            if let amount = decimalAmount(match.captures[1], flags: &flags) {
                let unit = unit(from: match.captures[2])
                return HerbalStandardisation(compound: compound, calculatedAs: nil, amount: amount, unit: unit)
            }
        }

        return nil
    }

    private func nutrientEntry(from line: String) -> NutrientEntry? {
        if let nutrient = equivalentActiveOnlyEntry(from: line) {
            return nutrient
        }

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

    private func equivalentActiveOnlyEntry(from line: String) -> NutrientEntry? {
        guard isStandaloneEquivalentActiveLine(line) else { return nil }
        let cleanedLine = cleanedEquivalentText(line)
        guard let amountMatch = degradedMilligramAmountMatch(in: cleanedLine) ?? amountMatch(in: cleanedLine) else {
            return nil
        }

        let prefix = String(cleanedLine[..<amountMatch.range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let activeNameAndForm = equivalentActiveNameAndForm(from: prefix, sourceLine: line)
        guard !activeNameAndForm.name.isEmpty else { return nil }
        guard !shouldRejectCandidateName(activeNameAndForm.name, line: line, unit: amountMatch.unit) else {
            return nil
        }

        let canonical = canonicalName(for: activeNameAndForm.name)
        let inferred = canonical != activeNameAndForm.name
        let flags = appended(
            semanticFlags(for: canonical, unit: amountMatch.unit),
            to: appended(
                inferred ? [.canonicalNameInferred] : [],
                to: appended(amountMatch.flags, to: [.extractEquivalent])
            )
        )

        return NutrientEntry(
            canonicalName: canonical,
            displayName: titleCased(activeNameAndForm.displayName),
            form: activeNameAndForm.form,
            amount: amountMatch.amount,
            unit: amountMatch.unit,
            isElemental: true,
            reviewFlags: flags
        )
    }

    private func equivalentActiveNameAndForm(
        from prefix: String,
        sourceLine: String
    ) -> (name: String, displayName: String, form: String?) {
        let nameAndForm = extractNameAndForm(from: prefix)
        let sourceKey = Self.normalizedKey(sourceLine)

        if let parenthetical = nameAndForm.form, isKnownNutrientName(parenthetical) {
            let form = formName(for: nameAndForm.name) ?? nameAndForm.name.lowercased()
            return (parenthetical, nameAndForm.name, form)
        }

        let inferredForm: String?
        if Self.normalizedKey(nameAndForm.name) == "vitamin a",
           sourceKey.contains("retinol equivalent") {
            inferredForm = "retinol equivalents"
        } else {
            inferredForm = nameAndForm.form ?? formName(for: nameAndForm.name)
        }

        return (nameAndForm.name, nameAndForm.name, inferredForm)
    }

    private func isKnownNutrientName(_ name: String) -> Bool {
        let key = Self.normalizedKey(name)
        return aliasesByVariant[key] != nil || key.hasPrefix("vitamin ")
    }

    private func makeNutrientEntry(
        from line: String,
        amountMatch: AmountMatch?,
        extraFlags: [ReviewFlag]
    ) -> NutrientEntry? {
        let prefix = amountMatch.map { String(line[..<$0.range.lowerBound]) } ?? line
        let suffix = amountMatch.map { String(line[$0.range.upperBound...]) } ?? ""
        let nameAndForm = extractNameAndForm(from: prefix)
        guard !nameAndForm.name.isEmpty else { return nil }
        guard !shouldRejectCandidateName(nameAndForm.name, line: line, unit: amountMatch?.unit) else { return nil }

        let canonical = canonicalName(for: nameAndForm.name)
        let inferred = canonical != nameAndForm.name
        let unit = amountMatch?.unit ?? .unknown
        let form = trailingParentheticalForm(from: suffix) ?? nameAndForm.form ?? formName(for: nameAndForm.name)
        let totalFlags: [ReviewFlag] = isTotalLine(line) ? [.totalLineAmbiguous] : []
        let flags = appended(
            semanticFlags(for: canonical, unit: unit),
            to: appended(
                inferred ? [.canonicalNameInferred] : [],
                to: appended(totalFlags, to: appended(amountMatch?.flags ?? [], to: extraFlags))
            )
        )

        return NutrientEntry(
            canonicalName: canonical,
            displayName: titleCased(nameAndForm.name),
            form: form,
            amount: amountMatch?.amount,
            unit: unit,
            isElemental: line.localizedCaseInsensitiveContains("elemental"),
            isTotalLine: isTotalLine(line),
            reviewFlags: flags
        )
    }

    private func compoundEquivalentEntry(from line: String) -> NutrientEntry? {
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)^(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b\s*\(?\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b\)?"#
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
            pattern: #"(?i)^(.+?)\s+(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b"#
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
            pattern: #"(?i)^(.+?)\s+\(\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b\s*\)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b"#
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
            pattern: #"(?i)^\(\s*(?:providing|equiv\.?|equivalent(?:\s+to)?)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\s*\)\s+(.+?)\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g)\b"#
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

        // Pattern 5: SERVING_DESC provides AMOUNT UNIT ACTIVE_NAME
        // e.g. "1 level scoop provides 1g N-Acetyl-Cysteine"
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)^(.+?)\s+provides\s+(\d+(?:[\.,]\d+)?)\s*(mg|mcg|micrograms?|μg|µg|ug|g|iu)\b\s+(.+?)$"#
        ) {
            return makeCompoundEquivalentEntry(
                compoundName: match.captures[0],
                compoundAmountText: nil,
                compoundUnitText: nil,
                activeNameText: match.captures[3],
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
        let form = compoundForm(from: compoundBaseName, canonicalName: canonical)
            ?? activeNameAndForm.form
            ?? formName(for: activeNameAndForm.name)
        let activeUnit = unit(from: activeUnitText)

        let amount = decimalAmount(activeAmountText, flags: &activeFlags)
        let compoundAmount = compoundAmountText.flatMap { decimalAmount($0, flags: &activeFlags) }
        let totalFlags: [ReviewFlag] = isTotalLine(sourceLine) ? [.totalLineAmbiguous] : []
        let flags = appended(
            semanticFlags(for: canonical, unit: activeUnit),
            to: appended(
                inferred ? [.canonicalNameInferred] : [],
                to: appended(totalFlags, to: appended(activeFlags, to: [.extractEquivalent]))
            )
        )

        return NutrientEntry(
            canonicalName: canonical,
            displayName: titleCased(activeNameAndForm.name),
            form: form,
            amount: amount,
            unit: activeUnit,
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

    private func trailingParentheticalForm(from text: String) -> String? {
        guard let match = firstMatch(
            in: text,
            pattern: #"(?i)\(\s*(?:as|from)\s+([^)]+)\)"#
        ) else { return nil }

        return normalizedForm(match.captures[0])
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
        let key = Self.normalizedKey(text)
        if key == "fat total" || key == "total fat" {
            return "Total Fat"
        }

        return replacing(pattern: #"(?i)\b(total|elemental|contains|per|each|tablet|capsule)\b"#, in: text, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func amountMatch(in line: String) -> AmountMatch? {
        let normalized = line.replacingOccurrences(of: "I.U.", with: "IU", options: .caseInsensitive)

        if let match = firstMatch(
            in: normalized,
            pattern: #"(?i)<\s*1\s*(mg|mcg|micrograms?|μg|µg|ug|g|iu)\b"#
        ) {
            return AmountMatch(amount: 0.5, unit: unit(from: match.captures[0]), flags: [.subOneAmount], range: match.range)
        }

        if normalized.localizedCaseInsensitiveContains("trace"),
           let match = firstMatch(in: normalized, pattern: #"(?i)\btrace\s*(mg|mcg|micrograms?|μg|µg|ug|g|iu)\b"#) {
            return AmountMatch(amount: 0, unit: unit(from: match.captures[0]), flags: [.traceAmount], range: match.range)
        }

        if let match = firstMatch(
            in: normalized,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*[-–]\s*\d+(?:[\.,]\d+)?\s*(mg|mcg|micrograms?|μg|µg|ug|g|iu)\b"#
        ) {
            var flags: [ReviewFlag] = [.rangeAmount]
            let amount = decimalAmount(match.captures[0], flags: &flags)
            return AmountMatch(amount: amount, unit: unit(from: match.captures[1]), flags: flags, range: match.range)
        }

        if let match = firstMatch(
            in: normalized,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*(mg\s+(?:ne|re|rae|dfe)|mcg|micrograms?|μg|µg|ug|mg|g|iu)\b"#
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

    private func degradedMilligramAmountMatch(in line: String) -> AmountMatch? {
        guard let match = firstMatch(
            in: line,
            pattern: #"(?i)(\d+(?:[\.,]\d+|\s+\d)?)\s*m\b"#
        ) else { return nil }

        var flags: [ReviewFlag] = [.unitUnknown, .ocrUncertain]
        let rawAmount = match.captures[0]
        let amountText: String
        if rawAmount.range(of: #"^\d+\s+\d$"#, options: .regularExpression) != nil {
            amountText = rawAmount.replacingOccurrences(of: " ", with: ".")
        } else {
            amountText = rawAmount
        }

        return AmountMatch(
            amount: decimalAmount(amountText, flags: &flags),
            unit: .mg,
            flags: flags,
            range: match.range
        )
    }

    private func cfuMatch(in line: String) -> CFUMatch? {
        // Primary: "X billion/million CFU" (explicit CFU suffix)
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s*(billion|million)?\s*cfu\b"#
        ) {
            var flags: [ReviewFlag] = []
            guard let amount = decimalAmount(match.captures[0], flags: &flags) else { return nil }
            let scale = match.captures.count > 1 ? match.captures[1].lowercased() : ""
            let cfuBillions: Double = scale == "million" ? amount / 1_000 : amount
            return CFUMatch(cfuBillions: cfuBillions, range: match.range)
        }

        // Fallback: "X Billion" / "X Million" alone — two-column probiotic label format
        // where "CFU" only appears in the column header, not on each row.
        if let match = firstMatch(
            in: line,
            pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s+(billion|million)\b"#
        ) {
            var flags: [ReviewFlag] = []
            guard let amount = decimalAmount(match.captures[0], flags: &flags) else { return nil }
            let cfuBillions: Double = match.captures[1].lowercased() == "million" ? amount / 1_000 : amount
            return CFUMatch(cfuBillions: cfuBillions, range: match.range)
        }

        return nil
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
        if normalized == "mcg" || normalized == "ug" || normalized == "microgram" || normalized == "micrograms" { return .mcg }
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

        // Scoop: handle "N level scoop" / "N heaping scoop" where a descriptor word
        // sits between the number and "scoop", e.g. "1 level scoop provides 1g NAC".
        if lower.contains("scoop"),
           let match = firstMatch(in: line, pattern: #"(?i)(\d+(?:[\.,]\d+)?)\s+(?:\w+\s+)?scoops?\b"#) {
            let quantity = Double(match.captures[0].replacingOccurrences(of: ",", with: ".")) ?? 1
            return ServingSize(quantity: quantity, unit: .scoop)
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
        let normalizedLine = Self.paddedNormalizedKey(trimmed)

        if trimmed.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." || $0 == "," }) {
            return true
        }

        if lower.contains("%") && firstMatch(in: lower, pattern: #"\d"#) != nil && amountMatch(in: lower) == nil {
            return true
        }

        if isStandaloneHerbalNoteLine(trimmed) {
            return true
        }

        let alwaysSkippedHeaders = [
            "supplement facts", "nutrition information", "active ingredients",
            "amount per serve", "amount per serving", "amount per capsule",
            "amount per tablet", "% daily value", "% rdi", "% nrv"
        ]
        if containsAnyNormalizedPhrase(alwaysSkippedHeaders, in: normalizedLine) {
            return true
        }

        // Section headers — skip regardless of whether they contain an amount.
        // "each vegetarian capsule contains: 96 billion CFU" must not become a nutrient entry.
        let ingredientSectionHeaders = [
            "each tablet contains", "each capsule contains", "each dose contains",
            "each vegetarian capsule", "each veg capsule", "each softgel contains",
            "each softcap contains", "each sachet contains", "each scoop contains",
        ]
        if containsAnyNormalizedPhrase(ingredientSectionHeaders, in: normalizedLine) {
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
            "store in", "batch", "expiry", " exp ", " lot ", "exp:",
            // "Also contains" ingredient-disclaimer separator and allergen lists
            "also contains", "contains no ", "contains sulfites", "contains galactose",
            "dairy products", "natural flavour", "natural flavor",
            "lemon flavour", "lime flavour", "lemon flavor", "lime flavor",
            "malic acid", "acacia", "stevia",
            // Regulatory, safety and compliance disclaimers
            "this product contains", "daily dose of", "not be exceeded",
            "daily value not established", "value not established",
            "natural color variation", "natural colour variation",
            "dietary supplements should not", "not replace a balanced",
            "per tablet", "per capsule", "per serve", "per serving",
            "gmp facility", "refrigeration required",
            "keep out of reach", "for extemporaneous", "compounding only",
            "not manufactured with", "suitable for vegans", "suitable for vegetarians",
            "100% money back", "money back guarantee", "no added", "no artificial",
            "designed and packed", "packed in australia",
        ]
        if containsAnyNormalizedPhrase(nonIngredientPhrases, in: normalizedLine) {
            return true
        }

        // Company, address, and contact rows — common OCR spill from label back/sides.
        let companyAddressFragments = [
            "pty ltd", " ltd", "p/l", " abn ", " acn ", "tel:", "tel.",
            "www.", ".com", ".com.au", "@", " rd,", " rd.", " rd ", " st,", " ave,",
            "postcode", "po box", "distributor", "manufactured by", "imported by",
            " nsw ", " vic ", " qld ", " sa ", " wa ", " act ", " tas ", " nt ",
            " usa ", " il ", "bloomingdale", "glen ellyn",
        ]
        if containsAnyRawFragment(companyAddressFragments, in: lower) {
            return true
        }

        // OCR misread of "total elemental X Ymg" — single-letter word before "elemental"
        // e.g. "f elemental magnesium 400mg" (misread of "total elemental magnesium 400mg")
        if let firstWord = trimmed.split(separator: " ").first,
           firstWord.count == 1,
           lower.contains("elemental") {
            return true
        }

        return false
    }

    private func containsAnyNormalizedPhrase(_ phrases: [String], in paddedNormalizedLine: String) -> Bool {
        phrases.contains { phrase in
            let phraseKey = Self.paddedNormalizedKey(phrase)
            guard phraseKey.trimmingCharacters(in: .whitespaces).isEmpty == false else { return false }
            return (paddedNormalizedLine as NSString).range(of: phraseKey).location != NSNotFound
        }
    }

    private func containsAnyRawFragment(_ fragments: [String], in lowercasedLine: String) -> Bool {
        fragments.contains { fragment in
            (lowercasedLine as NSString).range(of: fragment).location != NSNotFound
        }
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
        // Matches standalone form-qualifier lines: "(providing ...)", "(equiv ...)",
        // "(as Selenomethionine)", "(from X)", "(as amino acid chelate)" etc.
        // Note: `as\s+\w+` not `as\s+\w` — \w alone with trailing \b fails when
        // the form name continues (e.g. "S" in "Selenomethionine" has no word boundary).
        line.range(
            of: #"(?i)^\(?\s*(providing|equiv\.?|equivalent(?:\s+to)?|as\s+\w+|from\s+\w+)\b"#,
            options: .regularExpression
        ) != nil
    }

    private func isStandaloneEquivalentActiveLine(_ line: String) -> Bool {
        line.range(
            of: #"(?i)^\(?\s*equiv\.?\s+"#,
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
            pattern: #"(?i)\b(bifidobacterium|lactobacillus|lactococcus|bacillus|saccharomyces|streptococcus)\s+([a-z][a-z-]+(?:\s+(?:ssp\.|subsp\.)\s+[a-z][a-z-]+)?)\b\s*([^()]*)?"#
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

    private func formName(for extractedName: String) -> String? {
        formsByVariant[Self.normalizedKey(extractedName)]
    }

    private func semanticFlags(for canonical: String, unit: NutrientUnit) -> [ReviewFlag] {
        guard unit != .unknown,
              let profile = semanticProfilesByCanonical[Self.normalizedKey(canonical)]
        else {
            return []
        }

        if profile.suspiciousUnits.contains(unit) {
            return [.unitImplausible]
        }

        if !profile.acceptedUnits.isEmpty, !profile.acceptedUnits.contains(unit) {
            return [.unitUnexpected]
        }

        return []
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

    private static func paddedNormalizedKey(_ value: String) -> String {
        let key = normalizedKey(value)
        return key.isEmpty ? "" : " \(key) "
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

nonisolated private struct LeadingEquivalentLine {
    let activeName: String
    let activeAmountText: String
    let activeUnitText: String
    let compoundAmountText: String?
    let compoundUnitText: String?
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
    nonisolated func debugDecisions(for rawText: String) -> [OCRDebugParserDecision] {
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
            } else if let herbal = herbalEntry(from: line) {
                decisions.append(OCRDebugParserDecision(
                    rawRow: line, decision: "herbal",
                    reason: "Latin binomial + extract keyword",
                    extractedName: herbal.latinName,
                    amount: herbal.extractAmount,
                    unit: herbal.extractUnit?.rawValue
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
