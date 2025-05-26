import 'package:flutter_secure_storage/flutter_secure_storage.dart' show FlutterSecureStorage;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noteblock/services/crypto_services.dart' show CryptoService;
import '../models/note.dart';
import 'crypto_service.dart';

class StorageService {
  static const String _notesBoxName = 'notes';
  static const String _authBoxName = 'auth';
  static const String _passwordHashKey = 'password_hash';
  static const String _saltKey = 'salt';
  
  static late Box<Note> _notesBox;
  static late Box _authBox;
  
  static Future<void> initialize() async {
    _notesBox = await Hive.openBox<Note>(_notesBoxName);
    _authBox = await Hive.openBox(_authBoxName);
  }
  
  static bool get hasPassword => _authBox.containsKey(_passwordHashKey);
  
  static final _secureStorage = const FlutterSecureStorage(); // Instance for secure storage

  // Method to save password in secure storage
  static Future<void> _savePasswordToSecureStorage(String password) async {
    await _secureStorage.write(key: 'master_password', value: password);
  }

  // Method to recover secure storage password
  static Future<String?> getPasswordFromSecureStorage() async {
    return await _secureStorage.read(key: 'master_password');
  }

  // Atualize o método setPassword para salvar no armazenamento seguro
  static Future<void> setPassword(String password) async {
    final salt = CryptoService.generateSalt();
    final hash = CryptoService.hashPassword(password, salt);
    
    await _authBox.put(_passwordHashKey, hash);
    await _authBox.put(_saltKey, salt);
    
    // Saves password in secure storage (for biometric use)
    await _savePasswordToSecureStorage(password);
  }
  
  static bool verifyPassword(String password) {
    if (!hasPassword) return false;
    
    final storedHash = _authBox.get(_passwordHashKey) as String;
    final salt = _authBox.get(_saltKey) as String;
    final inputHash = CryptoService.hashPassword(password, salt);
    
    return storedHash == inputHash;
  }
  
  static String get salt => _authBox.get(_saltKey) as String;
  
  static List<Note> getAllNotes() {
    return _notesBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  static Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
  }
  
  static Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }
  
  static Note? getNote(String noteId) {
    return _notesBox.get(noteId);
  }
  
  static String decryptTitle(Note note, String password) {
    return CryptoService.decrypt(note.encryptedTitle, password, salt);
  }
  
  static String decryptContent(Note note, String password) {
    return CryptoService.decrypt(note.encryptedContent, password, salt);
  }
  
  static Note createEncryptedNote(String title, String content, String password) {
    final encryptedTitle = CryptoService.encrypt(title, password, salt);
    final encryptedContent = CryptoService.encrypt(content, password, salt);
    
    return Note.create(
      encryptedTitle: encryptedTitle,
      encryptedContent: encryptedContent,
    );
  }
  
  static Note updateEncryptedNote(Note note, String title, String content, String password) {
    note.encryptedTitle = CryptoService.encrypt(title, password, salt);
    note.encryptedContent = CryptoService.encrypt(content, password, salt);
    note.updatedAt = DateTime.now();
    return note;
  }
}