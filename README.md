<<<<<<< HEAD
# Trust Meter - AI Exam Integrity System
## Flutter Mobile App

A complete AI-powered online exam monitoring app that tracks student behavior
and calculates a real-time Integrity Score using computer vision.

---

## Project Structure

```
trust_meter/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── models/
│   │   └── models.dart                  # ScoreEvent, Student models
│   ├── services/
│   │   ├── score_service.dart           # Integrity score logic (Provider)
│   │   ├── face_detection_service.dart  # ML Kit face detection
│   │   └── websocket_service.dart       # Real-time backend sync
│   ├── screens/
│   │   ├── login_screen.dart            # Student login
│   │   ├── exam_screen.dart             # Camera + live monitoring
│   │   ├── result_screen.dart           # Final score & breakdown
│   │   └── admin_screen.dart            # Admin dashboard
│   └── widgets/
│       ├── app_theme.dart               # Colors, styles, constants
│       └── common_widgets.dart          # Reusable UI components
├── assets/
└── pubspec.yaml
```

---

## Scoring Rules

| Behavior              | Deduction |
|-----------------------|-----------|
| Multiple faces        | -30       |
| Looking away          | -10       |
| Left frame            | -20       |
| Excessive head move   | -10       |

### Trust Levels
- 70-100 → TRUSTED (Green)
- 40-69  → SUSPICIOUS (Yellow)
- 0-39   → HIGH RISK (Red)

---

## Setup

```bash
flutter pub get
flutter run
```

Add camera permissions:
- Android: CAMERA permission in AndroidManifest.xml
- iOS: NSCameraUsageDescription in Info.plist
=======
# TrustMeter
>>>>>>> eed92df93497e3bdb951ef6591da8cf122a84ebd
