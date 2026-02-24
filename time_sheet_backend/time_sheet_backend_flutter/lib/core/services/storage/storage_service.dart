import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_service.dart';

/// Wrapper around Supabase Storage for uploading/downloading files.
/// Handles PDFs, signatures, and expense receipt attachments.
class StorageService {
  final SupabaseClient _client;

  StorageService({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  String get _userId => SupabaseService.instance.currentUserId ?? '';

  // ============================================
  // PDF Operations
  // ============================================

  /// Upload a PDF file to storage.
  /// Path: pdfs/{userId}/{year}-{month}.pdf
  Future<String> uploadPdf({
    required Uint8List pdfBytes,
    required int year,
    required int month,
    String? customFileName,
  }) async {
    final rawFileName = customFileName ?? '$year-${month.toString().padLeft(2, '0')}.pdf';
    final fileName = sanitizeFileName(rawFileName);
    final path = '$_userId/$fileName';

    await _client.storage.from('pdfs').uploadBinary(
      path,
      pdfBytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: true,
      ),
    );

    return _client.storage.from('pdfs').getPublicUrl(path);
  }

  /// Download a PDF file from storage.
  Future<Uint8List> downloadPdf({
    required int year,
    required int month,
    String? customFileName,
  }) async {
    final fileName = customFileName ?? '$year-${month.toString().padLeft(2, '0')}.pdf';
    final path = '$_userId/$fileName';

    return await _client.storage.from('pdfs').download(path);
  }

  /// Download a PDF by its file name (for cross-device sync).
  Future<Uint8List?> downloadPdfByName(String fileName) async {
    try {
      final sanitized = sanitizeFileName(fileName);
      final path = '$_userId/$sanitized';
      return await _client.storage.from('pdfs').download(path);
    } catch (e) {
      debugPrint('Error downloading PDF by name: $e');
      return null;
    }
  }

  /// Get the signed URL for a PDF (time-limited access).
  Future<String> getPdfSignedUrl({
    required int year,
    required int month,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    final path = '$_userId/$year-${month.toString().padLeft(2, '0')}.pdf';
    return await _client.storage.from('pdfs').createSignedUrl(
      path,
      expiresIn.inSeconds,
    );
  }

  // ============================================
  // Signature Operations
  // ============================================

  /// Upload a signature image (PNG bytes).
  /// Path: signatures/{userId}/signature.png
  Future<String> uploadSignature(Uint8List signatureBytes) async {
    final path = '$_userId/signature.png';

    await _client.storage.from('signatures').uploadBinary(
      path,
      signatureBytes,
      fileOptions: const FileOptions(
        contentType: 'image/png',
        upsert: true,
      ),
    );

    return _client.storage.from('signatures').getPublicUrl(path);
  }

  /// Download the user's signature.
  Future<Uint8List?> downloadSignature() async {
    try {
      final path = '$_userId/signature.png';
      return await _client.storage.from('signatures').download(path);
    } catch (e) {
      debugPrint('No signature found: $e');
      return null;
    }
  }

  /// Download a specific user's signature (for managers viewing employee signatures).
  Future<Uint8List?> downloadSignatureForUser(String userId) async {
    try {
      final path = '$userId/signature.png';
      return await _client.storage.from('signatures').download(path);
    } catch (e) {
      debugPrint('No signature found for user $userId: $e');
      return null;
    }
  }

  /// Get signed URL for a signature.
  Future<String?> getSignatureUrl() async {
    try {
      final path = '$_userId/signature.png';
      return await _client.storage.from('signatures').createSignedUrl(
        path,
        3600, // 1 hour
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // Receipt Operations (Expense Attachments)
  // ============================================

  /// Upload an expense receipt image.
  /// Path: receipts/{userId}/{expenseId}.jpg
  Future<String> uploadReceipt({
    required String expenseId,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    final extension = contentType.split('/').last;
    final path = '$_userId/$expenseId.$extension';

    await _client.storage.from('receipts').uploadBinary(
      path,
      imageBytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    return _client.storage.from('receipts').getPublicUrl(path);
  }

  /// Upload a receipt from a file path.
  Future<String> uploadReceiptFromFile({
    required String expenseId,
    required String filePath,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final extension = filePath.split('.').last.toLowerCase();
    final contentType = _mimeType(extension);

    return uploadReceipt(
      expenseId: expenseId,
      imageBytes: bytes,
      contentType: contentType,
    );
  }

  /// Download a receipt.
  Future<Uint8List?> downloadReceipt(String expenseId) async {
    try {
      // Try common extensions
      for (final ext in ['jpg', 'jpeg', 'png', 'pdf']) {
        try {
          final path = '$_userId/$expenseId.$ext';
          return await _client.storage.from('receipts').download(path);
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading receipt: $e');
      return null;
    }
  }

  /// Get signed URL for a receipt.
  Future<String?> getReceiptSignedUrl(String receiptPath) async {
    try {
      return await _client.storage.from('receipts').createSignedUrl(
        receiptPath,
        3600,
      );
    } catch (e) {
      return null;
    }
  }

  /// Delete a receipt.
  Future<void> deleteReceipt(String expenseId) async {
    try {
      for (final ext in ['jpg', 'jpeg', 'png', 'pdf']) {
        try {
          await _client.storage.from('receipts').remove(['$_userId/$expenseId.$ext']);
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
    }
  }

  // ============================================
  // Employee PDFs (for managers)
  // ============================================

  /// Download an employee's PDF (manager access).
  Future<Uint8List?> downloadEmployeePdf({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final path = '$employeeId/$year-${month.toString().padLeft(2, '0')}.pdf';
      return await _client.storage.from('pdfs').download(path);
    } catch (e) {
      debugPrint('Error downloading employee PDF: $e');
      return null;
    }
  }

  /// Sanitize file name for Supabase Storage (no accented characters).
  static String sanitizeFileName(String name) {
    const replacements = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'à': 'a', 'â': 'a', 'ä': 'a',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'À': 'A', 'Â': 'A', 'Ä': 'A',
      'Î': 'I', 'Ï': 'I',
      'Ô': 'O', 'Ö': 'O',
      'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C',
    };
    var result = name;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String _mimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
