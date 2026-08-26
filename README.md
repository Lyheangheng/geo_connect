# GeoConnect - University Assignment Demonstration Guide

GeoConnect is a Flutter mobile application developed for a university assignment. It connects to an existing Next.js backend API (`where_am_i`) to provide user authentication, OTP email verification, secure session management, interactive Google Maps location check-ins, and a real-time dashboard feed.

---

## 1. Project Architecture & Structure

The codebase is organized into clean, decoupled layers suitable for a university assignment:

```text
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart      # Configurable backend base URL & endpoint getters
│   ├── errors/
│   │   └── api_exception.dart      # HTTP error parsing & exception wrapper
│   └── theme/
│       └── app_theme.dart          # Dark mode glassmorphic theme system
├── models/
│   ├── user_model.dart             # UserModel data schema (id, name, email, isVerified, bio, images)
│   └── checkin_model.dart          # CheckInModel & nested CheckInUser (id, lat, lng, locationName, description, user)
├── providers/
│   └── auth_provider.dart          # ChangeNotifier managing auth status, session & user state
├── services/
│   ├── api_service.dart            # Centralized API service handling auth & check-in HTTP endpoints
│   └── storage_service.dart        # flutter_secure_storage wrapper for JWT storage
├── widgets/
│   ├── checkin_card.dart           # Reusable check-in feed item widget
│   ├── custom_button.dart          # Reusable gradient button with loading state
│   ├── custom_text_field.dart      # Reusable input text field with password toggle
│   └── interactive_map_widget.dart # Reusable Google Maps widget with markers & tap callbacks
├── screens/
│   ├── login_screen.dart           # Login UI (POST /api/auth/login)
│   ├── register_screen.dart        # Account registration (POST /api/auth/register)
│   ├── otp_verification_screen.dart# OTP code entry (POST /api/auth/verify-otp & resend-otp)
│   ├── main_shell_screen.dart      # Main shell container with BottomNavigationBar
│   ├── dashboard_screen.dart       # Live Google Map feed (GET /api/checking with User ID grouping)
│   ├── location_screen.dart        # Location picker, check-in creation, editing & deletion
│   └── profile_screen.dart         # Authenticated user details & logout action
└── main.dart                       # App entry point with MultiProvider & AuthWrapperScreen
```

---

## 2. Required Packages

Dependencies defined in `pubspec.yaml`:

- `provider` (^6.1.2) — State management for authentication session.
- `http` (^1.2.2) — HTTP REST API calls & multipart/form-data support.
- `flutter_secure_storage` (^9.2.2) — Encrypted storage for JWT bearer tokens.
- `google_maps_flutter` (^2.10.0) — Interactive Google Maps rendering and marker management.
- `google_fonts` (^6.2.1) — Modern typography system (Poppins & Inter).
- `intl` (^0.19.0) — Date and time formatting.

---

## 3. Professor API Base URL Configuration

The backend API URL is configured centrally in [lib/core/constants/api_constants.dart](file:///d:/backuptuf/Studying/Flutter/geo_connect/lib/core/constants/api_constants.dart):

- **Android Emulator Default**: `http://10.0.2.2:3000`
- **iOS Simulator / Web Default**: `http://localhost:3000`
- **Physical Device**: Update base URL to your computer's local IP (e.g. `http://192.168.1.100:3000`):
  ```dart
  ApiConstants.setBaseUrl('http://192.168.1.100:3000');
  ```

---

## 4. Google Maps API Configuration

1. Open `android/local.properties` and add your Google Maps API Key:
   ```properties
   MAPS_API_KEY=YOUR_REAL_GOOGLE_MAPS_API_KEY
   ```
2. `android/app/build.gradle.kts` passes `MAPS_API_KEY` to `manifestPlaceholders["MAPS_API_KEY"]`.
3. `android/app/src/main/AndroidManifest.xml` safely references `${MAPS_API_KEY}` without hardcoding secrets in Dart code.

---

## 5. How Authentication Works

1. **Register**: `RegisterScreen` collects `name`, `email`, and `password` $\rightarrow$ calls `POST /api/auth/register`.
2. **OTP Verification**: `OtpVerificationScreen` collects 6-digit OTP $\rightarrow$ calls `POST /api/auth/verify-otp`.
3. **JWT Storage**: On successful verification or login, the returned JWT string is stored in secure local storage (`flutter_secure_storage`).
4. **Persistent Session**: On app launch, `AuthWrapperScreen` executes `checkAuthStatus()`, calling `GET /api/auth/me` with header `Authorization: Bearer <TOKEN>`. If valid, user session is restored automatically.
5. **Logout**: Tapping Log Out in `ProfileScreen` calls `POST /api/auth/logout`, deletes the stored JWT, and returns to `LoginScreen`.

---

## 6. How Location Saving Works

1. User opens `LocationScreen` and taps anywhere on the interactive Google Map to pick coordinates (`lat`, `lng`).
2. User enters `locationName` and `description`.
3. Tapping **Save Location Check-In** constructs a `multipart/form-data` request sent to `POST /api/checking` with header `Authorization: Bearer <TOKEN>`.
4. If editing an existing check-in, user taps **Update Check-In** sending `PUT /api/checking` with JSON `{ id, locationName, description }`.
5. Tapping **Delete Check-In** sends `DELETE /api/checking?id=<id>`.

---

## 7. How Dashboard Retrieves Other Users' Locations

1. `DashboardScreen` executes `GET /api/checking` via `ApiService.getCheckIns()`.
2. **User Grouping Logic**: To prevent duplicate markers for users who checked in multiple times, check-ins are grouped by `userId` (or `user.id`).
3. Evaluates `createdAt` timestamps to retain only the **most recent** check-in per user.
4. Each user's latest check-in is rendered as a Google Maps `Marker` (`position: LatLng(lat, lng)`).
5. Tapping any marker opens a modal bottom sheet showing User Name, Location Name, Description, Address, Coordinates, and Timestamp.

---

## 8. How to Run the Application

```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis (verify 0 issues)
flutter analyze

# 3. Run automated test suite
flutter test

# 4. Launch app on Android emulator or connected device
flutter run
```

---

## 9. University Demonstration Script (Step-by-Step)

Follow this step-by-step sequence to demonstrate the application to your professor or evaluator:

| Step | Action | Expected Application Behavior |
|---|---|---|
| **1** | Open app & tap **Register** | App displays `RegisterScreen`. |
| **2** | Enter User A details & submit | Form sends `POST /api/auth/register` and navigates to `OtpVerificationScreen`. |
| **3** | Enter 6-digit OTP code | Form sends `POST /api/auth/verify-otp`, stores JWT securely, and opens `DashboardScreen`. |
| **4** | Navigate to **Location** tab | `LocationScreen` opens with an interactive Google Map picker. |
| **5** | Tap map & enter description | Google Map marker moves to tapped coordinates. Enter location name (e.g., *"Central Library"*) and description (e.g., *"Studying Flutter assignment"*). |
| **6** | Tap **Save Location Check-In** | Form sends `multipart/form-data` `POST /api/checking`, displays green SnackBar: *"Location check-in saved successfully!"*. |
| **7** | Go to **Profile** & tap **Log Out** | App calls `POST /api/auth/logout`, clears local storage, and returns to `LoginScreen`. |
| **8** | Register & Verify **User B** | Repeat registration & OTP verification for a second user account (`User B`). |
| **9** | Open **Dashboard** as User B | `DashboardScreen` fetches `GET /api/checking` and displays Google Map pins for active users. |
| **10** | Locate & tap **User A's marker** | Map marker displays InfoWindow for User A. Tapping marker opens modal bottom sheet. |
| **11** | Verify User A details | Modal displays User A's Name, Location Name (*"Central Library"*), and Description (*"Studying Flutter assignment"*). |
