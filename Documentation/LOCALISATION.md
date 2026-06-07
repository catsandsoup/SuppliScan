# NutriScan — Localisation Strategy
# Skills for this document: `writing-for-interfaces`, `swift-format-style`
# Invoke `writing-for-interfaces` when adding any new user-facing string key.
# Invoke `swift-format-style` when formatting dates, numbers, or measurements for display.

## v1 Decision

English only. All user-facing strings managed via xcstrings with symbol keys
so future localisation requires only translation — no code changes.

---

## Implementation Rules

### All user-facing strings via xcstrings

No hardcoded string literals in Views or ViewModels.
No NSLocalizedString() calls — use generated symbol access.

```swift
// WRONG
Text("No text found on label.")

// CORRECT
Text(.labelNotFound)
```

### Symbol key convention

Keys are camelCase, descriptive, feature-prefixed.

```
scan.labelNotFound
scan.lowConfidenceWarning
scan.cameraPermissionDenied
review.analyseButton
review.addNutrient
report.disclaimer
report.aiInferredNote
report.noULEstablished
report.tierLabel.tier1
report.tierLabel.tier2
report.tierLabel.tier3
report.tierLabel.tier4
history.empty
history.deleteConfirmation
settings.defaultStandard
settings.deleteAllConfirmation
error.referenceDataLoadFailed
error.persistenceSaveFailed
error.exportFailed
```

### xcstrings setup

```
Localizable.xcstrings extractionState for all keys: "manual"
Default language: en
All keys have English value defined before any code is merged
```

### Disclaimer text — special handling

The disclaimer is a multi-sentence legal-adjacent string.
It lives in xcstrings with key `report.disclaimer`.
It must be reviewed before any wording change — it defines the regulatory
boundary between descriptive tool and therapeutic claim.

Current English value:
"This report is for practitioner reference only. It does not constitute
medical advice or therapeutic recommendation. Always exercise independent
clinical judgment."

---

## Strings That Are NOT in xcstrings

- Nutrient names in the reference database (domain data, not UI strings)
- Form names from labels (dynamic OCR output)
- AI-generated rationale text (dynamic)
- Log messages (developer-facing, English hardcoded is correct)
- Debug/test strings

---

## Adding New Strings

When the AI adds any user-facing string:
1. Add the key to Localizable.xcstrings with extractionState: "manual"
2. Provide the English value
3. Use the generated symbol in code — never the raw string
4. Do not call String(localized:) or NSLocalizedString() directly
