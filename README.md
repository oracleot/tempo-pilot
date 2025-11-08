# Tempo Pilot

An updated AI-guided focus planner that respects your real schedule.

Tempo Pilot helps you fit focused work sprints around your existing commitments with intelligent Pomodoro timers, calendar-aware planning, and lightweight AI coaching. Built for students, meeting-heavy professionals, and anyone who needs to protect their focus time.

## Features

**Pomodoro Timer**
- 25/5 minute focus/break cycles with session tracking
- Local and push notifications for phase transitions
- Automatic reconciliation when returning to the app
- Streak tracking and focus statistics

**Calendar Integration**
- Read-only access to device calendars
- Automatic free/busy analysis for the next 7 days
- Smart focus slot suggestions between meetings
- Privacy-first: no calendar content leaves your device

**AI Planning Assistant**
- Plan and adjust your day with AI guidance
- Streaming responses for instant feedback
- 10 daily AI interactions with transparent quota display
- Resets at midnight London time

**Privacy & Data**
- EU/UK data residency (Supabase eu-west-2, Azure UK South)
- End-to-end encrypted local storage (Drift)
- No raw calendar content uploaded to servers
- Magic link authentication with session persistence

## Tech Stack

**Client**: Flutter (Android-first, minSdk 24) with Riverpod state management, go_router navigation, and encrypted Drift database for offline-first architecture.

**Backend**: Supabase (Auth, Postgres with RLS, Realtime, Storage) + Deno Edge Functions for serverless compute.

**AI**: Azure OpenAI (UK South) accessed via Edge Function proxy with SSE streaming and rate limiting.

**Notifications**: flutter_local_notifications for local scheduling; FCM for push (feature-flagged for tester cohort).

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Android Studio or VS Code with Flutter extensions
- Android device or emulator (minSdk 24)

### Setup
```bash
# Clone the repository
git clone https://github.com/oracleot/tempo-pilot
cd tempo-pilot

# Install dependencies
flutter pub get

# Run the app
flutter run \                                             git:master*
  --dart-define=SUPABASE_URL=https://project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

### Configuration

**Supabase Setup**:
1. Create a Supabase project at https://supabase.com
2. Get your project URL and anon key from Project Settings → API
3. Add `tempopilot://auth-callback` to Authentication → URL Configuration → Redirect URLs
4. Run the app with your credentials (see command above)

## Project Structure

```
lib/
├── app_shell/        # Navigation and routing (go_router)
├── auth/             # Magic link authentication
├── timer/            # Pomodoro engine and notifications
├── calendar/         # Calendar reading and free/busy analysis
├── planner/          # Day view and focus slot suggestions
├── ai_chat/          # AI assistant with SSE streaming
├── data/             # Repositories, Drift DAOs, sync logic
├── settings/         # App configuration and preferences
└── analytics/        # Crashlytics and minimal event tracking
```

## License

Private and proprietary.

## Version

1.0.0+1 (Android-first v1, pre-release)
