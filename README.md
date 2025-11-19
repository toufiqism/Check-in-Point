# Check-in-Point
The app is essentially a location-based check-in system with real-time updates. Think of it as a mini version of Foursquare/Google check-in but focused on presence verification within a defined radius.

## Authentication
Firebase will act as the backend for user authentication and data storage. The app uses Firebase Authentication (email & password) with `provider` for state management.

### Added structure
- `lib/data/auth_repository.dart`: Abstraction over `FirebaseAuth`.
- `lib/providers/auth_provider.dart`: `ChangeNotifier` exposing auth state and actions.
- `lib/screens/login_screen.dart`: Minimal, responsive login UI.
- `lib/screens/register_screen.dart`: Minimal, responsive registration UI.
- `lib/screens/home_screen.dart`: Placeholder home after successful sign-in.
- `lib/main.dart`: Initializes Firebase, wires up Providers, and routes based on auth state.
  
#### Check-in feature (new)
- `lib/models/check_in_point.dart`: Model for a check-in point (lat, lng, radius, timestamps).
- `lib/data/check_in_repository.dart`: Firestore persistence enforcing a single active check-in per user via `users/{uid}/checkins/active` doc.
- `lib/providers/check_in_provider.dart`: `ChangeNotifier` exposing active check-in stream and save/clear actions.
- `lib/screens/check_in_create_screen.dart`: Google Map UI to drop a pin, adjust radius, and save.
  - Access from `HomeScreen` via the floating action button "Create check-in".

### Run prerequisites
1. Ensure platform config is present:
   - Android: `android/app/google-services.json` (already added)
   - iOS: Add `ios/Runner/GoogleService-Info.plist` to the Xcode project (Runner target). Make sure bundle id matches `com.tofiq.checkInPoint` or update `ios` options in `lib/firebase_options.dart` accordingly.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```



### Using auth
- Enable Email/Password provider in Firebase Authentication console.
- To register: From the login screen, tap "Don't have an account? Create one" and fill name, email, password.
- To sign in: Use email/password on the login screen.
- After signing in, you'll land on the home screen. Use the top-right logout icon to sign out.

### Notes for iOS
- Ensure `GoogleService-Info.plist` is added to the `Runner` target in Xcode.
- In Xcode, set iOS deployment target to match Flutter and Firebase SDK requirements (usually iOS 13+).
- Confirm that `ios/Runner/Info.plist` contains network permissions as needed.

### Google Maps setup
- Android: API key is defined in `android/app/src/main/AndroidManifest.xml` under `com.google.android.geo.API_KEY`.
- iOS: Add your Google Maps SDK for iOS API key in `AppDelegate.swift` (see below). Example:
  ```swift
  import GoogleMaps

  @UIApplicationMain
  class AppDelegate: FlutterAppDelegate {
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")
      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
  }
  ```

### Location permissions
- Android: `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are declared. If you plan background geofencing, keep `ACCESS_BACKGROUND_LOCATION`.
- iOS: Add the following to `ios/Runner/Info.plist`:
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Your location is used to create check-in points.</string>
  ```

### Check-in nearby
- Flow: When a user taps "Check in" the app fetches current GPS via `geolocator`, computes distance to the active point using `Geolocator.distanceBetween`, and compares with the configured radius.
- Success: Shows a success dialog if within radius; otherwise shows "Not in range" with distance in meters.
- Files:
  - `lib/providers/check_in_provider.dart`: `attemptCheckIn()` performs permission checks, gets current position, and calculates distance.
  - `lib/utils/location_helper.dart`: Centralized permission handling and current position retrieval.
  - `lib/screens/home_screen.dart`: Adds "Check in now" actions in the card and list.
  - `lib/screens/check_in_view_screen.dart`: Adds "Check in" button below the map.
- iOS notes: Ensure location usage description string is present (above). If testing on Simulator, provide a custom location in Features → Location.
- Android notes: Runtime permissions are requested automatically on first use via `geolocator`.

### Auto check-out (leave radius)
- Continuous monitoring: When an active check-in exists, the app subscribes to `Geolocator.getPositionStream()`.
- Logic: On each update, compute distance to the active point. If distance exceeds the radius, the app records a checkout and clears the active point.
- Data: Checkout logs written to `checkin_logs` collection with `uid`, `latitude`, `longitude`, `radiusMeters`, `checkedOutAt`, and `reason`.
- Files:
  - `lib/providers/check_in_provider.dart`: Start/stop monitoring tied to active point; auto-checkout when out of range.
  - `lib/data/check_in_repository.dart`: `recordCheckoutAndClear()` writes a log entry then deletes the active point.
- Background behavior: This implementation tracks only while the app is in foreground. For true background geofencing, consider platform-specific geofencing APIs or background services; ensure iOS background modes and Android background permissions are configured accordingly.

### Real-time checked-in count
- Model: `checkins/{uid}` document stores `{ checkedIn: bool, lastCheckInAt, lastCheckOutAt, updatedAt, point }`.
- Counting: Stream a query `where('checkedIn', isEqualTo: true)` and use the docs length.
- Files:
  - `lib/data/check_in_repository.dart`: `setUserCheckedIn`, `setUserCheckedOut`, `watchCheckedInCount`.
  - `lib/providers/check_in_provider.dart`: exposes `checkedInCount` stream and marks presence during manual/auto check-in/out.
  - `lib/screens/home_screen.dart` and `lib/screens/check_in_view_screen.dart`: display real-time count via `StreamBuilder<int>`.

### Firestore data model and rules
- Data path: `users/{uid}/checkins/active` (single document) with fields: `latitude` (double), `longitude` (double), `radiusMeters` (int), `active` (bool), `createdAt`, `updatedAt` (timestamps).
- Suggested Firestore rules (tighten as needed):
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{uid}/checkins/active {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
  ```

### Creating a check-in
1. Sign in.
2. On `HomeScreen`, tap "Create check-in".
3. Tap on the map to drop a pin, adjust the radius slider, tap "Save Check-in".
4. This overwrites the single active check-in at `users/{uid}/checkins/active`.

### UI/UX
- Minimalistic card-centered form
- Responsive layout via `LayoutBuilder` and constrained width for tablets/desktops
- Proper form validation and loading states

### Architecture
- Pattern: Layered, SOLID-aligned: Presentation → State → Data → Firebase SDK
- Presentation: `lib/screens/*` for UI widgets; no business logic.
- State management: `lib/providers/*` use `ChangeNotifier`; handle user intents, orchestrate side-effects, expose immutable state/streams to UI.
- Data layer: `lib/data/*` repositories abstract Firebase (`Auth`, `Firestore`) behind clean interfaces.
- Domain models: `lib/models/*` plain Dart value objects used across layers.
- Utilities: `lib/utils/*` platform helpers (location, dialogs); no app state.
- Unidirectional flow: UI → Provider → Repository → Firebase → Provider (streams) → UI.
- Testability: providers and repositories are injectable; external SDKs isolated in the data layer.

### Git Flow
- Base branches (from `.git/config`):
  - `prod` (production, GitFlow master)
  - `dev` (integration, GitFlow develop)
- Branch prefixes: `feature/`, `release/`, `hotfix/` (GitFlow); version tags use `V_` prefix (e.g., `V_1.2.3`).
- Workflow:
  1. Create an issue/task.
  2. Branch from `dev`: `feature/<short-scope>` (e.g., `feature/check_in_implementation`).
  3. Commit with Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).
  4. Open PR into `dev`; require review and green checks.
  5. Squash-merge into `dev`.
  6. Release: cut `release/x.y.z` from `dev`; only stabilization.
  7. Finalize: merge `release/x.y.z` to `prod` and back-merge to `dev`; tag `V_X.Y.Z`.
  8. Hotfix: branch `hotfix/x.y.z` from `prod`; after fix, merge to `prod` and `dev`; tag `V_X.Y.Z`.
- Note: A `main` branch exists remotely, but GitFlow production is `prod`. New work should target `dev` unless otherwise specified.
- Versioning: Semantic Versioning (MAJOR.MINOR.PATCH) with `V_` tag prefix.

### Compatibility notes
- Packages used (`google_maps_flutter`, `cloud_firestore`, `firebase_core`, `firebase_auth`, `geolocator`, `provider`) are supported on both Android and iOS. For iOS, ensure CocoaPods is set up and Xcode 15+.

## Testing

### Auth unit tests

Focused unit tests cover the authentication layer without hitting real Firebase services.

- Location: `test/auth/`
  - `auth_repository_test.dart`: repository delegation and behavior
  - `auth_provider_test.dart`: provider state, loading flags, error mapping, and calls

### How to run tests

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Run the full test suite:

   ```bash
   flutter test
   ```

### Test dependencies

- `mocktail` is used for mocking. It is dev-only and does not affect Android/iOS runtime.

### Notes

- The default counter widget test was replaced with a minimal placeholder to keep tests independent of runtime Firebase initialization. No app UI/behavior changes were made.
