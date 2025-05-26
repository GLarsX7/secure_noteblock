import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';
import '../services/storage_service.dart';
import 'notes_list_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const LoginScreen({super.key, required this.onThemeToggle});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricAvailable = false; // State to check if biometrics are available

  bool get _isNewUser => !StorageService.hasPassword;

  @override
  void initState() {
    super.initState();
    if (!_isNewUser) {
      _checkBiometricSupport(); // Check biometric support for existing users only
    }
  }

  Future<void> _checkBiometricSupport() async {
    final auth = LocalAuthentication();
    try {
      final canAuthenticate = await auth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _biometricAvailable = canAuthenticate;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = LocalAuthentication();

    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Log in to access your notes',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        final storedPassword = await StorageService.getPasswordFromSecureStorage();
        if (storedPassword != null) {
          _navigateToNotes(storedPassword);
        } else {
          setState(() {
            _errorMessage = 'Password not found. Please reset it in settings.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      String message = 'Biometric authentication error: ${e.message}';
      switch (e.code) {
        case 'NotAvailable':
          message = 'Biometrics not available on this device';
        case 'NotEnrolled':
          message = 'Biometrics not configured on device';
        case 'LockedOut':
          message = 'Autenticação bloqueada. Tente novamente mais tarde';
        default:
          message = 'Unknown error: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro desconhecido na autenticação';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Password cannot be empty';
        _isLoading = false;
      });
      return;
    }

    try {
      if (_isNewUser) {
        final confirmPassword = _confirmPasswordController.text;
        if (password != confirmPassword) {
          setState(() {
            _errorMessage = 'Passwords do not match';
            _isLoading = false;
          });
          return;
        }

        if (password.length < 6) {
          setState(() {
            _errorMessage = 'Password must be at least 6 characters long';
            _isLoading = false;
          });
          return;
        }

        await StorageService.setPassword(password);
        _navigateToNotes(password);
      } else {
        if (StorageService.verifyPassword(password)) {
          _navigateToNotes(password);
        } else {
          setState(() {
            _errorMessage = 'Incorrect password';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error has occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _navigateToNotes(String password) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => NotesListScreen(
          password: password,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure NoteBlock'),
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              _isNewUser ? 'Create a Password' : 'Enter your Password',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isNewUser
                  ? 'This password will encrypt all your notes. Remember it carefully.!'
                  : 'Enter your master password to access your encrypted notes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_isNewUser && _biometricAvailable)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Biometric Login'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            TextField(
              controller: _passwordController,
              obscureText: _isObscured,
              decoration: InputDecoration(
                labelText: 'Master Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
            if (_isNewUser) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _isConfirmObscured,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
                    icon: Icon(_isConfirmObscured ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isNewUser ? 'Create Password' : 'Login'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}