# Reference Data Handoff — Fresh Session Entry Point

**Date:** 2026-06-08
**What this is:** Complete briefing for a fresh window to implement Phase 1 (reference data) and Phase 4 (services). Read this first, then read AGENTS.md and CLAUDE.md.

---

## What Was Accomplished This Session

1. **NHMRC PDF obtained and saved.** The official source document is now at:
   `Documentation/nrv_au_nhmrc_2006_v1.2_sep2017.pdf`
   Title: *Nutrient Reference Values for Australia and New Zealand — Including Recommended Dietary Intakes, 2006, Version 1.2, Updated September 2017*
   Published by: National Health and Medical Research Council (NHMRC) + NZ Ministry of Health

2. **All AU NRV summary tables read from the PDF.** Tables 5–9 (pages 282–291) cover all vitamins and minerals for all demographic groups. The data below is transcribed directly from those tables.

3. **NASEM DRI PDF is in project tool-results.** The PDF at the path below shows the US DRI summary table (Vitamins — partial). Biotin, Choline, Folate, Niacin, Pantothenic Acid values visible for all life stages:
   `$PROJECT/.claude/projects/.../tool-results/webfetch-1780841751748-sja201.pdf`
   (This is the NASEM "Dietary Reference Intakes (DRIs): Vitamins" summary table, Food and Nutrition Board, Institute of Medicine, National Academies)

4. **Advisor confirmed rule:** Never write NRV numbers from memory. Every number in a JSON file must trace to a document actually read in that session. The NHMRC PDF is now in the repo — use `Read` on pages 282–291 to verify any value before writing it.

---

## Source Document Details

### AU — NHMRC 2006 v1.2

| Location | `Documentation/nrv_au_nhmrc_2006_v1.2_sep2017.pdf` |
|---|---|
| Citation | National Health and Medical Research Council, Australian Government Dept of Health and Ageing, NZ Ministry of Health. *Nutrient Reference Values for Australia and New Zealand Including Recommended Dietary Intakes*. Canberra: NHMRC; 2006. ISBN 1864962437 |
| Version | 1.2, Updated September 2017 (fluoride AI/UL revised Nov 2016, sodium SDT/UL revised Sep 2017) |
| Pages with data | 282–291 |
| Table index | Table 5 (p282–283): B Vitamins · Table 6 (p284–285): Vit A/C/D/E/K/Choline · Table 7 (p286–287): Ca/P/Zn/Fe · Table 8 (p288–289): Mg/Iodine/Se/Mo · Table 9 (p290–291): Cu/Cr/Mn/F/Na/K |

### US — NASEM DRI

| Status | Only the "Vitamins" summary table (Biotin, Choline, Folate, Niacin, Pantothenic Acid) has been directly read. Full minerals DRI table not yet obtained. |
|---|---|
| Source to use | `Read` the PDF at tool-results path above for what's there; for remaining nutrients fetch: https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx (NIH Office of Dietary Supplements DRI tables) or the NAP summary tables from https://www.nap.edu |

---

## AU NRV Data — Transcribed From NHMRC PDF

**How to read this table:**
- All values are for **supplemental intake** context (what the app analyses — not necessarily total diet)
- UL = Tolerable Upper Level of Intake (highest daily intake likely to pose no adverse health effects)
- `null` in UL column = no UL established ("NP" in source — not possible or insufficient evidence)
- Magnesium UL applies to supplements only (not from food); noted in `ul_note`
- Niacin UL applies to nicotinic acid form; separate UL for nicotinamide is 900 mg/day for adults
- Folate UL applies to synthetic folic acid from supplements/fortified foods
- Vitamin B6 UL is set for pyridoxine form
- Vitamin D values are AI (adequate intake) — no EAR established

### Demographics → JSON keys

| NHMRC source group | App key |
|---|---|
| Men 19–30 yr, Men 31–50 yr | `adult_male_19_50` |
| Women 19–30 yr, Women 31–50 yr | `adult_female_19_50` |
| Men 51–70 yr | `adult_male_51_70` |
| Women 51–70 yr | `adult_female_51_70` |
| Men >70 yr | `adult_male_70plus` |
| Women >70 yr | `adult_female_70plus` |
| Boys 14–18 yr | `adolescent_male_14_18` |
| Girls 14–18 yr | `adolescent_female_14_18` |
| Pregnancy 19–30 yr, 31–50 yr | `pregnant_female_19_50` |
| Lactation 19–30 yr, 31–50 yr | `lactating_female_19_50` |

---

### Table 5: B Vitamins (pages 282–283)

#### Thiamin — mg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 1.0 | 1.2 | null |
| adolescent_female_14_18 | 0.9 | 1.1 | null |
| adult_male_19_50 | 1.0 | 1.2 | null |
| adult_female_19_50 | 0.9 | 1.1 | null |
| adult_male_51_70 | 1.0 | 1.2 | null |
| adult_female_51_70 | 0.9 | 1.1 | null |
| adult_male_70plus | 1.0 | 1.2 | null |
| adult_female_70plus | 0.9 | 1.1 | null |
| pregnant_female_19_50 | 1.2 | 1.4 | null |
| lactating_female_19_50 | 1.2 | 1.4 | null |

#### Riboflavin — mg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 1.1 | 1.3 | null |
| adolescent_female_14_18 | 0.9 | 1.1 | null |
| adult_male_19_50 | 1.1 | 1.3 | null |
| adult_female_19_50 | 0.9 | 1.1 | null |
| adult_male_51_70 | 1.1 | 1.3 | null |
| adult_female_51_70 | 0.9 | 1.1 | null |
| adult_male_70plus | 1.1 | 1.3 | null |
| adult_female_70plus | 0.9 | 1.1 | null |
| pregnant_female_19_50 | 1.2 | 1.4 | null |
| lactating_female_19_50 | 1.3 | 1.6 | null |

#### Niacin — mg niacin equivalents/day — UL is for nicotinic acid only

| Group | EAR | RDI | UL | ul_note |
|---|---|---|---|---|
| adolescent_male_14_18 | 12 | 16 | 30 | UL is for synthetic nicotinic acid from supplements and fortified foods only |
| adolescent_female_14_18 | 11 | 14 | 30 | same |
| adult_male_19_50 | 12 | 16 | 35 | same |
| adult_female_19_50 | 11 | 14 | 35 | same |
| adult_male_51_70 | 12 | 16 | 35 | same |
| adult_female_51_70 | 11 | 14 | 35 | same |
| adult_male_70plus | 12 | 16 | 35 | same |
| adult_female_70plus | 11 | 14 | 35 | same |
| pregnant_female_19_50 | 14 | 18 | 35 | same |
| lactating_female_19_50 | 13 | 17 | 35 | same |

#### Vitamin B6 — mg/day — UL is for pyridoxine form

| Group | EAR | RDI | UL | ul_note |
|---|---|---|---|---|
| adolescent_male_14_18 | 1.1 | 1.3 | 40 | UL is for pyridoxine (supplemental) |
| adolescent_female_14_18 | 1.0 | 1.2 | 40 | same |
| adult_male_19_50 | 1.1 | 1.3 | 50 | same |
| adult_female_19_50 | 1.1 | 1.3 | 50 | same |
| adult_male_51_70 | 1.4 | 1.7 | 50 | same |
| adult_female_51_70 | 1.3 | 1.5 | 50 | same |
| adult_male_70plus | 1.4 | 1.7 | 50 | same |
| adult_female_70plus | 1.3 | 1.5 | 50 | same |
| pregnant_female_19_50 | 1.6 | 1.9 | 50 | same |
| lactating_female_19_50 | 1.7 | 2.0 | 50 | same |

#### Vitamin B12 — mcg/day — no UL established

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 2.0 | 2.4 | null |
| adolescent_female_14_18 | 2.0 | 2.4 | null |
| adult_male_19_50 | 2.0 | 2.4 | null |
| adult_female_19_50 | 2.0 | 2.4 | null |
| adult_male_51_70 | 2.0 | 2.4 | null |
| adult_female_51_70 | 2.0 | 2.4 | null |
| adult_male_70plus | 2.0 | 2.4 | null |
| adult_female_70plus | 2.0 | 2.4 | null |
| pregnant_female_19_50 | 2.2 | 2.6 | null |
| lactating_female_19_50 | 2.4 | 2.8 | null |

#### Folate — mcg dietary folate equivalents/day — UL is for folic acid from supplements/fortified foods

| Group | EAR | RDI | UL | ul_note |
|---|---|---|---|---|
| adolescent_male_14_18 | 330 | 400 | 800 | UL applies to folic acid from supplements and fortified foods only |
| adolescent_female_14_18 | 330 | 400 | 800 | same |
| adult_male_19_50 | 320 | 400 | 1000 | same |
| adult_female_19_50 | 320 | 400 | 1000 | same |
| adult_male_51_70 | 320 | 400 | 1000 | same |
| adult_female_51_70 | 320 | 400 | 1000 | same |
| adult_male_70plus | 320 | 400 | 1000 | same |
| adult_female_70plus | 320 | 400 | 1000 | same |
| pregnant_female_19_50 | 520 | 600 | 1000 | same |
| lactating_female_19_50 | 450 | 500 | 1000 | same |

#### Pantothenic Acid — mg/day — all AI values, no EAR, no UL

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 6.0 | null |
| adolescent_female_14_18 | 4.0 | null |
| adult_male_19_50 | 6.0 | null |
| adult_female_19_50 | 4.0 | null |
| adult_male_51_70 | 6.0 | null |
| adult_female_51_70 | 4.0 | null |
| adult_male_70plus | 6.0 | null |
| adult_female_70plus | 4.0 | null |
| pregnant_female_19_50 | 5.0 | null |
| lactating_female_19_50 | 6.0 | null |

#### Biotin — mcg/day — all AI values, no EAR, no UL

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 25 | null |
| adolescent_female_14_18 | 25 | null |
| adult_male_19_50 | 30 | null |
| adult_female_19_50 | 25 | null |
| adult_male_51_70 | 30 | null |
| adult_female_51_70 | 25 | null |
| adult_male_70plus | 30 | null |
| adult_female_70plus | 25 | null |
| pregnant_female_19_50 | 30 | null |
| lactating_female_19_50 | 35 | null |

---

### Table 6: Vitamins A, C, D, E, K and Choline (pages 284–285)

#### Vitamin A — mcg retinol equivalents/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 630 | 900 | 2800 |
| adolescent_female_14_18 | 485 | 700 | 2800 |
| adult_male_19_50 | 625 | 900 | 3000 |
| adult_female_19_50 | 500 | 700 | 3000 |
| adult_male_51_70 | 625 | 900 | 3000 |
| adult_female_51_70 | 500 | 700 | 3000 |
| adult_male_70plus | 625 | 900 | 3000 |
| adult_female_70plus | 500 | 700 | 3000 |
| pregnant_female_19_50 | 550 | 800 | 3000 |
| lactating_female_19_50 | 800 | 1100 | 3000 |

Note: "One α-tocopherol equivalent is equal to 1 mg RRR-α-tocopherol." Vitamin A UL applies to preformed retinol only, not beta-carotene.

#### Vitamin C — mg/day — no formal UL (prudent limit 1,000 mg/day per source footnote)

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 28 | 40 | null |
| adolescent_female_14_18 | 28 | 40 | null |
| adult_male_19_50 | 30 | 45 | null |
| adult_female_19_50 | 30 | 45 | null |
| adult_male_51_70 | 30 | 45 | null |
| adult_female_51_70 | 30 | 45 | null |
| adult_male_70plus | 30 | 45 | null |
| adult_female_70plus | 30 | 45 | null |
| pregnant_female_19_50 | 40 | 60 | null |
| lactating_female_19_50 | 60 | 85 | null |

#### Vitamin D — mcg/day — all AI values, UL applies to all sources

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 5 | 80 |
| adolescent_female_14_18 | 5 | 80 |
| adult_male_19_50 | 5 | 80 |
| adult_female_19_50 | 5 | 80 |
| adult_male_51_70 | 10 | 80 |
| adult_female_51_70 | 10 | 80 |
| adult_male_70plus | 15 | 80 |
| adult_female_70plus | 15 | 80 |
| pregnant_female_19_50 | 5 | 80 |
| lactating_female_19_50 | 5 | 80 |

Note: AI increases with age because older adults have reduced sun exposure and reduced dermal synthesis.

#### Vitamin E — mg α-tocopherol equivalents/day — all AI values

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 10 | 250 |
| adolescent_female_14_18 | 8 | 250 |
| adult_male_19_50 | 10 | 300 |
| adult_female_19_50 | 7 | 300 |
| adult_male_51_70 | 10 | 300 |
| adult_female_51_70 | 7 | 300 |
| adult_male_70plus | 10 | 300 |
| adult_female_70plus | 7 | 300 |
| pregnant_female_19_50 | 7 | 300 |
| lactating_female_19_50 | 11 | 300 |

Note: UL is for supplemental α-tocopherol only. From source: "The relevant figure for synthetic all-rac-α-tocopherols (dl-α-tocopherol) is 11 mg."

#### Vitamin K — mcg/day — all AI values, no UL established

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 55 | null |
| adolescent_female_14_18 | 45 | null |
| adult_male_19_50 | 70 | null |
| adult_female_19_50 | 60 | null |
| adult_male_51_70 | 70 | null |
| adult_female_51_70 | 60 | null |
| adult_male_70plus | 70 | null |
| adult_female_70plus | 60 | null |
| pregnant_female_19_50 | 60 | null |
| lactating_female_19_50 | 60 | null |

#### Choline — mg/day — all AI values

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 550 | 3000 |
| adolescent_female_14_18 | 400 | 3000 |
| adult_male_19_50 | 550 | 3500 |
| adult_female_19_50 | 425 | 3500 |
| adult_male_51_70 | 550 | 3500 |
| adult_female_51_70 | 425 | 3500 |
| adult_male_70plus | 550 | 3500 |
| adult_female_70plus | 425 | 3500 |
| pregnant_female_19_50 | 440 | 3500 |
| lactating_female_19_50 | 550 | 3500 |

---

### Table 7: Calcium, Phosphorus, Zinc, Iron (pages 286–287)

#### Calcium — mg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 1050 | 1300 | 2500 |
| adolescent_female_14_18 | 1050 | 1300 | 2500 |
| adult_male_19_50 | 840 | 1000 | 2500 |
| adult_female_19_50 | 840 | 1000 | 2500 |
| adult_male_51_70 | 840 | 1000 | 2500 |
| adult_female_51_70 | 840 | 1000 | 2500 |
| adult_male_70plus | 1100 | 1300 | 2500 |
| adult_female_70plus | 1100 | 1300 | 2500 |
| pregnant_female_19_50 | 840 | 1000 | 2500 |
| lactating_female_19_50 | 840 | 1000 | 2500 |

Note: "For calcium, there are separate recommendations for children aged 9–11 years and 12–13 years because of growth needs."

#### Phosphorus — mg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 1055 | 1250 | 4000 |
| adolescent_female_14_18 | 1055 | 1250 | 3500 |
| adult_male_19_50 | 580 | 1000 | 4000 |
| adult_female_19_50 | 580 | 1000 | 4000 |
| adult_male_51_70 | 580 | 1000 | 4000 |
| adult_female_51_70 | 580 | 1000 | 4000 |
| adult_male_70plus | 580 | 1000 | 3000 |
| adult_female_70plus | 580 | 1000 | 3000 |
| pregnant_female_19_50 | 580 | 1000 | 3500 |
| lactating_female_19_50 | 580 | 1000 | 4000 |

#### Zinc — mg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 11.0 | 13 | 35 |
| adolescent_female_14_18 | 6.0 | 7 | 35 |
| adult_male_19_50 | 12.0 | 14 | 40 |
| adult_female_19_50 | 6.5 | 8 | 40 |
| adult_male_51_70 | 12.0 | 14 | 40 |
| adult_female_51_70 | 6.5 | 8 | 40 |
| adult_male_70plus | 12.0 | 14 | 40 |
| adult_female_70plus | 6.5 | 8 | 40 |
| pregnant_female_19_50 | 9.0 | 11 | 40 |
| lactating_female_19_50 | 10.0 | 12 | 40 |

#### Iron — mg/day — NOTE: large sex and life-stage differences

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 8 | 11 | 45 |
| adolescent_female_14_18 | 8 | 15 | 45 |
| adult_male_19_50 | 6 | 8 | 45 |
| adult_female_19_50 | 8 | 18 | 45 |
| adult_male_51_70 | 6 | 8 | 45 |
| adult_female_51_70 | 5 | 8 | 45 |
| adult_male_70plus | 6 | 8 | 45 |
| adult_female_70plus | 5 | 8 | 45 |
| pregnant_female_19_50 | 22 | 27 | 45 |
| lactating_female_19_50 | 6.5 | 9 | 45 |

Note: Female 19–50 RDI is 18 mg due to menstrual losses. Post-menopause drops to 8 mg (same as men). Pregnancy RDI of 27 mg is the highest of any demographic.

---

### Table 8: Magnesium, Iodine, Selenium, Molybdenum (pages 288–289)

#### Magnesium — mg/day — UL applies to SUPPLEMENTAL magnesium only

| Group | EAR | RDI | UL | ul_note |
|---|---|---|---|---|
| adolescent_male_14_18 | 340 | 410 | 350 | UL applies to supplemental magnesium only; no UL from food sources |
| adolescent_female_14_18 | 300 | 360 | 350 | same |
| adult_male_19_50 | 330 | 400 | 350 | same |
| adult_female_19_50 | 255 | 310 | 350 | same |
| adult_male_51_70 | 350 | 420 | 350 | same |
| adult_female_51_70 | 265 | 320 | 350 | same |
| adult_male_70plus | 350 | 420 | 350 | same |
| adult_female_70plus | 265 | 320 | 350 | same |
| pregnant_female_19_50 | 300 | 350 | 350 | same |
| lactating_female_19_50 | 255 | 310 | 350 | same |

#### Iodine — mcg/day — requirement increases significantly in pregnancy/lactation

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 95 | 150 | 900 |
| adolescent_female_14_18 | 95 | 150 | 900 |
| adult_male_19_50 | 100 | 150 | 1100 |
| adult_female_19_50 | 100 | 150 | 1100 |
| adult_male_51_70 | 100 | 150 | 1100 |
| adult_female_51_70 | 100 | 150 | 1100 |
| adult_male_70plus | 100 | 150 | 1100 |
| adult_female_70plus | 100 | 150 | 1100 |
| pregnant_female_19_50 | 160 | 220 | 1100 |
| lactating_female_19_50 | 190 | 270 | 1100 |

#### Selenium — mcg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 60 | 70 | 400 |
| adolescent_female_14_18 | 60 | 70 | 400 |
| adult_male_19_50 | 60 | 70 | 400 |
| adult_female_19_50 | 50 | 60 | 400 |
| adult_male_51_70 | 60 | 70 | 400 |
| adult_female_51_70 | 50 | 60 | 400 |
| adult_male_70plus | 60 | 70 | 400 |
| adult_female_70plus | 50 | 60 | 400 |
| pregnant_female_19_50 | 55 | 65 | 400 |
| lactating_female_19_50 | 65 | 75 | 400 |

#### Molybdenum — mcg/day

| Group | EAR | RDI | UL |
|---|---|---|---|
| adolescent_male_14_18 | 33 | 43 | 1700 |
| adolescent_female_14_18 | 33 | 43 | 1100 |
| adult_male_19_50 | 34 | 45 | 2000 |
| adult_female_19_50 | 34 | 45 | 2000 |
| adult_male_51_70 | 34 | 45 | 2000 |
| adult_female_51_70 | 34 | 45 | 2000 |
| adult_male_70plus | 34 | 45 | 2000 |
| adult_female_70plus | 34 | 45 | 2000 |
| pregnant_female_19_50 | 40 | 50 | 2000 |
| lactating_female_19_50 | 36 | 50 | 2000 |

---

### Table 9: Copper, Chromium, Manganese, Fluoride, Sodium, Potassium (pages 290–291)

#### Copper — mg/day — all AI values for adults

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 1.5 | 8 |
| adolescent_female_14_18 | 1.1 | 8 |
| adult_male_19_50 | 1.7 | 10 |
| adult_female_19_50 | 1.2 | 10 |
| adult_male_51_70 | 1.7 | 10 |
| adult_female_51_70 | 1.2 | 10 |
| adult_male_70plus | 1.7 | 10 |
| adult_female_70plus | 1.2 | 10 |
| pregnant_female_19_50 | 1.3 | 10 |
| lactating_female_19_50 | 1.5 | 10 |

#### Chromium — mcg/day — all AI values, no UL established

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 35 | null |
| adolescent_female_14_18 | 24 | null |
| adult_male_19_50 | 35 | null |
| adult_female_19_50 | 25 | null |
| adult_male_51_70 | 35 | null |
| adult_female_51_70 | 25 | null |
| adult_male_70plus | 35 | null |
| adult_female_70plus | 25 | null |
| pregnant_female_19_50 | 30 | null |
| lactating_female_19_50 | 45 | null |

#### Potassium — mg/day — all AI values, no UL established

| Group | AI | UL |
|---|---|---|
| adolescent_male_14_18 | 3600 | null |
| adolescent_female_14_18 | 2600 | null |
| adult_male_19_50 | 3800 | null |
| adult_female_19_50 | 2800 | null |
| adult_male_51_70 | 3800 | null |
| adult_female_51_70 | 2800 | null |
| adult_male_70plus | 3800 | null |
| adult_female_70plus | 2800 | null |
| pregnant_female_19_50 | 2800 | null |
| lactating_female_19_50 | 3200 | null |

---

## JSON Schema (Required Format)

This must match `NRVDataFile` / `NRVNutrientEntry` / `NRVDemographicEntry` in `ReferenceDataService.swift`.

For nutrients with RDI: set `"rdi"` and `"ear"` (where available). `"reference_type"` = `"rdi"`.
For nutrients with AI only: set `"ai"`, omit `"rdi"` and `"ear"`. `"reference_type"` = `"ai"`.
If UL not established, omit the `"ul"` key entirely (null means unknown, not "no UL").

```json
{
  "standard": "AU",
  "edition": "NHMRC 2006 v1.2 (September 2017)",
  "source": "National Health and Medical Research Council, Australian Government Department of Health and Ageing, New Zealand Ministry of Health. Nutrient Reference Values for Australia and New Zealand Including Recommended Dietary Intakes. Canberra: NHMRC; 2006. ISBN 1864962437.",
  "nutrients": [
    {
      "name": "Vitamin A",
      "aliases": ["Retinol", "Vit A", "Beta-carotene"],
      "calculation_unit": "mcg",
      "source": "NHMRC NRV 2006 v1.2: Table 6, p284-285",
      "demographics": [
        {
          "group": "adult_male_19_50",
          "ear": 625,
          "rdi": 900,
          "ul": 3000,
          "reference_type": "rdi"
        },
        {
          "group": "adult_female_19_50",
          "ear": 500,
          "rdi": 700,
          "ul": 3000,
          "reference_type": "rdi"
        }
      ]
    },
    {
      "name": "Vitamin D",
      "aliases": ["Vit D", "Cholecalciferol", "Vitamin D3", "Ergocalciferol"],
      "calculation_unit": "mcg",
      "source": "NHMRC NRV 2006 v1.2: Table 6, p284-285",
      "demographics": [
        {
          "group": "adult_male_19_50",
          "ai": 5,
          "ul": 80,
          "reference_type": "ai"
        }
      ]
    },
    {
      "name": "Magnesium",
      "aliases": ["Mg"],
      "calculation_unit": "mg",
      "source": "NHMRC NRV 2006 v1.2: Table 8, p288-289",
      "demographics": [
        {
          "group": "adult_male_19_50",
          "ear": 330,
          "rdi": 400,
          "ul": 350,
          "ul_note": "UL applies to supplemental magnesium only; no UL established from food sources",
          "reference_type": "rdi"
        }
      ]
    }
  ]
}
```

**Critical schema rules from `ReferenceDataService.swift`:**
- `calculation_unit` field must match `NutrientUnit` enum cases in the codebase
- `reference_type` must be `"rdi"` or `"ai"`
- `ul_note` is optional — only include when there's a specific caveat about the UL
- Demographics that don't have an entry for a given nutrient simply won't appear
- The `standard` field must match `ReferenceStandard.rawValue` — verify the exact string

**`ReferenceDataService.load()` crash fix required before JSON will work:**
The current `load()` iterates `ReferenceStandard.allCases` and throws `BundleError.fileNotFound` if any standard's JSON is missing. This will crash when `nrv_eu.json` doesn't exist. Fix: change to `try?` (skip-and-log) so missing standards don't crash.

```swift
// In ReferenceDataService.load(), change:
for standard in ReferenceStandard.allCases {
    let file = try bundle.referenceData(named: standard.jsonFileName, as: NRVDataFile.self)
    loadedEntries[standard] = ...
}

// To:
for standard in ReferenceStandard.allCases {
    guard let file = try? bundle.referenceData(named: standard.jsonFileName, as: NRVDataFile.self) else {
        continue  // skip missing standards gracefully
    }
    loadedEntries[standard] = ...
}
```

---

## What Still Needs To Be Done

### Phase 1: Reference Data JSON files

Create these three files in `SuppliScan/Resources/ReferenceData/`:

1. **`nrv_au.json`** — Use data from tables above. Source document at `Documentation/nrv_au_nhmrc_2006_v1.2_sep2017.pdf`. For nutrients not listed here (Manganese, Fluoride, Sodium — not relevant for supplement analysis), skip them.

2. **`nrv_us.json`** — Read the NASEM DRI vitamins PDF (already partially available). For remaining nutrients, fetch from NIH ODS: https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx. **Do not write from memory.**

3. **`nrv_eu.json`** — Minimal stub to prevent ReferenceDataService crash (or fix the load() method). If EU data is not available from official sources in this session, create a minimal valid JSON with `"nutrients": []`.

Also add `interactions.json` and extend `form_quality.json` — see below.

### Phase 2: New Service Files

Create in `SuppliScan/Services/`:

**`FormQualityService.swift`** — actor that loads `form_quality.json` and provides:
```swift
actor FormQualityService {
    func quality(for nutrientName: String, form: String) async -> FormQuality?
}
```
Uses fuzzy matching (lowercase, strip punctuation) for nutrient and form lookup.

**`InteractionService.swift`** — actor that loads `interactions.json` and returns:
```swift
actor InteractionService {
    func interactions(for nutrients: [String]) async -> [InteractionFlag]
    func medicationInteractions(for nutrients: [String]) async -> [MedicationInteractionFlag]
}
```

**`ReportService.swift`** — actor orchestrating the full analysis pipeline:
```swift
actor ReportService {
    func generateReport(
        entries: [LabelEntry],
        servingSize: ServingSize,
        productName: String?,
        standard: ReferenceStandard,
        demographic: Demographic
    ) async throws -> LabelAnalysis
}
```
Steps: 1) For each nutrient entry: a) look up form quality, b) look up NRV, c) call CalculationService, d) flag if above UL. 2) Run interaction check across all nutrients. 3) Assemble LabelAnalysis with disclaimer and schemaVersion set.

### Phase 3: Wire Services Into UI

**`AppDependencies.swift`** — Add:
```swift
let referenceDataService: ReferenceDataService
let formQualityService: FormQualityService
let interactionService: InteractionService
let reportService: ReportService
```

**`ReviewViewModel.swift`** — Replace placeholder `requestAnalysis()`:
```swift
func requestAnalysis() {
    guard !isAnalysing else { return }
    isAnalysing = true
    Task {
        do {
            let analysis = try await dependencies.reportService.generateReport(
                entries: entries,
                servingSize: servingSize,
                productName: productName,
                standard: selectedStandard,
                demographic: Demographic(key: selectedDemographicKey) ?? .defaultAdult
            )
            await dependencies.persistence.save(analysis: analysis, ...)
            pendingAnalysis = analysis
        } catch {
            analysingError = error
        }
        isAnalysing = false
    }
}
```

Add `@ObservationIgnored @AppStorage("defaultStandard") private var storedStandard: ReferenceStandard = .au` and read it on init.

**`ReviewView.swift`** — Add `.task { viewModel.requestAnalysis() }` on appear. Push result via `router.navigate(to: .analysis(analysis))` instead of setting `analysisStore.currentAnalysis` (still set AnalysisStore too so History tab works).

**`RootTabView.swift`** — Remove `onChange(of: analysisStore.currentAnalysis) { selectedTab = .analysis }`.

**`AnalysisView.swift`** — Remove both `ContentUnavailableView("Nutrient Analysis Pending", ...)` blocks.

### Phase 4: interactions.json Schema

```json
{
  "version": 1,
  "nutrient_interactions": [
    {
      "participants": ["Calcium", "Iron"],
      "severity": "moderate",
      "effect": "Calcium inhibits non-haem iron absorption when taken concurrently at doses above 300mg calcium.",
      "recommendation": "Separate calcium and iron supplements by at least 2 hours.",
      "references": ["Hallberg L et al. Am J Clin Nutr. 1991;53(1):112-119."]
    }
  ],
  "medication_interactions": [
    {
      "nutrient": "Vitamin K",
      "medication_class": "Anticoagulants (Warfarin)",
      "severity": "high",
      "effect": "Vitamin K is the direct antagonist of warfarin. Consistent intake is required; sudden changes in vitamin K intake destabilise INR.",
      "recommendation": "Patients on warfarin must maintain consistent vitamin K intake and inform prescribing physician of any supplementation.",
      "references": ["Booth SL. Annu Rev Nutr. 2009;29:229-248."]
    }
  ]
}
```

---

## Critical Constants (Do Not Change)

From `CLAUDE.md` and confirmed in source code:

- IU conversions (hardcoded — not from JSON): Vitamin D ×0.025 mcg, Vitamin A retinol ×0.3 mcg, Vitamin E natural ×0.67 mg, synthetic ×0.45 mg
- `CalculationService` MUST throw if `entry.unit == .iu` — never silently convert
- `ServingMultiplier` applied exactly once, in CalculationService only
- `LabelAnalysis.disclaimer` and `.schemaVersion` set on every write — no exceptions
- `isAIInferred = true` only set by AIService — never by form quality JSON lookup

---

## Files — Schema stability

- `SuppliScanSchema.swift` — schema version stable at V1
- Any existing `@Model` — no schema changes without a migration plan
