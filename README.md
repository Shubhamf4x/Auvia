<div align="center">

# Auvia

**Your life. Organized intelligently.**

A private, local-first personal organizer for Android — notes, documents, screenshots,
tasks and reminders in one place, with an AI assistant that can find, summarize,
explain and understand everything you save.

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![AI](https://img.shields.io/badge/AI-Enabled-7C5CFC)

</div>

---

## Overview

Auvia turns everyday information — screenshots, receipts, tickets, documents and
quick notes — into a searchable, organized library. Every item you import is read
by an AI vision pipeline that titles it, categorizes it and extracts the important
details, so you never have to scroll through your gallery looking for one bill again.

Everything is stored **locally on your device**. There is no account, no sign-up,
no cloud, no tracking.

## Features

### AI Assistant
- Conversational assistant with full access to your library context
- Automatic multi-model fallback — if a provider is busy or unavailable, requests
  are retried across verified free models, then a keyless service, then on-device
- AI vision: scanned photos and documents are analyzed for title, category,
  transcribed text and key information
- Natural-language actions — *"remind me to pay the bill on Friday"* creates a real
  reminder; *"add task submit application"* creates a real task

### Library
- Organized categories: Screenshots, Documents, Notes, Receipts, Tickets
- Create your own categories; delete any category you don't use
- Add photos or documents directly inside any category
- Every item carries an AI summary, extracted key facts and full-text search

### Screenshot & Document Scanning
- Point the camera or pick from your gallery
- AI reads the image and files it with a title, category and key details
- Imported images are copied into secure app-owned storage so they persist

### Notes
- Fast, minimal note editor
- Long-press to enter multi-select mode and delete in bulk

### Tasks & Reminders
- Today / Upcoming / Completed sections with priorities and due times
- Mini week calendar with task indicators and per-day filtering
- Reminders with date, time and repeat options

### Global Search
- One search across screenshots, documents, notes, tasks, reminders and metadata

### Personalization
- 6 themes: Light (default), Dark, Midnight, Neon Purple, Emerald, Electric Blue
- 20 languages with full RTL support (Arabic, Urdu, Hebrew, and more)
- Custom profile name and avatar

### Security
- **App Lock** with biometric unlock (fingerprint / face) — re-locks when the app
  leaves the foreground
- AI credentials stored in Android **Keystore-backed encrypted storage**
- **Backups disabled** — notes, documents and AI history never leave the device
  through Android backup or device transfer
- **HTTPS enforced** via Android Network Security Configuration; cleartext traffic
  and user-installed CA interception are rejected
- R8 code shrinking and Dart obfuscation in release builds

## How It Works

```
┌─────────────────────────────────────────────────┐
│                     Auvia                       │
│                                                 │
│  UI (Flutter)                                   │
│    ↓                                            │
│  AppState (ChangeNotifier, local-first)         │
│    ↓                    ↓                       │
│  SharedPreferences      App documents/media     │
│  (items, tasks,         (imported images)       │
│   reminders, chats)                             │
│    ↓                                            │
│  AiService                                      │
│    ├─ 1. Selected model      (free)             │
│    ├─ 2. Verified fallbacks  (free)             │
│    ├─ 3. Keyless service     (no API key)       │
│    └─ 4. On-device heuristics (offline)         │
│         ↓                                       │
│  Vision pipeline → JSON → Library item          │
└─────────────────────────────────────────────────┘
```

**Persistence.** All data is stored as JSON in the app's private shared
preferences, with a validation layer that caps and sanitizes every write.
Imported images are copied out of the OS cache into app-owned storage.

**AI chain.** Chat and document analysis go through the selected free model.
On failure, the service walks a verified fallback list, then a keyless endpoint,
and finally local heuristics — so the app stays usable with no network at all.

**Security model.** No account, no cloud, no telemetry. The Android manifest
disables all backups, network security config forbids plaintext traffic, and the
AI key lives in Keystore-backed encrypted storage, never in plaintext prefs.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart 3) |
| State | `ChangeNotifier` + InheritedWidget |
| Persistence | `shared_preferences`, `flutter_secure_storage`, `path_provider` |
| AI | OpenRouter-compatible chat API, multimodal vision, keyless fallback |
| Media | `image_picker` (camera / gallery), app-owned file storage |
| Auth (device) | `local_auth` biometrics |
| Localization | 20 locales via `flutter_localizations` |
| Android | R8, resource shrinking, Dart obfuscation, Network Security Config |

## Project Structure

```
lib/
├── main.dart                  # Entry point, global error handlers
├── app.dart                   # Root widget, routing, lifecycle, lock gate
├── core/
│   ├── theme.dart             # 6-palette design system + typography
│   ├── l10n.dart              # 20-language translation maps
│   ├── secrets.dart           # Credential constants (--dart-define overridable)
│   └── fmt.dart               # Date/time formatting helpers
├── data/
│   ├── app_state.dart         # Single source of truth + validation layer
│   ├── models.dart            # LifeItem, Task, Reminder, ChatMessage
│   └── scope.dart             # InheritedWidget state access
├── services/
│   ├── ai_service.dart        # Provider abstraction, fallback chain, vision
│   └── cloud_gateway.dart     # Backend contract for future accounts/sync
├── features/
│   ├── shell/                 # Bottom nav, drawer, lock screen
│   ├── home/                  # Dashboard, recent activity
│   ├── ai/                    # AI chat
│   ├── library/               # Categories, item/document detail
│   ├── notes/                 # Notes list + editor with multi-select
│   ├── tasks/                 # Tasks + mini calendar + creation
│   ├── reminders/             # Reminder list + creation
│   ├── screenshots/           # Scan + upload flows
│   ├── search/                # Global search
│   └── profile/               # Profile, themes, languages, security
└── widgets/                   # Reusable cards, bars, buttons, sheets
```

## Getting Started

### Prerequisites
- Flutter 3.22+ (Dart 3)
- Android SDK (min API 23) with licenses accepted

### Run

```bash
flutter pub get
flutter run
```

### Build a release APK

```bash
# Installable on any modern Android phone
flutter build apk --release --obfuscate --split-debug-info=build/symbols --split-per-abi
# Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Configuration

Auvia works out of the box on the keyless AI tier. To use your own OpenRouter
key, create a **gitignored** local config file:

```bash
# config/auvia.local.json
{ "AUVIA_AI_KEY": "sk-or-v1-your-key" }
```

then build with:

```bash
flutter build apk --release --dart-define-from-file=config/auvia.local.json
# or simply: .\build_local.ps1
```

| Define | Description |
|--------|-------------|
| `AUVIA_AI_KEY` | Optional AI gateway key (kept in Keystore-encrypted storage at runtime) |

You can also change the AI quality profile in-app under **Profile → AI Connection**
(Best quality / Fastest / Balanced / Lightweight — all free tiers).

## Privacy

Auvia collects nothing. Notes, documents, AI conversations and images stay on the
device. AI requests contain only the content you choose to ask about. Android
backups and device transfers are fully disabled so private data can never be
restored elsewhere.

## Roadmap

- [ ] Scheduled system notifications for reminders
- [ ] Optional cloud sync with end-to-end encryption (see `cloud_gateway.dart`)
- [ ] PDF import and full-text extraction
- [ ] iOS support
- [ ] Widgets

## License

All rights reserved. See repository settings for licensing updates.
