# Hot Takes Only 🔥

A Cards Against Humanity-style iOS party game. Fully online, multiplayer, real-time.  
This repo contains **Prototype v1** — the core game loop with Supabase Realtime sync.

---

## Stack

| Layer | Technology | Why |
|---|---|---|
| UI | SwiftUI (iOS 17+) | Native 120Hz, day-one AirPlay/Sign-in-with-Apple, zero framework lag |
| State | `ObservableObject` + `@EnvironmentObject` | Single source of truth via `GameViewModel` |
| Backend | Supabase (Postgres + Realtime) | Sub-50ms broadcast latency, free at <50K MAU, SQL flexibility |
| Real-time | Supabase `realtimeV2` channels (`postgres_changes`) | Event-driven game state — no polling |
| Auth | None (v1 prototype) | Display name + device UUID; add Sign in with Apple for v2 |
| Cards | Hardcoded Swift arrays | No DB table needed for prototype; swap for user-generated content later |

---

## Architecture

```
HotTakesOnly/
├── App/
│   ├── HotTakesOnlyApp.swift     # @main + RootView (state-driven navigation)
│   └── AppDelegate.swift         # Background task + grace-timer disconnect detection
├── Config/
│   └── SupabaseConfig.swift      # Project URL + anon key (fill in before running)
├── Models/
│   ├── Room.swift                # Room + GamePhase enum + NewRoom insert payload
│   ├── Player.swift              # Player + NewPlayer (includes last_ping for heartbeat)
│   └── Submission.swift         # Submission + NewSubmission
├── Data/
│   └── SampleCards.swift        # 15 black cards, 50 white cards + deal helpers
├── Services/
│   ├── SupabaseService.swift    # Singleton SupabaseClient wrapper
│   ├── LiveKitService.swift     # LiveKit voice chat stub (deferred to post-launch)
│   └── GameViewModel.swift      # All game logic, Supabase ops, Realtime subscriptions
├── Features/
│   ├── Lobby/
│   │   ├── LobbyView.swift       # Name entry + create/join flow
│   │   └── WaitingRoomView.swift # Room code display + player list + Start button
│   ├── Game/
│   │   ├── GameView.swift        # Phase container (submitting / judging / round-over)
│   │   ├── FinalScoreView.swift  # End-of-game leaderboard
│   │   └── Components/
│   │       ├── BlackCardView.swift    # The prompt card (black)
│   │       ├── WhiteCardView.swift    # Answer card (white, reused in hand + judging)
│   │       ├── HandView.swift         # Horizontal scroll of player's hand
│   │       ├── JudgingView.swift      # Judge picks winner from submitted cards
│   │       ├── RoundResultsView.swift # Winner reveal + scoreboard
│   │       ├── ScoreboardView.swift   # Sorted player scores
│   │       └── QuickChatOverlay.swift # Floating toast for broadcast quick-chat messages
│   └── TV/
│       ├── TVGameView.swift              # AirPlay second-screen game display
│       └── ExternalDisplaySceneDelegate.swift # Routes external UIScreen to TVGameView
└── Resources/
    └── Assets.xcassets/
```

### Game state machine

```
waiting ──[host: Start]──► submitting ──[all submitted]──► judging
   ▲                                                           │
   │                                                    [judge picks]
   │                                                           ▼
finished ◄──[score ≥ 7 or max rounds]──────────────── round_over
                                                               │
                                                    [judge: Next Round]
                                                               │
                                                        submitting (n+1)
```

### Who drives state transitions

The **host client** drives game start and card dealing.  
The **judge client** drives winner selection and round advancement.  
All other clients are **read-only** — they react to Realtime events from Supabase.

This is intentional for the prototype. In production, move transitions to Supabase Edge Functions or Postgres triggers for cheat-resistance.

### Realtime strategy

Each event from Supabase triggers a full re-fetch of the relevant table for the current room. This is slightly over-fetching (~3 small queries per event) but is trivially fast at ≤10 players and makes the code simple and correct.

```swift
// On any rooms change → re-fetch room row
// On any players change → re-fetch all players for this room
// On any submissions change → re-fetch submissions for current round
```

Replace with direct record decoding from `AnyAction.newRecord` for production efficiency.

---

## Prerequisites

- Xcode 16+ (Swift 6)
- A free [Supabase](https://supabase.com) account
- `xcodegen` (`brew install xcodegen`) — only needed if you regenerate the `.xcodeproj`

---

## Local Setup (5 steps)

### 1. Create a Supabase project

Go to [supabase.com](https://supabase.com) → New Project.  
Note the **Project URL** and **anon public key** from Settings → API.

### 2. Run the database migrations

In the Supabase dashboard, go to **SQL Editor → New Query** and run each migration in order:

```
supabase/migrations/001_initial_schema.sql   # rooms, players, submissions tables + RLS + Realtime
supabase/migrations/002_add_is_ready.sql     # is_ready column on players
```

```
supabase/migrations/003_add_last_ping.sql    # last_ping column for heartbeat disconnect detection
```

This adds the `last_ping` column used by the heartbeat system. Without it, disconnected players are never evicted.

### 3. Enable Realtime replication

Go to **Database → Replication** in the dashboard.  
Verify that `rooms`, `players`, and `submissions` appear under the `supabase_realtime` publication (the migration SQL handles this, but confirm it's toggled on).

### 4. Add your credentials

Open [HotTakesOnly/Config/SupabaseConfig.swift](HotTakesOnly/Config/SupabaseConfig.swift) and fill in:

```swift
static let url = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
static let anonKey = "YOUR_ANON_KEY"
```

> **Never commit real credentials.** Add `SupabaseConfig.swift` to `.gitignore`, or use a `.xcconfig` file with environment variable injection for CI.

### 5. Open in Xcode and run

```bash
open HotTakesOnly.xcodeproj
```

Select a simulator or physical device (iOS 17+), then **⌘R** to build and run.

> First build will resolve the Supabase Swift Package Manager dependency (~30 seconds).

---

## Testing the game loop locally

The easiest way to test multiplayer without physical devices:

1. Run the app on **two simulators simultaneously** (Xcode → Devices and Simulators → add a second iOS 17 simulator, then use `xcodebuild` or open a second Xcode window).
2. Alternatively, run on one simulator + one physical iPhone.

**Happy path:**
1. **Device A** — Enter a name → "Create Game" → note the 6-char room code
2. **Device B** — Enter a name → "Join Game" → enter the code
3. **Device A** (host) → tap "Start Game"
4. Both devices transition to the game view. Device A's judge sees "You're the judge"; Device B sees their hand.
5. **Device B** — tap a white card → "Submit This Card"
6. **Device A** (judge) — tap the submitted card → "Choose This Card"
7. Winner reveal screen appears on both devices with updated scores.
8. **Device A** (judge) → "Next Round →" to continue.
9. After 5 rounds (or first to 7 points), the final score screen appears.

---

## Environment validation

To confirm Realtime is working before playing:

1. Open the Supabase dashboard → **Table Editor → rooms**
2. Run the app, create a room
3. You should see a new row appear in the rooms table
4. In the dashboard, manually update the `status` column to `submitting`
5. The app should transition to the game view automatically (within ~1–2 seconds)

If it doesn't update, check:
- Realtime publication includes the `rooms` table
- RLS policies allow SELECT on rooms
- Your anon key matches the project

---

## Next steps

| Step | What | Status |
|---|---|---|
| Core game loop | Rooms, players, submissions, judge rotation | ✅ Done |
| Quick chat | Supabase Broadcast toast overlay | ✅ Done |
| AirPlay second screen | `TVGameView` on external `UIScreen` | ✅ Done |
| Disconnect detection | Heartbeat + grace-timer eviction | ✅ Done |
| CI/CD | Xcode Cloud + TestFlight automated builds | 🔲 Pending |
| Sign in with Apple + Keychain | PKCE flow, persistent identity | 🔲 Pre-launch |
| `PrivacyInfo.plist` | Required for App Store submission (iOS 17+) | 🔲 Pre-launch |
| Supabase RLS (tighten) | Per-player row ownership, remove open policies | 🔲 Pre-launch |
| Move game logic to Edge Functions | Cheat-resistant authoritative server | 🔲 Post-launch |
| LiveKit voice chat | `client-sdk-swift` per-room audio | 🔲 Post-launch |

---

## Known prototype limitations

- **No reconnection** — if a player is evicted (missed heartbeats) and returns, they land on the lobby screen; they cannot rejoin the in-progress game
- **No card pool limits** — with many rounds, the 50-card white deck can be exhausted; add more cards or a shuffle/reset mechanism
- **Host-driven logic** — the host client writes game state; in production, use Supabase Edge Functions as the authoritative game server
- **No auth** — player identity is scoped to the app session; add Sign in with Apple for persistence and friend lists
- **Open RLS policies** — anyone can read/write any room; tighten with per-player row ownership before public launch
