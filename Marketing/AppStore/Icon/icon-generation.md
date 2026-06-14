# Icon Generation Notes

Generation mode:
Built-in Codex image generation, local PNG processing with Pillow, then layered
source assembly in Apple's Icon Composer for iOS 26 Liquid Glass readiness.

Original generated image:
`/Users/monty/.codex/generated_images/019ec0bc-aee6-7a23-a2c0-7e8ca82d6eb0/ig_0d3188f72a73abc0016a2de8508ecc8191aa4aa2a784917865.png`

Installed assets:
- `SuppliScan/SuppliScan/Assets.xcassets/AppIcon.appiconset/AppIcon-Default.png`
- `SuppliScan/SuppliScan/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- `SuppliScan/SuppliScan/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- `Marketing/AppStore/Icon/SuppliScan-AppIcon-1024.png`
- `Marketing/AppStore/Icon/SuppliScan.icon`

Icon Composer source:
`Marketing/AppStore/Icon/SuppliScan.icon`

Layer order:
1. `06-glass-highlights`
2. `05-risk-data-accents`
3. `04-ink-label-lines`
4. `03-jade-scan-bracket`
5. `02-glass-report-tile`
6. `01-background-plate`

Prompt:
Premium iOS 26 App Store icon for SuppliScan, a native supplement label analysis app. Square 1024x1024, fully opaque, no rounded corners, no text, no letters, no numbers, no watermark. Central symbol: a translucent Liquid Glass supplement label/report tile with three clean label lines and a precise jade scan bracket around it. Include one small red upper-limit risk bar and one amber interaction dot as subtle data accents. Warm off-white report surface, near-black ink accents, clinical jade, restrained amber and red. No capsule or pill as the main subject. No caduceus, medical cross, Apple logo, iPhone hardware, or screenshots.

Validation:
- 1024 x 1024 pixels.
- RGB PNG.
- No alpha channel.
- No rounded corners baked into the artwork.
- No text or letters.
- Icon Composer package contains `icon.json` and six named image layers.
- Icon Composer fill is set to SuppliScan jade instead of the default starter
  blue gradient.
