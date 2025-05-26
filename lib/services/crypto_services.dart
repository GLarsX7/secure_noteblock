import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class CryptoService {
  static const int _saltLength = 32;
  static const int _iterations = 100000;
  
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }
  
  static Uint8List _pbkdf2(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64.decode(salt);
    
    final hmac = Hmac(sha256, passwordBytes);
    final iterations = _iterations;
    final keyLength = 32;
    
    Uint8List derivedKey = Uint8List(keyLength);
    Uint8List block = Uint8List(keyLength);
    
    for (int i = 1; i <= (keyLength + 31) ~/ 32; i++) {
      final u = Uint8List(saltBytes.length + 4);
      u.setRange(0, saltBytes.length, saltBytes);
      u[saltBytes.length] = (i >> 24) & 0xff;
      u[saltBytes.length + 1] = (i >> 16) & 0xff;
      u[saltBytes.length + 2] = (i >> 8) & 0xff;
      u[saltBytes.length + 3] = i & 0xff;
      
      Uint8List uPrev = Uint8List.fromList(hmac.convert(u).bytes);
      block.setRange(0, uPrev.length, uPrev);
      
      for (int j = 1; j < iterations; j++) {
        uPrev = Uint8List.fromList(hmac.convert(uPrev).bytes);
        for (int k = 0; k < uPrev.length; k++) {
          block[k] ^= uPrev[k];
        }
      }
      
      final start = (i - 1) * 32;
      final end = (start + 32 > keyLength) ? keyLength : start + 32;
      derivedKey.setRange(start, end, block);
    }
    
    return derivedKey;
  }
  
  static Encrypter createEncrypter(String password, String salt) {
    final key = _pbkdf2(password, salt);
    final encryptionKey = Key(key);
    return Encrypter(AES(encryptionKey));
  }
  
  static String encrypt(String plaintext, String password, String salt) {
    final encrypter = createEncrypter(password, salt);
    final iv = IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
  
  static String decrypt(String ciphertext, String password, String salt) {
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) throw Exception('Invalid ciphertext format');
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = createEncrypter(password, salt);
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed');
    }
  }
}