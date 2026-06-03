// Product Service - Retrieve product information from the Open Food Facts API by barcode

import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  // Fetch product name and ingredients from Open Food Facts using the given barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          return {
            "productName":
                data['product']['product_name'] ?? "منتج غير معروف",
            "ingredients":
                data['product']['ingredients_text'] ?? "لا توجد مكونات"
          };
        }
      }

      return null;
    } catch (e) {
      print("🔥 Exception: $e");
      return null;
    }
  }
}