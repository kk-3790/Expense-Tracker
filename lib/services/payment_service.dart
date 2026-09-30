import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/transaction_model.dart';
import 'transaction_service.dart';

class PaymentResult {
  final bool success;
  final String transactionRef;
  final double amount;
  final String recipient;
  final String note;
  final DateTime timestamp;
  final String? rawResponse;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.transactionRef,
    required this.amount,
    required this.recipient,
    required this.note,
    required this.timestamp,
    this.rawResponse,
    this.errorMessage,
  });
}

class PaymentService {
  /// Generate a realistic Google Pay / UPI Transaction Reference ID
  static String generateTransactionRef() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final randomDigits = (100000 + Random().nextInt(900000)).toString();
    return 'GPAY$year$month$day$randomDigits';
  }

  /// Launch Google Pay / UPI application with transaction parameters
  static Future<bool> launchGooglePay({
    required String upiId,
    required String payeeName,
    required double amount,
    required String note,
    String? transactionRef,
  }) async {
    final ref = transactionRef ?? generateTransactionRef();
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim().isEmpty ? 'Merchant' : payeeName.trim());
    final cleanNote = Uri.encodeComponent(note.trim().isEmpty ? 'Paisa Payment' : note.trim());
    final formattedAmount = amount.toStringAsFixed(2);

    // Candidates in priority order: Tez (Google Pay India), GPay, universal UPI
    final uris = [
      Uri.parse(
          'tez://upi/pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote&tr=$ref'),
      Uri.parse(
          'gpay://upi/pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote&tr=$ref'),
      Uri.parse(
          'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote&tr=$ref'),
    ];

    for (final uri in uris) {
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('[PaymentService] Error attempting $uri: $e');
      }
    }

    // Attempt universal upi uri directly
    try {
      final fallbackUri = Uri.parse(
          'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote&tr=$ref');
      return await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      debugPrint('[PaymentService] Universal UPI launch failed: $e');
      return false;
    }
  }

  /// Save Google Pay transaction response to Paisa database
  /// If [isPaid] is false, skips tracking and returns null so balance is untouched.
  static Future<TransactionModel?> recordGPayTransaction({
    required String recipient,
    required double amount,
    String category = 'Other',
    String note = 'Google Pay Transfer',
    String? transactionRef,
    bool isPaid = true,
  }) async {
    if (!isPaid) {
      debugPrint('[PaymentService] Payment not completed or cancelled by user. Not tracking.');
      return null;
    }

    final ref = transactionRef ?? generateTransactionRef();
    final now = DateTime.now();

    final tx = TransactionModel(
      id: 'gpay_${now.millisecondsSinceEpoch}',
      title: recipient.startsWith('Transfer to ')
          ? recipient
          : 'Transfer to $recipient',
      note: 'Google Pay (Ref: $ref) - $note',
      date: now,
      amount: amount,
      category: category,
      type: 'Expense',
    );

    await TransactionService.add(tx);
    return tx;
  }

  /// Create a PaymentResult for response display and audit
  static PaymentResult createPaymentResult({
    required bool isPaid,
    required String recipient,
    required double amount,
    required String note,
    String? transactionRef,
    String? errorMessage,
  }) {
    final ref = transactionRef ?? generateTransactionRef();
    return PaymentResult(
      success: isPaid,
      transactionRef: ref,
      amount: amount,
      recipient: recipient,
      note: note,
      timestamp: DateTime.now(),
      rawResponse: isPaid ? 'SUCCESS' : 'USER_CANCELLED_OR_NOT_PAID',
      errorMessage: errorMessage ??
          (isPaid ? null : 'User did not complete payment in Google Pay'),
    );
  }
}
