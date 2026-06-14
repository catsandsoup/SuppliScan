# Screenshot Plan

Target device set:
- Required primary set: iPhone 6.9-inch, portrait, 1290 x 2796 PNG.
- Optional fallback set: iPhone 6.5-inch, portrait, 1284 x 2778 PNG.

For SuppliScan 1.0, submit five iPhone screenshots:

1. Supplement Dose Reports
   - Raw source: `01-home.png`
   - Purpose: front-load the product promise: supplement labels become dose reports.

2. Catch Upper-Limit Risks
   - Raw source: `05-report.png`
   - Purpose: show safety flags and report snapshot.

3. Review Interaction Flags
   - Raw source: `06-interactions.png`
   - Purpose: show practitioner-facing safety context without making treatment claims.

4. Save Practitioner Reports
   - Raw source: `03-history.png`
   - Purpose: show practitioner workflow.

5. Choose RDI/UL Standards
   - Raw source: `04-settings.png`
   - Purpose: show AU, US, and EU reference-standard control.

Current limitation:
The OCR overhaul is in progress, so the final set should replace or supplement the current screenshots with the finished OCR review flow. The simulator camera screen is exercised by the UI test, but it is not framed for App Store use because it has no live camera feed.

Regenerate raw screenshots:
`Tools/capture_app_store_screenshots.sh`

Regenerate framed screenshots from raw captures:
`python3 Tools/build_app_store_promos.py`
