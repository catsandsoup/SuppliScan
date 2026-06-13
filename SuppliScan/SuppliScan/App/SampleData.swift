// SampleData.swift
// SuppliScan
// Debug-only seed data for simulator screenshots and UI testing.
// Never compiled into release builds.

#if DEBUG
import Foundation

enum SampleData {

    // MARK: - Sample LabelAnalysis

    static let analysis: LabelAnalysis = {
        let vitaminD = NutrientAnalysis(
            entry: NutrientEntry(
                canonicalName: "Vitamin D",
                displayName: "Vitamin D3 (Cholecalciferol)",
                form: "Cholecalciferol",
                amount: 25,
                unit: .mcg,
                servingMultiplier: 1.0
            ),
            rdiPercent: 167,
            ulPercent: 42,
            rdiReference: RDIReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 15,
                unit: .mcg,
                referenceType: .rdi,
                source: "NHMRC 2023"
            ),
            ulReference: ULReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 80,
                unit: .mcg,
                note: nil,
                source: "NHMRC 2023"
            ),
            formQuality: FormQuality(
                tier: .tier1,
                rationale: "Cholecalciferol (D3) is the preferred supplemental form with superior bioavailability and longer half-life compared to ergocalciferol (D2).",
                isAIInferred: false,
                confidence: nil,
                references: ["PMID:28768407", "PMID:19594220"]
            ),
            effectiveDose: 25,
            effectiveDoseUnit: .mcg
        )

        let magnesium = NutrientAnalysis(
            entry: NutrientEntry(
                canonicalName: "Magnesium",
                displayName: "Magnesium",
                form: "Magnesium Oxide",
                amount: 200,
                unit: .mg,
                servingMultiplier: 1.0
            ),
            rdiPercent: 49,
            ulPercent: 50,
            rdiReference: RDIReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 400,
                unit: .mg,
                referenceType: .rdi,
                source: "NHMRC 2023"
            ),
            ulReference: ULReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 350,
                unit: .mg,
                note: "Applies to supplemental magnesium only",
                source: "NHMRC 2023"
            ),
            formQuality: FormQuality(
                tier: .tier3,
                rationale: "Magnesium oxide has low bioavailability (~4%). Chelated forms such as magnesium glycinate or citrate are significantly better absorbed.",
                isAIInferred: false,
                confidence: nil,
                references: ["PMID:12597475"]
            ),
            effectiveDose: 200,
            effectiveDoseUnit: .mg
        )

        let zinc = NutrientAnalysis(
            entry: NutrientEntry(
                canonicalName: "Zinc",
                displayName: "Zinc",
                form: "Zinc Sulfate",
                amount: 45,
                unit: .mg,
                servingMultiplier: 1.0
            ),
            rdiPercent: 300,
            ulPercent: 113,
            rdiReference: RDIReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 14,
                unit: .mg,
                referenceType: .rdi,
                source: "NHMRC 2023"
            ),
            ulReference: ULReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 40,
                unit: .mg,
                note: nil,
                source: "NHMRC 2023"
            ),
            formQuality: FormQuality(
                tier: .tier2,
                rationale: "Zinc sulfate is a common, reasonably bioavailable supplemental form. Zinc bisglycinate may offer marginally better absorption with fewer GI side effects.",
                isAIInferred: false,
                confidence: nil,
                references: ["PMID:9550453"]
            ),
            effectiveDose: 45,
            effectiveDoseUnit: .mg
        )

        let vitaminC = NutrientAnalysis(
            entry: NutrientEntry(
                canonicalName: "Vitamin C",
                displayName: "Vitamin C (Ascorbic Acid)",
                form: "Ascorbic Acid",
                amount: 100,
                unit: .mg,
                servingMultiplier: 1.0
            ),
            rdiPercent: 111,
            ulPercent: 3,
            rdiReference: RDIReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 45,
                unit: .mg,
                referenceType: .rdi,
                source: "NHMRC 2023"
            ),
            ulReference: ULReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 2000,
                unit: .mg,
                note: nil,
                source: "NHMRC 2023"
            ),
            formQuality: FormQuality(
                tier: .tier1,
                rationale: "Ascorbic acid is the standard, well-researched form with equivalent bioavailability to mineral ascorbates.",
                isAIInferred: false,
                confidence: nil,
                references: ["PMID:8507655"]
            ),
            effectiveDose: 100,
            effectiveDoseUnit: .mg
        )

        let vitaminB12 = NutrientAnalysis(
            entry: NutrientEntry(
                canonicalName: "Vitamin B12",
                displayName: "Vitamin B12 (Methylcobalamin)",
                form: "Methylcobalamin",
                amount: 500,
                unit: .mcg,
                servingMultiplier: 1.0
            ),
            rdiPercent: 20833,
            ulPercent: nil,
            rdiReference: RDIReference(
                standard: .au,
                demographic: "adult_male_19_50",
                value: 2.4,
                unit: .mcg,
                referenceType: .rdi,
                source: "NHMRC 2023"
            ),
            ulReference: nil,
            formQuality: FormQuality(
                tier: .tier1,
                rationale: "Methylcobalamin is the active, bioidentical coenzyme form that does not require hepatic conversion. Preferred for neurological applications.",
                isAIInferred: false,
                confidence: nil,
                references: ["PMID:15453358"]
            ),
            effectiveDose: 500,
            effectiveDoseUnit: .mcg
        )

        let zincAboveUL = zinc

        let interaction = InteractionFlag(
            participants: ["Zinc", "Vitamin D"],
            severity: .low,
            effect: "High-dose zinc supplementation may interfere with Vitamin D receptor activity at pharmacological doses.",
            recommendation: "Separate doses or monitor total intake. This interaction is unlikely to be clinically significant at standard supplementation doses.",
            references: ["PMID:12600857"]
        )

        let medicationInteraction = MedicationInteractionFlag(
            nutrient: "Vitamin D",
            medicationClass: "Thiazide Diuretics",
            severity: .moderate,
            effect: "Concurrent use of Vitamin D and thiazide diuretics may increase risk of hypercalcaemia.",
            recommendation: "Monitor serum calcium if patient is on thiazide therapy. Consider dose reduction.",
            references: ["PMID:11790126"]
        )

        let flags = ReportFlags(
            nutrientsAboveUL: [zincAboveUL],
            nutrientsAtUL: [],
            lowBioavailabilityForms: [magnesium],
            aiInferredForms: [],
            unresolvedEntries: [],
            servingSizeAdjusted: false,
            nutrientInteractions: [interaction],
            medicationInteractions: [medicationInteraction]
        )

        return LabelAnalysis(
            id: UUID(),
            productName: "Advanced Multivitamin Pro",
            referenceStandard: .au,
            demographic: .defaultAdult,
            servingSize: ServingSize(quantity: 2, unit: .capsule),
            nutrientAnalyses: [vitaminD, magnesium, zinc, vitaminC, vitaminB12],
            herbalEntries: [],
            probioticEntries: [],
            unresolvedLines: [],
            flags: flags,
            disclaimer: LabelAnalysis.disclaimer,
            schemaVersion: LabelAnalysis.currentSchemaVersion,
            createdAt: Date()
        )
    }()

    // MARK: - Sample Review entries
    //
    // Models the hardest label in the training corpus (multi-form magnesium powder with
    // a horsetail extract) plus typical non-nutrient label text, so the Review display can
    // be verified deterministically across every state: ready, needs-review, and other text.

    static let reviewEntries: [LabelEntry] = [
        // Ready to analyse
        .nutrient(NutrientEntry(canonicalName: "Taurine", displayName: "Taurine", amount: 1000, unit: .mg)),
        .nutrient(NutrientEntry(
            canonicalName: "Magnesium", displayName: "Magnesium amino acid chelate",
            form: "amino acid chelate", amount: 350, unit: .mg,
            isElemental: true, compoundAmount: 1750, compoundUnit: .mg
        )),
        .nutrient(NutrientEntry(
            canonicalName: "Magnesium", displayName: "Magnesium glycinate dihydrate",
            form: "glycinate", amount: 12.2, unit: .mg,
            isElemental: true, compoundAmount: 104, compoundUnit: .mg
        )),
        .nutrient(NutrientEntry(canonicalName: "Zinc", displayName: "Zinc", form: "amino acid chelate", amount: 5, unit: .mg)),
        .herbal(HerbalEntry(
            latinName: "Equisetum arvense", commonName: "Horsetail",
            extractType: .dryConcExtract, extractAmount: 250, extractUnit: .mg,
            dryEquivalentAmount: 1000, dryEquivalentUnit: .mg,
            standardisation: HerbalStandardisation(compound: "silicon", calculatedAs: nil, amount: 14, unit: .mg)
        )),

        // Needs review
        .nutrient(NutrientEntry(
            canonicalName: "Magnesium", displayName: "Magnesium phosphate pentahydrate",
            form: "phosphate", amount: 24.8, unit: .mg,
            isElemental: true, compoundAmount: 120, compoundUnit: .mg,
            reviewFlags: [.extractEquivalent]
        )),
        .nutrient(NutrientEntry(canonicalName: "Selenium", displayName: "Selenomethionine", amount: nil, unit: .mcg, reviewFlags: [.amountNotFound])),
        .unresolved(RawLine(text: "Calcium pantothenate 30 mg", lineNumber: 12)),

        // Other label text (collapsed by default)
        .unresolved(RawLine(text: "Supports healthy hair, skin and nails", lineNumber: 1)),
        .unresolved(RawLine(text: "Take one tablet daily with a meal", lineNumber: 20)),
        .unresolved(RawLine(text: "Do not exceed the stated dose", lineNumber: 21)),
        .unresolved(RawLine(text: "Store below 25°C in a dry place", lineNumber: 22)),
        .unresolved(RawLine(text: "Imported and distributed by New Nordic Pty Ltd", lineNumber: 23)),
    ]
}
#endif
