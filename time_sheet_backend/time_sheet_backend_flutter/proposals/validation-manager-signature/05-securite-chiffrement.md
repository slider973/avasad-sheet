# Sécurité et Chiffrement - Système de Validation

## Vue d'ensemble de la sécurité

### Architecture de sécurité multicouche

```
┌─────────────────────────────────────────────────────────┐
│                   Couche Application                      │
│  - Authentification biométrique                          │
│  - Validation des entrées                                │
│  - Sanitization des données                              │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   Couche Transport                        │
│  - TLS 1.3 obligatoire                                  │
│  - Certificate pinning                                   │
│  - HSTS (HTTP Strict Transport Security)                │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   Couche Données                          │
│  - Chiffrement AES-256-GCM                              │
│  - Clés dérivées par organisation                       │
│  - Rotation automatique des clés                        │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   Couche Infrastructure                   │
│  - Row Level Security (RLS) Supabase                    │
│  - Isolation par tenant                                 │
│  - Audit logs complets                                  │
└─────────────────────────────────────────────────────────┘
```

## 1. Authentification et autorisation

### Authentification Supabase avec JWT

```dart
// lib/services/auth/secure_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';

class SecureAuthService {
  final SupabaseClient _supabase;
  final LocalAuthentication _localAuth;
  
  SecureAuthService(this._supabase) : _localAuth = LocalAuthentication();
  
  // Connexion sécurisée avec biométrie
  Future<AuthResponse> secureSignIn({
    required String email,
    required String password,
  }) async {
    // 1. Vérifier la biométrie si disponible
    if (await _localAuth.canCheckBiometrics) {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à l\'application',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (!authenticated) {
        throw AuthException('Authentification biométrique échouée');
      }
    }
    
    // 2. Connexion Supabase
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // 3. Vérifier la validité du JWT
    await _validateJWT(response.session?.accessToken);
    
    // 4. Configurer la rotation automatique des tokens
    _setupTokenRotation();
    
    return response;
  }
  
  Future<void> _validateJWT(String? token) async {
    if (token == null) throw AuthException('Token manquant');
    
    // Décoder et vérifier le JWT
    final jwt = JWT.decode(token);
    
    // Vérifier l'expiration
    if (jwt.isExpired) {
      throw AuthException('Token expiré');
    }
    
    // Vérifier l'issuer
    if (jwt.issuer != 'https://[project-ref].supabase.co/auth/v1') {
      throw AuthException('Issuer invalide');
    }
  }
  
  void _setupTokenRotation() {
    // Rafraîchir le token 5 minutes avant expiration
    Timer.periodic(Duration(minutes: 55), (_) async {
      await _supabase.auth.refreshSession();
    });
  }
}
```

### Gestion des rôles et permissions

```dart
// lib/services/auth/permission_service.dart
class PermissionService {
  static const Map<String, List<String>> rolePermissions = {
    'employee': [
      'timesheet:create',
      'timesheet:read:own',
      'timesheet:update:own',
      'validation:create',
      'validation:read:own',
    ],
    'manager': [
      'timesheet:read:assigned',
      'validation:read:assigned',
      'validation:update:assigned',
      'validation:sign',
      'feedback:create',
    ],
    'admin': [
      'timesheet:read:all',
      'validation:read:all',
      'user:manage',
      'organization:manage',
    ],
  };
  
  Future<bool> hasPermission(String permission) async {
    final user = await _getCurrentUser();
    final userRole = user.role;
    
    return rolePermissions[userRole]?.contains(permission) ?? false;
  }
  
  Future<void> checkPermission(String permission) async {
    if (!await hasPermission(permission)) {
      throw PermissionException('Permission refusée: $permission');
    }
  }
}
```

## 2. Chiffrement des données

### Service de chiffrement AES-256-GCM

```dart
// lib/services/security/encryption_service.dart
import 'package:encrypt/encrypt.dart';
import 'dart:typed_data';
import 'dart:convert';

class EncryptionService {
  static const int KEY_SIZE = 32; // 256 bits
  static const int IV_SIZE = 16;  // 128 bits
  static const int TAG_SIZE = 16; // 128 bits
  
  // Dériver une clé spécifique à l'organisation
  Future<Key> _deriveOrganizationKey(String organizationId) async {
    // Récupérer le master key depuis le secure storage
    final masterKey = await _secureStorage.read(key: 'master_key');
    if (masterKey == null) {
      throw SecurityException('Master key non trouvé');
    }
    
    // Dériver une clé spécifique avec PBKDF2
    final salt = utf8.encode('org_$organizationId');
    final pbkdf2 = PBKDF2(iterations: 100000);
    final key = pbkdf2.generateKey(masterKey, salt, KEY_SIZE);
    
    return Key(Uint8List.fromList(key));
  }
  
  // Chiffrer des données avec AES-256-GCM
  Future<EncryptedData> encrypt({
    required Uint8List data,
    required String organizationId,
    Map<String, String>? additionalData,
  }) async {
    try {
      // 1. Générer un IV aléatoire
      final iv = IV.fromSecureRandom(IV_SIZE);
      
      // 2. Obtenir la clé de l'organisation
      final key = await _deriveOrganizationKey(organizationId);
      
      // 3. Créer l'encrypter avec AES-GCM
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      
      // 4. Construire les données additionnelles authentifiées (AAD)
      final aad = _buildAAD(organizationId, additionalData);
      
      // 5. Chiffrer les données
      final encrypted = encrypter.encryptBytes(
        data,
        iv: iv,
        associatedData: aad,
      );
      
      // 6. Retourner les données chiffrées avec métadonnées
      return EncryptedData(
        ciphertext: encrypted.bytes,
        iv: iv.bytes,
        tag: encrypted.tag,
        organizationId: organizationId,
        timestamp: DateTime.now(),
        additionalData: additionalData,
      );
      
    } catch (e) {
      throw SecurityException('Erreur de chiffrement: $e');
    }
  }
  
  // Déchiffrer des données
  Future<Uint8List> decrypt({
    required EncryptedData encryptedData,
    required String organizationId,
  }) async {
    try {
      // 1. Vérifier l'organisation
      if (encryptedData.organizationId != organizationId) {
        throw SecurityException('Organisation non autorisée');
      }
      
      // 2. Vérifier l'expiration (si applicable)
      if (encryptedData.expiresAt != null && 
          DateTime.now().isAfter(encryptedData.expiresAt!)) {
        throw SecurityException('Données expirées');
      }
      
      // 3. Obtenir la clé
      final key = await _deriveOrganizationKey(organizationId);
      
      // 4. Reconstruire l'IV et l'encrypted
      final iv = IV(encryptedData.iv);
      final encrypted = Encrypted(encryptedData.ciphertext);
      
      // 5. Créer le decrypter
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      
      // 6. Reconstruire l'AAD
      final aad = _buildAAD(organizationId, encryptedData.additionalData);
      
      // 7. Déchiffrer
      final decrypted = encrypter.decryptBytes(
        encrypted,
        iv: iv,
        associatedData: aad,
      );
      
      return Uint8List.fromList(decrypted);
      
    } catch (e) {
      throw SecurityException('Erreur de déchiffrement: $e');
    }
  }
  
  // Construire les données additionnelles authentifiées
  Uint8List _buildAAD(String organizationId, Map<String, String>? additional) {
    final aadMap = {
      'org_id': organizationId,
      'version': '1.0',
      'algorithm': 'AES-256-GCM',
      ...?additional,
    };
    
    return utf8.encode(jsonEncode(aadMap));
  }
}

// Modèle pour les données chiffrées
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List? tag;
  final String organizationId;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final Map<String, String>? additionalData;
  
  EncryptedData({
    required this.ciphertext,
    required this.iv,
    this.tag,
    required this.organizationId,
    required this.timestamp,
    this.expiresAt,
    this.additionalData,
  });
  
  // Sérialisation pour stockage
  Map<String, dynamic> toJson() => {
    'ciphertext': base64Encode(ciphertext),
    'iv': base64Encode(iv),
    'tag': tag != null ? base64Encode(tag!) : null,
    'organization_id': organizationId,
    'timestamp': timestamp.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'additional_data': additionalData,
  };
  
  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    ciphertext: base64Decode(json['ciphertext']),
    iv: base64Decode(json['iv']),
    tag: json['tag'] != null ? base64Decode(json['tag']) : null,
    organizationId: json['organization_id'],
    timestamp: DateTime.parse(json['timestamp']),
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    additionalData: json['additional_data']?.cast<String, String>(),
  );
}
```

### Chiffrement des PDFs

```dart
// lib/services/security/pdf_encryption_service.dart
class PDFEncryptionService {
  final EncryptionService _encryptionService;
  
  PDFEncryptionService(this._encryptionService);
  
  // Chiffrer un PDF avec métadonnées
  Future<EncryptedPDF> encryptPDF({
    required Uint8List pdfBytes,
    required String organizationId,
    required String employeeId,
    required String validationId,
  }) async {
    // 1. Calculer le hash du PDF pour intégrité
    final hash = SHA256Hasher().hash(pdfBytes);
    
    // 2. Compresser le PDF
    final compressed = ZLibEncoder().encode(pdfBytes);
    
    // 3. Chiffrer avec métadonnées
    final encrypted = await _encryptionService.encrypt(
      data: Uint8List.fromList(compressed),
      organizationId: organizationId,
      additionalData: {
        'employee_id': employeeId,
        'validation_id': validationId,
        'content_type': 'application/pdf',
        'original_size': pdfBytes.length.toString(),
        'compressed_size': compressed.length.toString(),
        'hash': base64Encode(hash),
      },
    );
    
    return EncryptedPDF(
      encryptedData: encrypted,
      originalHash: hash,
      compressionRatio: compressed.length / pdfBytes.length,
    );
  }
  
  // Déchiffrer et vérifier l'intégrité
  Future<Uint8List> decryptPDF({
    required EncryptedPDF encryptedPDF,
    required String organizationId,
  }) async {
    // 1. Déchiffrer
    final compressed = await _encryptionService.decrypt(
      encryptedData: encryptedPDF.encryptedData,
      organizationId: organizationId,
    );
    
    // 2. Décompresser
    final decompressed = ZLibDecoder().decodeBytes(compressed);
    
    // 3. Vérifier l'intégrité
    final hash = SHA256Hasher().hash(decompressed);
    if (!_compareHashes(hash, encryptedPDF.originalHash)) {
      throw SecurityException('Intégrité du PDF compromise');
    }
    
    return Uint8List.fromList(decompressed);
  }
  
  bool _compareHashes(List<int> hash1, List<int> hash2) {
    if (hash1.length != hash2.length) return false;
    
    // Comparaison temps constant pour éviter timing attacks
    var result = 0;
    for (var i = 0; i < hash1.length; i++) {
      result |= hash1[i] ^ hash2[i];
    }
    return result == 0;
  }
}
```

## 3. Sécurité du transport

### Certificate Pinning

```dart
// lib/services/security/certificate_pinning.dart
import 'package:dio/dio.dart';
import 'package:dio_certificate_pinning/dio_certificate_pinning.dart';

class SecureHttpClient {
  late Dio _dio;
  
  SecureHttpClient() {
    _dio = Dio();
    _setupCertificatePinning();
    _setupSecurityHeaders();
  }
  
  void _setupCertificatePinning() {
    // Pins SHA256 des certificats Supabase
    final supabasePins = [
      'sha256/AbCdEfGhIjKlMnOpQrStUvWxYz1234567890=', // Production
      'sha256/ZyXwVuTsRqPoNmLkJiHgFeDcBa0987654321=', // Backup
    ];
    
    _dio.interceptors.add(
      CertificatePinningInterceptor(
        allowedSHAFingerprints: supabasePins,
        timeout: 30,
      ),
    );
  }
  
  void _setupSecurityHeaders() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Ajouter les headers de sécurité
          options.headers.addAll({
            'X-Client-Version': '1.0.0',
            'X-Request-ID': Uuid().v4(),
            'X-Timestamp': DateTime.now().toIso8601String(),
          });
          
          handler.next(options);
        },
      ),
    );
  }
}
```

## 4. Stockage sécurisé local

### Secure Storage pour clés sensibles

```dart
// lib/services/security/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'secure_prefs',
      preferencesKeyPrefix: 'secure_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'timesheet_secure',
    ),
  );
  
  // Initialiser le master key au premier lancement
  static Future<void> initializeMasterKey() async {
    final existingKey = await _storage.read(key: 'master_key');
    
    if (existingKey == null) {
      // Générer un nouveau master key
      final random = Random.secure();
      final masterKey = List.generate(32, (_) => random.nextInt(256));
      
      await _storage.write(
        key: 'master_key',
        value: base64Encode(masterKey),
      );
    }
  }
  
  // Rotation des clés
  static Future<void> rotateMasterKey() async {
    // 1. Générer nouvelle clé
    final newKey = _generateSecureKey();
    
    // 2. Re-chiffrer toutes les données avec la nouvelle clé
    await _reencryptAllData(newKey);
    
    // 3. Remplacer l'ancienne clé
    await _storage.write(
      key: 'master_key',
      value: base64Encode(newKey),
    );
    
    // 4. Logger la rotation
    await _logKeyRotation();
  }
}
```

## 5. Protection contre les attaques

### Rate Limiting

```dart
// lib/services/security/rate_limiter.dart
class RateLimiter {
  final Map<String, List<DateTime>> _attempts = {};
  
  bool checkLimit({
    required String identifier,
    required int maxAttempts,
    required Duration window,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    
    // Nettoyer les anciennes tentatives
    _attempts[identifier]?.removeWhere((time) => time.isBefore(cutoff));
    
    // Vérifier la limite
    final attemptCount = _attempts[identifier]?.length ?? 0;
    if (attemptCount >= maxAttempts) {
      return false; // Limite atteinte
    }
    
    // Enregistrer la nouvelle tentative
    _attempts[identifier] ??= [];
    _attempts[identifier]!.add(now);
    
    return true;
  }
}

// Utilisation pour login
class LoginService {
  final _rateLimiter = RateLimiter();
  
  Future<void> attemptLogin(String email, String password) async {
    // Vérifier le rate limit
    if (!_rateLimiter.checkLimit(
      identifier: email,
      maxAttempts: 5,
      window: Duration(minutes: 15),
    )) {
      throw SecurityException('Trop de tentatives. Réessayez dans 15 minutes.');
    }
    
    // Procéder au login...
  }
}
```

### Protection CSRF

```dart
// lib/services/security/csrf_protection.dart
class CSRFProtection {
  static String generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  static Future<void> validateToken(String token) async {
    final storedToken = await SecureStorage.read(key: 'csrf_token');
    
    if (storedToken == null || storedToken != token) {
      throw SecurityException('Token CSRF invalide');
    }
  }
}
```

## 6. Audit et logs

### Service d'audit sécurisé

```dart
// lib/services/security/audit_service.dart
class AuditService {
  Future<void> logSecurityEvent({
    required SecurityEventType type,
    required String userId,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    final event = {
      'id': Uuid().v4(),
      'type': type.toString(),
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'ip_address': await _getIpAddress(),
      'device_id': await _getDeviceId(),
      'details': details,
      'metadata': metadata,
    };
    
    // Signer l'événement pour intégrité
    final signature = await _signEvent(event);
    event['signature'] = signature;
    
    // Envoyer vers Supabase
    await supabase
      .from('security_audit_logs')
      .insert(event);
  }
  
  Future<String> _signEvent(Map<String, dynamic> event) async {
    final json = jsonEncode(event);
    final hmac = Hmac(sha256, utf8.encode(await _getSigningKey()));
    final digest = hmac.convert(utf8.encode(json));
    return digest.toString();
  }
}

enum SecurityEventType {
  login_success,
  login_failed,
  logout,
  permission_denied,
  data_access,
  data_modification,
  key_rotation,
  suspicious_activity,
}
```

## 7. Conformité RGPD

### Anonymisation et droit à l'oubli

```dart
// lib/services/security/gdpr_service.dart
class GDPRService {
  // Anonymiser les données utilisateur
  Future<void> anonymizeUser(String userId) async {
    // 1. Remplacer les données personnelles
    await supabase
      .from('users')
      .update({
        'email': 'anonymized_$userId@deleted.com',
        'full_name': 'Utilisateur Supprimé',
        'fcm_token': null,
        'preferences': {},
        'anonymized_at': DateTime.now().toIso8601String(),
      })
      .eq('id', userId);
    
    // 2. Supprimer les signatures
    await _deleteUserSignatures(userId);
    
    // 3. Anonymiser les validations
    await _anonymizeValidations(userId);
    
    // 4. Logger l'action
    await _auditService.logSecurityEvent(
      type: SecurityEventType.data_modification,
      userId: 'system',
      details: 'User anonymized per GDPR request',
      metadata: {'affected_user': userId},
    );
  }
}
```

## Checklist de sécurité

- [ ] Authentification forte avec biométrie
- [ ] Chiffrement AES-256-GCM pour toutes les données sensibles
- [ ] Certificate pinning pour toutes les connexions
- [ ] Rate limiting sur toutes les endpoints sensibles
- [ ] Audit logs pour toutes les actions critiques
- [ ] Rotation automatique des clés tous les 90 jours
- [ ] Tests de pénétration réguliers
- [ ] Conformité RGPD avec droit à l'oubli
- [ ] Backup chiffré des données
- [ ] Plan de réponse aux incidents