# Secure NoteBlock

A secure, encrypted note-taking application built with Flutter that provides end-to-end encryption for your personal notes with biometric authentication support.

## Features

- **End-to-End Encryption**: All notes are encrypted using AES encryption with PBKDF2 key derivation
- **Biometric Authentication**: Support for fingerprint and face recognition login
- **Cross-Platform**: Runs on Android, iOS, Windows, macOS, and Linux
- **Secure Storage**: Master password stored securely using Flutter Secure Storage
- **Material Design 3**: Modern UI with light and dark theme support
- **Local Storage**: All data stored locally using Hive database - no cloud dependencies

## Security Features

- **AES-256 Encryption**: Military-grade encryption for note content
- **PBKDF2 Key Derivation**: 100,000 iterations with 32-byte salt
- **Secure Password Hashing**: SHA-256 with random salt generation
- **Biometric Integration**: Platform-native biometric authentication
- **No Data Transmission**: All encryption/decryption happens locally

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher)
- **Dart SDK** (2.17.0 or higher)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development - macOS only)
- **Visual Studio** (for Windows development)

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/secure-noteblock.git
cd secure-noteblock
```

### 2. Configure flutter project
```bash
flutter create .
```
### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Generate Required Files

The project uses Hive for local storage, which requires code generation:

```bash
flutter packages pub run build_runner build
```

### 5. Platform-Specific Setup

#### Android Setup

1. **Minimum SDK Requirements**: Ensure your `android/app/build.gradle` has:
   ```gradle
   android {
       compileSdkVersion 34
       
       defaultConfig {
           minSdkVersion 23
           targetSdkVersion 34
       }
   }
   ```

2. **Permissions**: Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC" />
   <uses-permission android:name="android.permission.USE_FINGERPRINT" />
   ```

3. **Biometric Authentication**: The app automatically handles biometric setup on Android 6.0+

#### iOS Setup

1. **Minimum iOS Version**: Ensure `ios/Runner/Info.plist` has:
   ```xml
   <key>MinimumOSVersion</key>
   <string>12.0</string>
   ```

2. **Biometric Permissions**: Add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Use Face ID to securely access your encrypted notes</string>
   ```

3. **Keychain Access**: Add to `ios/Runner/Runner.entitlements`:
   ```xml
   <key>keychain-access-groups</key>
   <array>
       <string>$(AppIdentifierPrefix)com.yourcompany.noteblock</string>
   </array>
   ```

#### Windows Setup

1. **Visual Studio Requirements**: Install Visual Studio 2022 with C++ desktop development tools
2. **Windows SDK**: Ensure Windows 10 SDK (10.0.17763.0) or later is installed

#### macOS Setup

1. **macOS Version**: Requires macOS 10.14 or later
2. **Xcode**: Install Xcode 12.0 or later

#### Linux Setup

1. **Dependencies**: Install required Linux dependencies:
   ```bash
   sudo apt-get update
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
   ```

## Running the Application

### Development Mode

#### Android
```bash
flutter run -d android
```

#### iOS (macOS only)
```bash
flutter run -d ios
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### Linux
```bash
flutter run -d linux
```

#### Web (Limited functionality - no biometrics)
```bash
flutter run -d chrome
```

### Production Builds

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

#### iOS (macOS only)
```bash
flutter build ios --release
```

#### Windows
```bash
flutter build windows --release
```

#### macOS
```bash
flutter build macos --release
```

#### Linux
```bash
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/
│   ├── note.dart               # Note data model
│   └── note.g.dart             # Generated Hive adapter
├── screens/
│   ├── login_screen.dart       # Authentication screen
│   ├── notes_list_screen.dart  # Main notes list view
│   ├── note_editor_screen.dart # Note creation/editing
│   └── note_viewer_screen.dart # Note viewing screen
└── services/
    ├── storage_service.dart    # Local storage management
    ├── crypto_service.dart     # Encryption/decryption
    └── crypto_services.dart    # Cryptographic utilities
```

## Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `hive`: Local database
- `hive_flutter`: Flutter integration for Hive
- `flutter_secure_storage`: Secure credential storage
- `local_auth`: Biometric authentication
- `crypto`: Cryptographic functions
- `encrypt`: Encryption library

### Development Dependencies
- `build_runner`: Code generation
- `hive_generator`: Hive adapter generation

## Usage

### First Time Setup
1. Launch the application
2. Create a master password (minimum 6 characters)
3. The password will be used to encrypt all your notes

### Authentication
- **Password Login**: Enter your master password
- **Biometric Login**: Use fingerprint/face recognition (if available)

### Managing Notes
- **Create**: Tap the + button to create a new encrypted note
- **Edit**: Tap on any note to view, then use the edit button
- **Delete**: Use the menu options to delete notes
- **Auto-save**: Notes are automatically encrypted and saved

## Security Considerations

### Encryption Details
- **Algorithm**: AES-256 in CBC mode
- **Key Derivation**: PBKDF2 with SHA-256
- **Iterations**: 100,000 rounds
- **Salt**: 256-bit random salt per password
- **IV**: Random 128-bit initialization vector per note

### Data Storage
- **Encrypted Data**: All note content is encrypted before storage
- **Master Password**: Hashed using SHA-256 with unique salt
- **Biometric Backup**: Master password securely stored for biometric access
- **Local Only**: No data transmitted over networks

### Best Practices
- Choose a strong master password
- Enable biometric authentication for convenience
- Regular backups recommended (export functionality to be added)
- Keep the app updated for security patches

## Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean build cache
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### Biometric Authentication Not Working
- Ensure device has biometric hardware
- Verify biometric authentication is set up in device settings
- Check app permissions for biometric access

#### Encryption/Decryption Errors
- Verify master password is correct
- Check for corrupted local storage
- Try clearing app data and re-creating password

### Platform-Specific Issues

#### Android
- **Minimum API Level**: Requires Android 6.0+ (API 23) for full functionality
- **Permissions**: Ensure biometric permissions are granted

#### iOS
- **iOS Version**: Requires iOS 12.0 or later
- **Face ID**: Requires explicit permission in Info.plist

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guide
- Add tests for new features
- Update documentation as needed
- Ensure security best practices

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Privacy Policy

Secure NoteBlock is designed with privacy in mind:
- **No Data Collection**: We don't collect any personal data
- **Local Storage Only**: All notes remain on your device
- **No Analytics**: No usage tracking or analytics
- **Open Source**: Code is open for security auditing

## Support

For support, bug reports, or feature requests:
- Create an issue on GitHub
- Check existing issues for solutions
- Refer to Flutter documentation for platform-specific issues

## Roadmap

- [ ] Note categories and tags
- [ ] Search functionality
- [ ] Export/Import capabilities
- [ ] Note sharing (encrypted)
- [ ] Backup and sync options
- [ ] Rich text formatting
- [ ] Attachment support

---

**⚠️ Important Security Notice**: This application provides strong encryption for your notes, but the security ultimately depends on your master password strength and device security. Use a strong, unique password and keep your device updated.
