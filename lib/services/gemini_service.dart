// gemini_service.dart — SafeBite optimised build

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = 'AIzaSyCaONW2r35n8FYWBffo4cSNDw10Ax7ZvmU';
  static const _model  = 'gemini-2.5-flash';
  static const _base   =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model';

  static final http.Client _http = http.Client();

  static Future<Uint8List> _compress(Uint8List raw) =>
      FlutterImageCompress.compressWithList(
        raw,
        minWidth: 1280, minHeight: 1280,
        quality: 80, format: CompressFormat.jpeg, keepExif: false,
      );

  static const _sysInstruction = '''
ROLE: Food allergen classifier. Input: ingredient label image. Output: JSON only.

HARD RULES
H1: Read ONLY text visible in image. Do not infer or add unseen ingredients.
H2: Do not use world knowledge unless ingredient is visible on label.
H3: unreadable image OR no ingredient list => confidence=low, all arrays=[], is_safe_for_user=true.
H4: readable but uncertain ingredient/allergen mapping => treat as unsafe.
H5: is_safe_for_user=false if ANY user allergen detected. No exceptions.
H6: is_safe_for_user=true => detected_allergens=[], hidden_sources=[], warning_statements=[].
H7: No duplicate ingredient across detected_allergens, hidden_sources, warning_statements.
H8: detected_allergens and hidden_sources must only contain allergens relevant to the user's allergy list.
H9: Every allergen in detected_allergens must link to a visible ingredient string.

PRODUCT CATEGORY RULE
1. If productName is provided OR product label is clearly visible => use it as primary signal.
2. If not clear => infer category from ingredients.
3. If still uncertain => set product_category = "other".

E-NUMBER RULES
E322, E442 => soybeans. ALWAYS place in hidden_sources with allergen_type=soybeans if user
  has soy allergy. Do NOT skip even if soy/sunflower source is unlabelled on the package.
  Exception ONLY if label explicitly contains "sunflower lecithin" or "tournesol".
E471, E472 => milk OR soybeans (flag whichever matches user allergy; flag both if both match).
E120 => animal-derived (flag if relevant allergy).
E220-E228 => sulfur (flag if sulfur allergy).
E1404, E1422, E1442 => gluten (flag if gluten allergy).
E153 => warning only.
unknown E-number => warning_statements.

E-NUMBER OVERRIDE
If label contains E322 or E442 AND user has soybeans allergy:
  - hidden_sources MUST include { allergen_type: "soybeans", ingredient: "E322" } (or E442).
  - is_safe_for_user MUST be false.
  - This overrides H3 and H6. No exceptions.

SEPARATION RULES
peanuts ≠ treenuts. Always separate even when both in profile.
coconut ≠ treenuts. sesame ≠ treenuts.
"(no peanuts)" on label => never flag peanuts regardless of treenuts in profile.

CLAIM VERIFICATION
Marketing claims ("Dairy Free", "Vegan") never override ingredient evidence.
Flavor words alone (cream, butter) are insufficient unless explicit milk derivative also appears.

FIELD BOUNDARIES
detected_allergens.ingredients: direct visible allergen ingredients only.
hidden_sources: derivatives not already in detected_allergens (casein, soy lecithin, barley malt, E-numbers).
warning_statements: may-contain / cross-contamination text matching user allergies only.
No item appears in more than one of these three fields.

INGREDIENT FORMAT
Arabic+English both visible => merge as "عربي (English)" — Arabic first, English in parentheses.
Arabic only => Arabic as-is.
English only => English as-is.
Never list the same ingredient twice in different formats.

ALTERNATIVES
Max 3. Free from ALL user allergies.
Allowed brands: Alpro, Oatly, Violife, Schär, Enjoy Life, Bob\'s Red Mill, So Delicious, Silk, Kite Hill, Barilla GF, San-J, Hellmann\'s Vegan, Follow Your Heart, Daiya, Good Karma, Califia Farms.
Format: "Brand ProductName" only. No descriptions.
Safe product => suggested_alternatives=[].

ORDER
1. Extract all visible ingredient text verbatim from image.
2. Apply E-number rules to every E-number found. Apply E-NUMBER OVERRIDE before anything else.
3. Match each ingredient against user allergies.
4. Identify hidden sources not already in detected_allergens.
5. Extract warning statements matching user allergies only.
6. Set is_safe_for_user=false if any match found.
7. Select up to 3 alternatives free from ALL user allergies.
8. Verify JSON matches responseSchema.
''';

  static const _schema = {
    'type': 'OBJECT',
    'required': [
      'is_safe_for_user',
      'product_type_ar',
      'product_category',
      'confidence',
      'detected_allergens',
      'hidden_sources',
      'warning_statements',
      'suggested_alternatives',
    ],
    'properties': {
      'is_safe_for_user': {'type': 'BOOLEAN'},

      'product_type_ar': {'type': 'STRING'},

      'product_category': {
        'type': 'STRING',
        'enum': [
          'milk', 'yogurt', 'labneh', 'cheese', 'butter', 'ghee',
          'cream', 'ice-cream', 'milkshake', 'custard', 'cooking-cream',
          'chocolate', 'chocolate-spread', 'candy', 'halawa',
          'bread', 'pita', 'pastry', 'cake', 'pancake-mix',
          'pasta', 'noodles', 'cereal', 'oats', 'granola', 'flour-mix',
          'biscuit', 'chips', 'snack-bar', 'popcorn',
          'mayo', 'salad-dressing', 'soy-sauce', 'pesto', 'sauce',
          'coffee-creamer', 'hot-chocolate', 'protein-shake', 'soup',
          'plant-based milk', 'plant-based labneh',
          'dairy-free custard', 'dairy-free cooking-cream',
          'dairy-free chocolate-spread', 'dairy-free cake',
          'gluten-free pasta', 'gluten-free cereal', 'gluten-free biscuit',
          'gluten-free cracker', 'gluten-free bread', 'gluten-free flour-mix',
          'gluten-free oats', 'gluten-free granola', 'gluten-free chocolate',
          'free-from chips', 'free-from energy-bar', 'free-from candy',
          'free-from pancake-mix', 'other',
        ],
      },

      'confidence': {
        'type': 'STRING',
        'enum': ['high', 'medium', 'low'],
      },

      'detected_allergens': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'required': ['allergen_type', 'allergen_ar', 'ingredients'],
          'properties': {
            'allergen_type': {
              'type': 'STRING',
              'enum': [
                'milk', 'eggs', 'gluten', 'fish', 'peanuts', 'soybeans',
                'treenuts', 'sesame', 'crustaceans', 'celery', 'mustard',
                'sulfur', 'lupin', 'mollusks',
              ],
            },
            'allergen_ar':  {'type': 'STRING'},
            'ingredients': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
          },
        },
      },

      'hidden_sources': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'required': ['allergen_type', 'ingredient'],
          'properties': {
            'allergen_type': {
              'type': 'STRING',
              'enum': [
                'milk', 'eggs', 'gluten', 'fish', 'peanuts', 'soybeans',
                'treenuts', 'sesame', 'crustaceans', 'celery', 'mustard',
                'sulfur', 'lupin', 'mollusks',
              ],
            },
            'ingredient': {'type': 'STRING'},
          },
        },
      },

      'warning_statements': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },

      'suggested_alternatives': {
  'type': 'ARRAY',
  'items': {
    'type': 'OBJECT',
    'required': ['name'],
    'properties': {
      'name': {'type': 'STRING'},
    },
  },
},
    },
  };

  String _buildPrompt(String productName, String userAllergies) =>
      'Product: ${productName.isEmpty ? 'not provided' : productName}\n'
      'Allergies: ${userAllergies.isEmpty ? 'none' : userAllergies}';

  static Map<String, dynamic> _empty() => {
    'is_safe_for_user':      true,
    'product_type_ar':       '',
    'product_category':      'other',
    'confidence':            'low',
    'detected_allergens':    <dynamic>[],
    'hidden_sources':        <dynamic>[],
    'warning_statements':    <dynamic>[],
    'suggested_alternatives': <dynamic>[],
  };

  Future<Map<String, dynamic>> analyzeProductImage(
    Uint8List imageBytes, {
    String productName   = '',
    String userAllergies = '',
    void Function(bool isSafe)? onSafetySignal,
  }) async {
    final compressed = await _compress(imageBytes);
    final b64        = base64Encode(compressed);
    debugPrint('📸 Compressed: ${imageBytes.length} → ${compressed.length} bytes');

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _sysInstruction}],
      },
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data':      b64,
              },
            },
            {'text': _buildPrompt(productName, userAllergies)},
          ],
        },
      ],
'generationConfig': {
  'temperature':      0,
  'maxOutputTokens':  1024,
  'responseMimeType': 'application/json',
  'responseSchema':   _schema,
  'thinkingConfig':   {'thinkingBudget': 0},
},
    });

    final url = Uri.parse('$_base:streamGenerateContent?alt=sse&key=$_apiKey');

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final req = http.Request('POST', url)
          ..headers['Content-Type'] = 'application/json'
          ..body = body;

        final streamed = await _http.send(req)
            .timeout(const Duration(seconds: 30));

        if (streamed.statusCode == 200) {
          return await _collectStream(
            streamed.stream,
            onSafetySignal: onSafetySignal,
          );
        }

        final errBody = await streamed.stream.bytesToString();
        if (streamed.statusCode >= 400 && streamed.statusCode < 500) {
          throw Exception('Gemini ${streamed.statusCode}: $errBody');
        }
        if (attempt == 2) throw Exception('Gemini ${streamed.statusCode}: $errBody');
      } catch (e) {
        if (attempt == 2) rethrow;
        debugPrint('⚠️ Attempt $attempt failed, retrying in 300ms: $e');
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    return _empty();
  }

  Future<Map<String, dynamic>> _collectStream(
    Stream<List<int>> raw, {
    void Function(bool isSafe)? onSafetySignal,
  }) async {
    final buf        = StringBuffer();
    bool signalFired = false;

    final lines = raw
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      if (data.isEmpty || data == '[DONE]') continue;

      try {
        final chunk = jsonDecode(data) as Map<String, dynamic>;
        final text  = chunk['candidates']?[0]?['content']?['parts']?[0]
                ?['text'] as String? ?? '';
        buf.write(text);

        if (!signalFired && onSafetySignal != null) {
          try {
            final partial = jsonDecode(buf.toString()) as Map<String, dynamic>;
            if (partial.containsKey('is_safe_for_user')) {
              signalFired = true;
              onSafetySignal(partial['is_safe_for_user'] as bool? ?? true);
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    final full = buf.toString();
    debugPrint('🧠 AI RESULT: $full');

    try {
      return jsonDecode(full) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ JSON ERROR: $e');
      return _empty();
    }
  }
}