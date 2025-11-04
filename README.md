# Email Phishing Detection Application

A mobile application developed with Flutter to help users detect and protect against phishing emails. The app integrates multi-factor authentication and a user-friendly interface.

## 🎯 Project Goals

Build an intelligent email security tool to help users:
- Securely login with multiple authentication methods
- Manage and read emails from various sources (Gmail, IMAP)
- Detect dangerous phishing emails
- Protect personal information from fraudulent attacks

## ✨ Current Features

### 🔐 Authentication & Security
- **Google Sign-In**: Integrated Google Sign-In for quick login experience
- **Email/Password Login**: Support registration and login via email with Firebase Authentication
- **Email Verification**: Send verification email to ensure account validity
- **Biometric Authentication**: Secure app with fingerprint/Face ID
- **Session Management**: Securely store login information

### 📧 Email Management
- **Gmail Integration**: Read emails from Gmail account via Gmail API
- **IMAP Support**: Configure IMAP connection for other email providers
- **Email List**: Display email list with intuitive interface
- **Email Content Reader**: View detailed content and metadata of emails

### 🎨 User Interface
- **Material Design 3**: Modern, user-friendly design
- **Google Theme**: Uses Google's color scheme and design style
- **Responsive**: Optimized for multiple screen sizes
- **Drawer Navigation**: Easy-to-use navigation menu
- **Bottom Sheet**: Quick settings with bottom sheet

## 🚀 Upcoming Features

### 🤖 AI-Powered Phishing Analysis
- **Machine Learning Model**: Integrate AI model to detect phishing emails
- **Content Analysis**: Evaluate email content, links, and attachments
- **Scoring System**: Risk scoring system for email threats
- **Smart Alerts**: Automatic notifications when dangerous emails are detected
- **Analysis History**: Store analysis results for tracking

### 📊 Statistics & Reports
- **Dashboard**: Display statistics about scanned emails
- **Detailed Reports**: Analyze trends and common phishing types
- **Export Reports**: Generate PDF/CSV reports of scanned emails

### 🔔 Notifications
- **Push Notification**: Alert immediately when suspicious emails are received
- **Email Alert**: Send email notifications about threats

## 🛠️ Technologies Used

### Framework & Language
- **Flutter**: 3.9.2
- **Dart**: SDK ^3.9.2

### Backend & Authentication
- **Firebase Core**: 3.8.1 - Backend platform
- **Firebase Auth**: 5.3.3 - User authentication
- **Google Sign-In**: 6.2.1 - Google login

### Email Services
- **Gmail API**: googleapis 13.2.0, googleapis_auth 1.6.0
- **IMAP Protocol**: enough_mail 2.1.7

### Security & Storage
- **Local Auth**: 2.3.0 - Biometric authentication
- **Flutter Secure Storage**: 9.2.2 - Secure storage
- **Shared Preferences**: 2.2.2 - Settings storage

### Networking
- **HTTP**: 1.2.0 - API requests

## 📋 System Requirements

- **Flutter SDK**: >= 3.9.2
- **Android**: API level 21 (Android 5.0) or higher
- **iOS**: iOS 12.0 or higher (if building for iOS)
- **Windows**: Windows 10 or higher (if building for Windows)

## 🔧 Installation and Running

### 1. Clone repository
```bash
git clone <repository-url>
cd project
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
- Create a new project on [Firebase Console](https://console.firebase.google.com/)
- Add Android/iOS app to Firebase project
- Download configuration files:
  - Android: `google-services.json` → `android/app/`
  - iOS: `GoogleService-Info.plist` → `ios/Runner/`
- Enable Firebase Authentication (Email/Password and Google Sign-In)

### 4. Configure Google Sign-In
- Create OAuth 2.0 credentials on [Google Cloud Console](https://console.cloud.google.com/)
- Add SHA-1 fingerprint for Android:
```bash
cd android
./gradlew signingReport
```

### 5. Run the application
```bash
# Android
flutter run

# Windows (if available)
flutter run -d windows
```

## 📁 Project Structure

```
lib/
├── main.dart                          # Application entry point
├── models/                            # Data models
│   └── email_message.dart             # Email message model
├── screens/                           # UI screens
│   ├── auth_wrapper.dart              # Authentication state wrapper
│   ├── google_login_screen.dart       # Google login screen
│   ├── email_login_screen.dart        # Email login screen
│   ├── email_register_screen.dart     # Registration screen
│   ├── email_verification_screen.dart # Email verification screen
│   ├── biometric_lock_screen.dart     # Biometric authentication screen
│   ├── home_screen.dart               # Home screen
│   ├── email_list_screen.dart         # Email list screen
│   └── imap_setup_screen.dart         # IMAP configuration screen
└── services/                          # Business logic & services
    ├── auth_service.dart              # Authentication service
    ├── biometric_service.dart         # Biometric service
    └── gmail_service.dart             # Gmail API service
```

## 🎓 Graduation Thesis Project

This project is being developed as part of a Graduation Thesis (DATN).

**Status**: In Development 🚧

**Current Phase**:
- ✅ Completed multi-factor authentication system
- ✅ Completed email reading integration (Gmail & IMAP)
- ✅ Completed basic user interface
- 🔄 Currently researching and developing AI phishing analysis module
- ⏳ Notification and reporting systems not yet implemented

**Development Roadmap**:
1. **Phase 2**: Integrate AI/ML model for phishing email analysis
2. **Phase 3**: Build scoring and alert system
3. **Phase 4**: Add statistics and reporting features
4. **Phase 5**: Testing and performance optimization
5. **Phase 6**: Complete documentation and demo

## 🔒 Security

The application is committed to protecting user information:
- Passwords encrypted by Firebase Authentication
- Authentication tokens securely stored with Flutter Secure Storage
- Supports biometric authentication (fingerprint/Face ID)
- Does not store email content on server
- All connections use HTTPS/SSL

## 📸 Screenshots

_(Screenshots will be updated after UI completion)_

## 🤝 Contributing

This is a personal thesis project. All feedback and suggestions are welcome!

## 📝 License

This project is developed for educational and research purposes.

## 👨‍💻 Author

**Team 2**
- Email: datlecong156@gmail.com


## 📞 Contact

If you have any questions or feedback, please contact via email or create an issue on the repository.

---

**Note**: The application is in development. Some features may be incomplete or being improved.



