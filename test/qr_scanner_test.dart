import 'package:expense_tracker/services/qr_scanner_service.dart';
import 'package:expense_tracker/utils/mcc_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MCC Data Tests', () {
    test('MCC code 5411 correctly maps to Food and Supermarkets', () {
      final match = MccData.lookupMcc('5411');
      expect(match, isNotNull);
      expect(match!.$1, 'Food');
      expect(match.$2, contains('Supermarket'));
    });

    test('MCC code 5541 correctly maps to Transport and Fuel', () {
      final match = MccData.lookupMcc('5541');
      expect(match, isNotNull);
      expect(match!.$1, 'Transport');
      expect(match.$2, contains('Fuel'));
    });

    test('MCC code 5912 correctly maps to Health and Pharmacy', () {
      final match = MccData.lookupMcc('5912');
      expect(match, isNotNull);
      expect(match!.$1, 'Health');
      expect(match.$2, contains('Pharmacies'));
    });

    test('MCC code 5311 correctly maps to Shopping', () {
      final match = MccData.lookupMcc('5311');
      expect(match, isNotNull);
      expect(match!.$1, 'Shopping');
    });

    test('MCC code 4900 correctly maps to Bills and Utilities', () {
      final match = MccData.lookupMcc('4900');
      expect(match, isNotNull);
      expect(match!.$1, 'Bills');
    });

    test('MCC code 7832 correctly maps to Entertainment', () {
      final match = MccData.lookupMcc('7832');
      expect(match, isNotNull);
      expect(match!.$1, 'Entertainment');
    });

    test('Keyword fallback matches correctly', () {
      expect(MccData.detectFromKeywords('swiggy delivery'), 'Food');
      expect(MccData.detectFromKeywords('Uber Trip'), 'Transport');
      expect(MccData.detectFromKeywords('Apollo Pharmacy Ltd'), 'Health');
      expect(MccData.detectFromKeywords('Electricity Bill payment'), 'Bills');
      expect(MccData.detectFromKeywords('PVR Cinemas Mumbai'), 'Entertainment');
      expect(MccData.detectFromKeywords('Zara Fashion Store'), 'Shopping');
    });
  });

  group('QR Scanner Service Parsing Tests', () {
    test('Parses full UPI QR with MCC, Amount, and Merchant Name', () {
      const qr =
          'upi://pay?pa=supermarket@upi&pn=D-Mart%20Supermarket&mc=5411&am=350.50&cu=INR';
      final result = QrScannerService.parse(qr);

      expect(result.category, 'Food');
      expect(result.mcc, '5411');
      expect(result.amount, 350.50);
      expect(result.merchantName, 'D-Mart Supermarket');
      expect(result.merchantId, 'supermarket@upi');
      expect(result.displayTitle, 'D-Mart Supermarket');
    });

    test('Parses restaurant UPI QR with MCC 5812', () {
      const qr =
          'upi://pay?pa=starbucks@icici&pn=Starbucks%20Cafe&mc=5812&am=280.00';
      final result = QrScannerService.parse(qr);

      expect(result.category, 'Food');
      expect(result.mcc, '5812');
      expect(result.amount, 280.00);
      expect(result.displayTitle, 'Starbucks Cafe');
    });

    test('Parses petrol pump UPI QR with MCC 5541', () {
      const qr =
          'upi://pay?pa=indianoil@sbi&pn=Indian%20Oil&mc=5541&am=1000.00';
      final result = QrScannerService.parse(qr);

      expect(result.category, 'Transport');
      expect(result.mcc, '5541');
      expect(result.amount, 1000.00);
    });

    test('Parses UPI QR without MCC using keyword fallback on Payee Name', () {
      const qr = 'upi://pay?pa=swiggy@icici&pn=Swiggy%20Order&am=450.00';
      final result = QrScannerService.parse(qr);

      expect(result.category, 'Food');
      expect(result.amount, 450.00);
      expect(result.merchantName, 'Swiggy Order');
    });

    test('Parses EMVCo / BharatQR TLV QR code with Tag 52 (MCC)', () {
      // 000201 (version) 52045411 (MCC=5411) 5406120.00 (Amount=120.00) 5912KIRANA STORE (Name)
      const emv = '000201520454115406120.005912KIRANA STORE';
      final result = QrScannerService.parse(emv);

      expect(result.category, 'Food');
      expect(result.mcc, '5411');
      expect(result.amount, 120.00);
      expect(result.merchantName, 'KIRANA STORE');
    });

    test('Parses JSON QR payload', () {
      const json =
          '{"merchantName": "Apollo Med", "mc": "5912", "amount": 250.0}';
      final result = QrScannerService.parse(json);

      expect(result.category, 'Health');
      expect(result.mcc, '5912');
      expect(result.amount, 250.0);
      expect(result.merchantName, 'Apollo Med');
    });

    test('Parses direct 4-digit MCC code', () {
      final result = QrScannerService.parse('7832');
      expect(result.category, 'Entertainment');
      expect(result.mcc, '7832');
    });
  });
}
