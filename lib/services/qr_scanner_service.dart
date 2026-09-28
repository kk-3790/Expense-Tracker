import 'dart:convert';
import '../utils/mcc_data.dart';

/// Parsed merchant QR code details.
class ParsedMerchantQr {
  final String rawData;
  final String? merchantName;
  final String? merchantId; // UPI ID (VPA) or Merchant ID
  final String? mcc;        // 4-digit Merchant Category Code
  final String? mccDescription;
  final double? amount;
  final String category;    // Auto-categorized expense category
  final String matchMethod; // How category was identified (e.g. MCC vs Keyword)
  final String? note;

  const ParsedMerchantQr({
    required this.rawData,
    this.merchantName,
    this.merchantId,
    this.mcc,
    this.mccDescription,
    this.amount,
    required this.category,
    required this.matchMethod,
    this.note,
  });

  /// Formatted title for the transaction, prioritizing merchant name.
  String get displayTitle {
    if (merchantName != null && merchantName!.trim().isNotEmpty) {
      return merchantName!.trim();
    }
    if (merchantId != null && merchantId!.trim().isNotEmpty) {
      return merchantId!.trim();
    }
    return category;
  }
}

class QrScannerService {
  /// Parses raw QR code string and identifies merchant details and category.
  static ParsedMerchantQr parse(String raw) {
    final trimmed = raw.trim();

    // 1. UPI QR Code (upi://pay?...)
    if (trimmed.toLowerCase().startsWith('upi://') || trimmed.contains('pa=')) {
      return _parseUpiQr(trimmed);
    }

    // 2. EMVCo / BharatQR TLV format (starts with 000201...)
    if (trimmed.startsWith('000201')) {
      final emvResult = _parseEmvCo(trimmed);
      if (emvResult != null) return emvResult;
    }

    // 3. JSON format
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final jsonResult = _parseJson(trimmed);
      if (jsonResult != null) return jsonResult;
    }

    // 4. Fallback / Plain text or standalone MCC code
    return _parseGenericText(trimmed);
  }

  // ============================================================
  // UPI QR PARSER
  // ============================================================
  static ParsedMerchantQr _parseUpiQr(String raw) {
    String? pa;
    String? pn;
    String? mc;
    double? am;
    String? tn;

    try {
      final uri = Uri.parse(raw);
      final params = uri.queryParameters;

      pa = params['pa'];
      pn = params['pn'];
      mc = params['mc'];
      tn = params['tn'];

      if (params.containsKey('am')) {
        am = double.tryParse(params['am'] ?? '');
      }
    } catch (_) {
      // Manual regex fallback if Uri.parse fails
      final paMatch = RegExp(r'[?&]pa=([^&]+)').firstMatch(raw);
      if (paMatch != null) pa = Uri.decodeComponent(paMatch.group(1)!);

      final pnMatch = RegExp(r'[?&]pn=([^&]+)').firstMatch(raw);
      if (pnMatch != null) pn = Uri.decodeComponent(pnMatch.group(1)!);

      final mcMatch = RegExp(r'[?&]mc=([^&]+)').firstMatch(raw);
      if (mcMatch != null) mc = mcMatch.group(1);

      final amMatch = RegExp(r'[?&]am=([^&]+)').firstMatch(raw);
      if (amMatch != null) am = double.tryParse(amMatch.group(1)!);

      final tnMatch = RegExp(r'[?&]tn=([^&]+)').firstMatch(raw);
      if (tnMatch != null) tn = Uri.decodeComponent(tnMatch.group(1)!);
    }

    // Clean up merchant name
    if (pn != null) {
      pn = pn.replaceAll('+', ' ').trim();
    }

    return _determineCategory(
      raw: raw,
      merchantName: pn,
      merchantId: pa,
      mcc: mc,
      amount: am,
      note: tn,
    );
  }

  // ============================================================
  // EMVCO / BHARATQR PARSER (Tag-Length-Value format)
  // ============================================================
  static ParsedMerchantQr? _parseEmvCo(String raw) {
    try {
      String? mcc;
      String? merchantName;
      double? amount;
      String? upiId;

      int i = 0;
      while (i + 4 <= raw.length) {
        final tag = raw.substring(i, i + 2);
        final len = int.tryParse(raw.substring(i + 2, i + 4));
        if (len == null || i + 4 + len > raw.length) break;

        final val = raw.substring(i + 4, i + 4 + len);
        i += 4 + len;

        if (tag == '52') {
          // Merchant Category Code
          mcc = val;
        } else if (tag == '54') {
          // Transaction Amount
          amount = double.tryParse(val);
        } else if (tag == '59') {
          // Merchant Name
          merchantName = val;
        } else if (tag == '26' || tag == '27') {
          // Sub-tags for UPI VPA (usually tag 01 is upi@bank)
          if (val.contains('@')) {
            upiId = val;
          }
        }
      }

      return _determineCategory(
        raw: raw,
        merchantName: merchantName,
        merchantId: upiId,
        mcc: mcc,
        amount: amount,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // JSON FORMAT PARSER
  // ============================================================
  static ParsedMerchantQr? _parseJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final mc = decoded['mc']?.toString() ?? decoded['mcc']?.toString();
        final name = decoded['name']?.toString() ??
            decoded['merchantName']?.toString() ??
            decoded['pn']?.toString();
        final id = decoded['pa']?.toString() ??
            decoded['merchantId']?.toString() ??
            decoded['vpa']?.toString();
        final amountNum = decoded['amount'] ?? decoded['am'];
        final amount = amountNum is num
            ? amountNum.toDouble()
            : double.tryParse(amountNum?.toString() ?? '');

        return _determineCategory(
          raw: raw,
          merchantName: name,
          merchantId: id,
          mcc: mc,
          amount: amount,
          note: decoded['note']?.toString(),
        );
      }
    } catch (_) {}
    return null;
  }

  // ============================================================
  // GENERIC TEXT / DIRECT MCC INPUT
  // ============================================================
  static ParsedMerchantQr _parseGenericText(String raw) {
    // If exactly 4 digits, check if it's an MCC code directly
    final trimmed = raw.trim();
    if (RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return _determineCategory(
        raw: raw,
        mcc: trimmed,
      );
    }

    return _determineCategory(
      raw: raw,
      merchantName: raw,
    );
  }

  // ============================================================
  // CATEGORY RESOLVER (MCC -> Keywords -> Default)
  // ============================================================
  static ParsedMerchantQr _determineCategory({
    required String raw,
    String? merchantName,
    String? merchantId,
    String? mcc,
    double? amount,
    String? note,
  }) {
    // 1. Direct MCC Lookup (Highest accuracy)
    if (mcc != null && mcc.trim().isNotEmpty) {
      final lookup = MccData.lookupMcc(mcc.trim());
      if (lookup != null) {
        return ParsedMerchantQr(
          rawData: raw,
          merchantName: merchantName,
          merchantId: merchantId,
          mcc: mcc.trim(),
          mccDescription: lookup.$2,
          amount: amount,
          category: lookup.$1,
          matchMethod: 'MCC Code: $mcc (${lookup.$2})',
          note: note,
        );
      }
    }

    // 2. Keyword fallback on merchant name and merchant ID
    final combinedText = '${merchantName ?? ""} ${merchantId ?? ""} ${note ?? ""}';
    final keywordCategory = MccData.detectFromKeywords(combinedText);
    if (keywordCategory != null) {
      return ParsedMerchantQr(
        rawData: raw,
        merchantName: merchantName,
        merchantId: merchantId,
        mcc: mcc,
        amount: amount,
        category: keywordCategory,
        matchMethod: 'Auto-detected from merchant name',
        note: note,
      );
    }

    // 3. Fallback
    return ParsedMerchantQr(
      rawData: raw,
      merchantName: merchantName,
      merchantId: merchantId,
      mcc: mcc,
      amount: amount,
      category: 'Other',
      matchMethod: 'Default Category (Other)',
      note: note,
    );
  }
}
