import 'dart:convert';
import 'package:http/http.dart' as http;

class SfdaProduct {
  final String barCode;
  final String brandName;
  final String tradeName;
  final String ingredientsAr;
  final String ingredientsEn;
  final String warnings;
  final String foodGroupEn;
  final String foodGroupAr;
  final String companyName;

  SfdaProduct({
    required this.barCode,
    required this.brandName,
    required this.tradeName,
    required this.ingredientsAr,
    required this.ingredientsEn,
    required this.warnings,
    required this.foodGroupEn,
    required this.foodGroupAr,
    required this.companyName,
  });

  factory SfdaProduct.fromJson(Map<String, dynamic> json) {
    return SfdaProduct(
      barCode: json['barCode']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      ingredientsAr: json['ingredientsAr']?.toString() ?? '',
      ingredientsEn: json['ingredientsEn']?.toString() ?? '',
      warnings: json['warnings']?.toString() ?? '',
      foodGroupEn: json['enFoodGroup']?.toString() ?? '',
      foodGroupAr: json['arFoodGroup']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
    );
  }

  String get combinedIngredients {
    final parts = <String>[];
    if (ingredientsEn.isNotEmpty) parts.add('English: $ingredientsEn');
    if (ingredientsAr.isNotEmpty) parts.add('Arabic: $ingredientsAr');
    if (warnings.isNotEmpty) parts.add('Warnings: $warnings');
    return parts.join('\n');
  }

  String get displayName {
    if (tradeName.isNotEmpty) return tradeName;
    if (brandName.isNotEmpty) return brandName;
    return 'منتج غير معروف';
  }
}

class SfdaService {
  static const String _consumerKey = 'x4AAA7VNjZYzOBeG980hx4beqlTxIChexX7OR13R8GnJH2z9';
  static const String _consumerSecret = 'YtxB8wb6m64SOambrVGR9d90SGOMoGtUWvu3LeA6kYOMkFopquhy0B4GrgvVYEmA';

  static const String _tokenUrl =
      'https://apis.sfda.gov.sa:9002/v2/oauth/accesstoken';
  static const String _productBaseUrl =
      'https://apis.sfda.gov.sa:9002/v2/Food';

  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  // ──────────────────────────────────────────────
  // GET ACCESS TOKEN — working method: query param
  // ──────────────────────────────────────────────
  static Future<String?> _getToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    try {
      final credentials =
          base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));

      final uri = Uri.parse(_tokenUrl).replace(
        queryParameters: {'grant_type': 'client_credentials'},
      );

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _cachedToken = json['access_token']?.toString();
        _tokenExpiry = DateTime.now().add(const Duration(hours: 23));
        print('✅ SFDA token obtained!');
        return _cachedToken;
      } else {
        print('❌ SFDA token failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ SFDA token exception: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // FIX INVALID JSON FROM SFDA API
  // SFDA returns unquoted string values — fix them
  // e.g. "key": someValue  →  "key": "someValue"
  // ──────────────────────────────────────────────
  static String _fixInvalidJson(String raw) {
    // Fix unquoted string values: "key": value,  →  "key": "value",
    // Handles: strings, Arabic text, dates without quotes
    // Does NOT touch: numbers, booleans, null, already-quoted strings
    return raw.replaceAllMapped(
      RegExp(r':\s*([^"{}\[\],\n][^,}\]\n]*)([,}\]\n])'),
      (match) {
        final value = match.group(1)!.trim();
        final terminator = match.group(2)!;

        // Skip if already a number, boolean, or null
        if (value == 'true' ||
            value == 'false' ||
            value == 'null' ||
            RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
          return ': $value$terminator';
        }

        // Wrap unquoted string in quotes
        return ': "${value.replaceAll('"', '\\"')}"$terminator';
      },
    );
  }

  // ──────────────────────────────────────────────
  // EXTRACT KEY FIELDS DIRECTLY WITH REGEX
  // More reliable than JSON parsing for bad JSON
  // ──────────────────────────────────────────────
  static String _extractField(String body, String field) {
    // Match: "field": "value" or "field": value
    final quoted = RegExp('"$field"\\s*:\\s*"([^"]*)"');
    final unquoted = RegExp('"$field"\\s*:\\s*([^,}\\]\\n]+)');

    final qMatch = quoted.firstMatch(body);
    if (qMatch != null) return qMatch.group(1)?.trim() ?? '';

    final uMatch = unquoted.firstMatch(body);
    if (uMatch != null) {
      final val = uMatch.group(1)?.trim() ?? '';
      // Remove trailing comma or brace
      return val.replaceAll(RegExp(r'[,}]$'), '').trim();
    }

    return '';
  }

  // ──────────────────────────────────────────────
  // FETCH PRODUCT BY BARCODE
  // ──────────────────────────────────────────────
  static Future<SfdaProduct?> fetchProductByBarcode(String barcode) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ Could not get SFDA token');
        return null;
      }

      final uri = Uri.parse('$_productBaseUrl/product/barcode/$barcode');
      print('📦 Fetching: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📦 Product status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body;

        // ✅ Extract fields directly with regex — avoids JSON parse errors
        final product = SfdaProduct(
          barCode: _extractField(body, 'barCode'),
          brandName: _extractField(body, 'brandName'),
          tradeName: _extractField(body, 'tradeName'),
          ingredientsAr: _extractField(body, 'ingredientsAr'),
          ingredientsEn: _extractField(body, 'ingredientsEn'),
          warnings: _extractField(body, 'warnings'),
          foodGroupEn: _extractField(body, 'enFoodGroup'),
          foodGroupAr: _extractField(body, 'arFoodGroup'),
          companyName: _extractField(body, 'companyName'),
        );

        print('✅ Product found: ${product.displayName}');
        print('📋 Ingredients EN: ${product.ingredientsEn}');
        print('📋 Ingredients AR: ${product.ingredientsAr}');

        return product;
      } else if (response.statusCode == 404) {
        print('⚠️ Product not found in SFDA for barcode $barcode');
        return null;
      } else if (response.statusCode == 401) {
        _cachedToken = null;
        _tokenExpiry = null;
        print('⚠️ Token expired — retrying...');
        return fetchProductByBarcode(barcode);
      } else {
        print('❌ SFDA error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('❌ SFDA fetch exception: $e');
      print('❌ Stack: $stack');
      return null;
    }
  }
}