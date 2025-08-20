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

### UI/UX
- Minimalistic card-centered form
- Responsive layout via `LayoutBuilder` and constrained width for tablets/desktops
- Proper form validation and loading states

### Architecture
- SOLID-friendly separation: UI → Provider → Repository → Firebase SDK
- `provider` ensures existing features are unaffected and state is predictable