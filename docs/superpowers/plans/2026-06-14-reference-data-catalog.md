# Reference Data Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand SuppliScan's bundled supplement reference data so nutrients, botanicals, probiotics, forms, interactions, contraindication notes, and sources can support the Library and future UI work.

**Architecture:** Keep v1 on-device and deterministic. Reuse the existing JSON loaders and add validation tests instead of adding a service or remote data dependency.

**Tech Stack:** Swift 6.2, Swift Testing, bundled JSON resources, NIH ODS, NCCIH, NHMRC source material.

---

### Task 1: Source And Schema Map

**Files:**
- Read: `Documentation/DATA_SCHEMA.md`
- Read: `Documentation/HANDOFF_REFERENCE_DATA.md`
- Read: `SuppliScan/SuppliScan/Services/SupplementKnowledgeService.swift`
- Read: `SuppliScan/SuppliScan/Services/NutritionLexicon.swift`
- Read: `SuppliScan/SuppliScan/Services/InteractionService.swift`

- [ ] Confirm `supplement_knowledge.json` supports source IDs, dose contexts, and clinical notes.
- [ ] Confirm `form_quality.json` supports references per form.
- [ ] Confirm `interactions.json` currently reports nutrient interactions only from nutrient analyses.

### Task 2: Expand Bundled Data

**Files:**
- Modify: `SuppliScan/SuppliScan/Resources/ReferenceData/supplement_knowledge.json`
- Modify: `SuppliScan/SuppliScan/Resources/ReferenceData/form_quality.json`
- Modify: `SuppliScan/SuppliScan/Resources/ReferenceData/interactions.json`

- [ ] Add every AU NRV nutrient to supplement knowledge.
- [ ] Add common botanical and probiotic entries with aliases, forms, active compounds, dose interpretation notes, safety notes, and source IDs.
- [ ] Replace unsourced form-quality prose with cited, uncertainty-preserving rationale.
- [ ] Add medication and nutrient interaction records the current report pipeline can surface.

### Task 3: Add Data Validation

**Files:**
- Create: `SuppliScan/SuppliScanTests/Services/ReferenceDataIntegrityTests.swift`

- [ ] Decode each edited JSON file from the bundle.
- [ ] Assert all source IDs referenced by entries, dose contexts, and notes exist.
- [ ] Assert every AU NRV nutrient has a supplement knowledge record.
- [ ] Assert each form-quality row has a valid tier and at least one reference.
- [ ] Assert interaction severities match `InteractionSeverity`.

### Task 4: Verify

**Commands:**
- `jq empty SuppliScan/SuppliScan/Resources/ReferenceData/supplement_knowledge.json`
- `jq empty SuppliScan/SuppliScan/Resources/ReferenceData/form_quality.json`
- `jq empty SuppliScan/SuppliScan/Resources/ReferenceData/interactions.json`
- `xcodebuild test -project SuppliScan/SuppliScan.xcodeproj -scheme SuppliScan -destination 'platform=iOS Simulator,name=iPhone 17'`

- [ ] Run JSON validation.
- [ ] Run focused unit tests if simulator discovery fails.
- [ ] Run the database audit skill checks for schema and migration risk.
