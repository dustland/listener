# TestFlight Deployment

This project can be built and uploaded to TestFlight by GitHub Actions without installing Xcode locally.

## Apple Developer Setup

1. In Apple Developer, create or confirm the App ID for `com.dustland.DialectListener`.
2. In App Store Connect, create the app record with the same bundle ID.
3. Create an App Store Connect API key with permission to upload builds. Save the key ID, issuer ID, and the `.p8` private key content.

## GitHub Setup

Add these repository secrets:

- `APPLE_TEAM_ID`: your Apple Developer Team ID.
- `APP_STORE_CONNECT_API_KEY_ID`: the App Store Connect API key ID.
- `APP_STORE_CONNECT_API_ISSUER_ID`: the App Store Connect issuer ID.
- `APP_STORE_CONNECT_API_PRIVATE_KEY`: the full contents of the downloaded `.p8` key file.
- `OPENROUTER_API_KEY`: OpenRouter key used for dialect conversion.
- `DOUBAO_ASR_API_KEY`: Volcengine/Doubao Speech API key from the new console.
- `DOUBAO_ASR_RESOURCE_ID`: Volcengine/Doubao ASR resource ID. For Seed ASR 2.0 hourly billing, use `volc.seedasr.sauc.duration`.

Optional repository variables:

- `APP_BUNDLE_ID`: defaults to `com.dustland.DialectListener`.
- `MARKETING_VERSION`: currently set in the workflow.

## Build

Run the `TestFlight` workflow manually from the GitHub Actions tab after the secrets are configured.

The workflow archives the app, exports an `.ipa`, stores it as a GitHub Actions artifact, and uploads it to TestFlight.
