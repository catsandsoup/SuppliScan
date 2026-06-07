# NutriScan Test Corpus — Label Index
# 14 labels from real supplement collection
# Generated from IMG_1131–IMG_1144

## Coverage Summary

| # | File | Original | Format | Type | Key Parser Rules |
|---|---|---|---|---|---|
| 1 | selenium_150mcg_au.json | IMG_1143 | AU TGA | Single nutrient | P2 as-qualifier, mcg unit |
| 2 | probiotic_96b_cfu_multistrain_au.json | IMG_1136 | AU TGA | Probiotic (no NRV) | Two-column, CFU-only |
| 3 | probiotic_60b_cfu_herbal_au.json | IMG_1142 | AU TGA | Probiotic (no NRV) | Probiotic category, partial occlusion |
| 4 | quercetin_complex_au.json | IMG_1140 | AU TGA | Multi-nutrient tablet | Mixed NRV/no-NRV, variable dosing |
| 5 | astaxanthin_12mg_au.json | IMG_1137 | AU TGA | Single herbal extract | Extract equivalent pattern |
| 6 | magnesium_powder_multiform_au.json | IMG_1131 | AU TGA | Powder multi-form | Multiple elemental forms, total line |
| 7 | omega3_fish_oil_epa_dha_au.json | IMG_1138 | AU TGA | Multi-nutrient capsule | Sub-entries, g→mg, variable dosing |
| 8 | st_marys_thistle_taurine_selenium_au.json | IMG_1132 | AU TGA Herbal | Herbal + nutrients | Dry equivalent, standardisation, two sections |
| 9 | saw_palmetto_3500_au.json | IMG_1133 | AU TGA Herbal | Herbal only | Soft concentrate, fatty acid std, herbal-only |
| 10 | vitamin_d3_1000iu_au.json | IMG_1139 | AU TGA | Single nutrient IU | IU→mcg conversion, dual unit |
| 11 | vitamin_c_1g_zinc_bioflavonoids_au.json | IMG_1134 | AU TGA | Multi-nutrient tablet | Total summary line, two C forms |
| 12 | hair_volume_new_nordic_au.json | IMG_1144 | EU-style AU distributed | Multi-herbal + nutrients | EU decimal comma, Latin names |
| 13 | iron_ferrochel_b_vitamins_au.json | IMG_1141 | AU TGA | Multi-nutrient capsule | Trademarked forms, active B vitamins |
| 14 | chlorella_tablets_au.json | IMG_1135 | AU FSANZ food panel | Food nutrition panel | Per-serving/100g columns, food format |

---

## Parser Rules Exercised Across Corpus

| Rule | Labels Testing It |
|---|---|
| P2: as-qualifier | 1, 8, 13 |
| P3: from-qualifier | 4 (partial) |
| P4: elemental qualifier | 6, 11, 12, 13 |
| P6: dual unit IU+metric | 10 |
| P8: header skip | all |
| P_extract_equivalent | 5, 8, 9, 12 |
| P_standardised_extract | 8, 9, 12 |
| P_two_section_label | 8 |
| P_total_summary_line | 11 |
| P_trademark_strip | 13 |
| P_sub_entry_equiv | 7 |
| P_food_nutrition_panel | 14 |
| P_variable_dosing | 4, 7, 11 |
| A2: decimal comma | 12 |
| A4: trace/<1 | Not yet covered — add label |
| Probiotic category | 2, 3 |
| Herbal-only category | 9 |
| No-NRV nutrients | 4, 5, 6, 7, 8, 9, 12, 14 |
| IU conversion Vitamin D | 10 |

---

## Coverage Gaps (Labels Still Needed)

| Gap | Description | Priority |
|---|---|---|
| US Supplement Facts panel | FDA format with %DV column | High |
| EU format (native European label) | Different from AU distributed | Medium |
| IU Vitamin A label | Tests RAE conversion complexity | High |
| IU Vitamin E label | Tests d-alpha vs dl-alpha | High |
| Trace/<1 amounts | Very low dose micronutrient | Medium |
| Curved bottle poor lighting | OCR stress test | Medium |
| Multi-page folded insert | Some products have info inside box | Low |
| Barcode-only face | Tests skipping non-label face | Low |

---

## Classification Categories Covered

- ✅ Single nutrient (AU TGA)
- ✅ Multi-nutrient capsule (AU TGA)
- ✅ Multi-nutrient tablet (AU TGA)
- ✅ Powder (AU TGA)
- ✅ Probiotic (no NRV)
- ✅ Herbal extract tablet (AU TGA herbal)
- ✅ Herbal only (no nutrients)
- ✅ EU-style distributed in AU
- ✅ Food nutrition panel (AU FSANZ)
- ❌ US Supplement Facts panel (FDA)
- ❌ Soft gel (lipid-soluble vitamins, CoQ10)

---

## Unique Drug Interaction Flags in Corpus

For v2 contraindications engine — interactions identified across corpus:

| Nutrient/Compound | Interaction | Severity |
|---|---|---|
| Magnesium (high dose) | Quinolone/tetracycline antibiotics, bisphosphonates | Moderate |
| Omega-3 (>3g/day) | Anticoagulants (warfarin, aspirin, clopidogrel) | Moderate |
| Quercetin | CYP3A4/P-gp inhibition — immunosuppressants, antibiotics, cyclosporine | Moderate-High |
| Silymarin (St Mary's Thistle) | CYP2C9/3A4 — warfarin, phenytoin, statins | Moderate |
| Saw Palmetto (high dose) | Anticoagulants, hormonal therapies | Low-Moderate |
| Vitamin C (>1g) | Iron absorption (haemochromatosis), oxalate (kidney stones) | Context-dependent |
| Iron bisglycinate | Quinolones, tetracyclines, levothyroxine | Moderate |
| Biotin (high dose) | Immunoassay lab tests (thyroid, troponin, Vit D) | Clinical — lab interference |
| Vitamin K (any source) | Warfarin/INR | High — even small consistent amounts |
