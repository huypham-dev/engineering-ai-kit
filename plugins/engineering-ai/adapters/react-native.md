# Adapter: React Native

Use this to *discover* conventions. Mobile builds are slow and environment-dependent; prefer JS-level checks unless the plan needs native verification.

## Signals
`package.json` depending on `react-native` or `expo`; `app.json`/`app.config.*`, `metro.config.*`, `ios/` and `android/` folders, `eas.json`.

## What to discover
| Topic | Where to look |
|---|---|
| Expo vs bare | `expo` dependency, `app.config.*`, presence of `ios/`/`android/` (prebuild vs committed native code) |
| Package manager & workspaces | Lockfile; monorepo tooling as in frontend.md |
| Navigation | `@react-navigation/*`, `expo-router` (file-based `app/` dir) |
| Tests | `jest` config with `preset: 'react-native'` or `jest-expo`; `@testing-library/react-native`; Detox/Maestro config for E2E |
| Lint/typecheck | Same as frontend.md |
| Native modules | `ios/Podfile`, `android/build.gradle`, config plugins in `app.config.*`, `react-native.config.js` |
| Platform code | `*.ios.tsx` / `*.android.tsx`, `Platform.OS` branches |
| Release config | `eas.json`, Fastlane, version/build numbers — **do not change without explicit approval** |

## Common risk areas
Platform-specific behaviour (test both branches of `Platform.OS`), permissions and `Info.plist`/`AndroidManifest.xml` changes, native dependency additions (need pod install / rebuild), OTA update compatibility, deep links, offline/slow network, keyboard and safe-area layout, performance on lists (`FlatList` keys, re-renders).

## Verification hints
- Run JS tests, lint and typecheck from the repo's scripts.
- Native builds (`pod install`, Gradle, Xcode, EAS) often cannot run in the current environment: report them as NOT RUN / COULD NOT RUN with the reason, and list manual device checks in the PR draft.
