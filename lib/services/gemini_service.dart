import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class LlmScanResult {
  final List<String> detectedAllergens;
  final List<String> hiddenSources;
  final List<String> warningStatements;
  final List<String> safeAlternatives;
  final String confidence;
  final bool hasAllergens;

  LlmScanResult({
    required this.detectedAllergens,
    required this.hiddenSources,
    required this.warningStatements,
    required this.safeAlternatives,
    required this.confidence,
  }) : hasAllergens = detectedAllergens.isNotEmpty ||
            hiddenSources.isNotEmpty ||
            warningStatements.isNotEmpty;

  factory LlmScanResult.empty() {
    return LlmScanResult(
      detectedAllergens: [],
      hiddenSources: [],
      warningStatements: [],
      safeAlternatives: [],
      confidence: '-',
    );
  }

  factory LlmScanResult.fromJson(Map<String, dynamic> json) {
    return LlmScanResult(
      detectedAllergens: List<String>.from(
          json['detected_allergens'] ?? []),
      hiddenSources:
          List<String>.from(json['hidden_sources'] ?? []),
      warningStatements:
          List<String>.from(json['warning_statements'] ?? []),
      safeAlternatives:
          List<String>.from(json['safe_alternatives'] ?? []),
      confidence: json['confidence']?.toString() ?? '-',
    );
  }
}

class GeminiService {
  // ─────────────────────────────────────────────
  // IMPORTANT: Store this in a .env file
  // Never hardcode or commit to GitHub!
  // ─────────────────────────────────────────────
  static const String _apiKey = 'AIzaSyAPzAge7-nmcsdjUygCCcPcVcQq9ZrgBKw';

  static GenerativeModel? _model;

  static GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0,
      ),
    );
    return _model!;
  }

  // ──────────────────────────────────────────────
  // ANALYZE INGREDIENTS FOR ALLERGENS
  // Sends ingredients text to Gemini
  // Returns structured allergen detection result
  // ──────────────────────────────────────────────
  static Future<LlmScanResult> analyzeIngredients({
    required String ingredientsText,
    required List<String> userAllergyIds,
    required String productName,
    required String productCategory,
  }) async {
    try {
      if (ingredientsText.trim().isEmpty) {
        print('⚠️ Gemini: No ingredients text provided');
        return LlmScanResult.empty();
      }

      // Build user allergies list for prompt
      final userAllergiesText = userAllergyIds.isEmpty
          ? 'تحقق من جميع مسببات الحساسية الـ 14'
          : 'المستخدم لديه حساسية من: ${userAllergyIds.join(', ')}';

      final prompt = _buildPrompt(
        ingredientsText: ingredientsText,
        userAllergiesText: userAllergiesText,
        productName: productName,
        productCategory: productCategory,
      );

      final model = _getModel();
      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        print('⚠️ Gemini: Empty response');
        return LlmScanResult.empty();
      }

      print('✅ Gemini response received');

      // Clean response and parse JSON
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return LlmScanResult.fromJson(json);
    } catch (e) {
      print('❌ Gemini analysis error: $e');
      return LlmScanResult.empty();
    }
  }

  // ──────────────────────────────────────────────
  // BUILD PROMPT
  // Professional allergen detection prompt
  // ──────────────────────────────────────────────
  static String _buildPrompt({
    required String ingredientsText,
    required String userAllergiesText,
    required String productName,
    required String productCategory,
  }) {
    return '''
أنت خبير تغذية وسلامة غذائية متخصص في اكتشاف مسببات الحساسية.

معلومات المنتج:
- اسم المنتج: $productName
- الفئة: $productCategory
- $userAllergiesText

قائمة المكونات:
$ingredientsText

المهمة:
تحليل قائمة المكونات واكتشاف مسببات الحساسية بدقة عالية.

التعليمات:
1. اقرأ المكونات المذكورة فقط، لا تخمّن مكونات غير موجودة.
2. استخرج مسببات الحساسية التالية إن وُجدت، واكتب المكون الفعلي كما هو مكتوب ثم أدرجه تحت فئته:
   - الحليب ومشتقاته (Milk & Dairy)
   - البيض (Eggs)
   - الفول السوداني (Peanuts)
   - المكسرات (Tree Nuts)
   - الصويا (Soy)
   - القمح / الجلوتين (Wheat / Gluten)
   - السمك (Fish)
   - القشريات (Crustaceans)
   - السمسم (Sesame)
   - الكرفس (Celery)
   - الخردل (Mustard)
   - الترمس (Lupin)
   - الكبريتيت (Sulfites)
   - الرخويات (Molluscs)

3. اكتشف العبارات التحذيرية مثل:
   - "قد يحتوي على آثار من..."
   - "May contain traces of..."
   - "Contains:"
   - "يحتوي على:"
   - "Manufactured in a facility that also processes..."

4. انتبه للأسماء غير المباشرة مثل:
   - كازين، مصل اللبن، لاكتوز = حليب
   - ليسيثين الصويا = صويا
   - مالت الشعير = جلوتين
   - E220 إلى E228 = كبريتيت
   - أي E-code يدل على مسبب حساسية أضفه إلى hidden_sources

5. إذا تم اكتشاف أي حساسية يهتم بها المستخدم:
   - اقترح 3 إلى 5 منتجات بديلة آمنة ومتوفرة في السوق السعودية
   - اكتب اسم المنتج التجاري الحقيقي كما هو معروف في السعودية
   - لا تخترع منتجات غير موجودة
   - لا تكرر المنتج الأصلي
   - إذا لم تجد بدائل حقيقية اترك القائمة فارغة

اعرض كل مسبب حساسية بصيغة: "العربية (English)"

المخرجات يجب أن تكون بصيغة JSON فقط بدون أي شرح إضافي:

{
  "detected_allergens": [],
  "hidden_sources": [],
  "warning_statements": [],
  "safe_alternatives": [],
  "confidence": "high | medium | low | -"
}
''';
  }
}