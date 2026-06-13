# Privacy and Data Collection Draft

## App Store Privacy Answers

Tracking:
No.

Data collection:
Data Not Collected, based on the current codebase.

Current evidence:
- No `URLSession` usage in app code.
- No analytics SDK.
- No ad SDK.
- No account system.
- No third-party login.
- No remote OCR upload path found.
- Scan history and preferences are stored locally on device.

UserDefaults / AppStorage:
The app stores local preferences such as default reference standard, demographic key, OCR confidence display, and review-before-analysis behavior. `PrivacyInfo.xcprivacy` declares `NSPrivacyAccessedAPICategoryUserDefaults`.

Camera and photos:
Camera and photo-library access are used so the user can capture or import supplement-label images for on-device text recognition. The current camera purpose string is:
`SuppliScan uses the camera to photograph supplement labels for on-device text recognition.`

Privacy Policy URL:
Launch blocker. App Store Connect requires a live Privacy Policy URL for iOS apps.

Suggested privacy policy substance:
- SuppliScan does not sell personal information.
- SuppliScan does not track users across apps or websites.
- Supplement scans and reports are stored locally on the user's device unless the user chooses to share/export them.
- Camera/photo access is used only after user action.
- Preferences are stored locally to remember app settings.
- If future AI, sync, accounts, analytics, crash reporting, or cloud services are added, this policy and App Store privacy answers must be updated before release.

