# Submission Checklist

## Already Prepared

- Bundle ID: `montygiovenco.SuppliScan`
- Display name: `SuppliScan`
- Version: `1.0`
- Build: `1`
- Minimum OS: iOS 26.0
- Device family: iPhone
- Category: Health & Fitness
- Camera purpose string present
- Privacy manifest declares UserDefaults access
- Export compliance key set to no non-exempt encryption
- App icon asset catalog has default, dark, and tinted 1024px icons
- Draft metadata, privacy answers, review notes, and screenshot plan created

## Launch Blockers

- OCR overhaul must be finished and verified.
- Support URL must be live and reachable.
- Privacy Policy URL must be live and reachable.
- Age rating questionnaire must be completed in App Store Connect.
- Final App Store screenshots must be recaptured from the OCR-complete build.
- Archive upload must be created with Xcode 26 or newer.
- TestFlight smoke test must pass on a physical iPhone.

## Pre-Submit Audit

- Build with Release configuration.
- Run unit tests.
- Run UI tests on the selected screenshot simulator.
- Verify no production `print()` calls outside debug-only code.
- Verify no placeholder tabs, dead buttons, or debug-only affordances in Release.
- Verify `PrivacyInfo.xcprivacy` still matches code.
- Verify App Store privacy answers after any networking, AI, sync, analytics, crash reporting, or third-party SDK changes.
- Verify all screenshots are opaque RGB PNG or JPEG, within Apple size limits.
- Verify product-page copy avoids diagnosis, treatment, cure, or prevention claims.

