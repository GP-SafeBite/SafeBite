// Gemini.service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyCtJbiIuu_eK8_YmBcGWK22Sw81Sk3vNq0";

  final String _baseUrl =
"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

 // 🔥 تنظيف JSON من ```json
  String _cleanJson(String text) {
    return text
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();
  }

  Future<Map<String, dynamic>> analyzeProductImage(
      Uint8List imageBytes) async {
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    const prompt = """
أنت خبير تغذية وسلامة غذائية متخصص في اكتشاف مسببات الحساسية.

المهمة:
تحليل صورة تحتوي على قائمة مكونات منتج غذائي، واستخراج مسببات الحساسية بدقة عالية.

التعليمات:
1. اقرأ النص الظاهر في الصورة فقط (لا تخمّن مكونات غير موجودة).
2. استخرج مسببات الحساسية التالية إن وُجدت ,لا تكتب اسم الفئة فقط (مثل: الحليب),بل اكتب المكون الفعلي كما هو مكتوب في الصورةوادرجة تحت اي فئة,إذا كان المكون باللغة الإنجليزية أعده كما هو,إذا كان بالعربية أعده كما هو, لا تترجم,لا تلخص :
- الحليب ومشتقاته (Milk & Dairy)
- البيض (Eggs)
- الفول السوداني (Peanuts)
- المكسرات (Tree Nuts)
- الصويا (Soy)
- القمح / الغلوتين (Wheat / Gluten)
- السمك (Fish)
- المحار (Shellfish)
- السمسم (Sesame)
- الكرفس (Celery)
- الخردل (Mustard)
- الترمس (Lupin)
- الكبريتيت (Sulfites)
- الرخويات (Molluscs)

3. اكتشف أيضًا العبارات التحذيرية مثل:
-"قد يحتوي على آثار من..."
-"مصنع في منشأة تتعامل مع..."
- أي جملة تبدأ بـ "May contain"
- أي جملة تبدأ بـ "قد يحتوي على"
- أي جملة تبدأ بـ "Contains:"
- أي جملة تبدأ بـ "يحتوي على:"

4. انتبه للأسماء غير المباشرة مثل:
- كازين، مصل اللبن = حليب
- ليسيثين الصويا = صويا
- مالت الشعير = غلوتين
- ثاني أكسيد الكبريت E220 = الكبريتيت
(Sulphur Dioxide (E220),
Sodium Sulfite (E221),
Sodium Bisulfite (E222),
Potassium Metabisulfite (E224),
وغيرها من E220–E228)
- أي E-code يدل على مسبب حساسية يجب إضافته إلى hidden_sources

في hidden_sources:
أعد النص الكامل كما هو مكتوب في الصورة
ولا تختصره إلى الرمز فقط.
مثال:
ثاني أكسيد الكبريت (E220)
Sulphur Dioxide (E220)

اعرض كل مسبب حساسية بصيغة:
"العربية (English)"

المخرجات يجب أن تكون بصيغة JSON فقط بدون شرح وبالشكل التالي:

{
  "detected_allergens": [],
  "hidden_sources": [],
  "warning_statements": [],
  "confidence": "high | medium | low | - "
}
Do not add explanations.
Do not wrap with ```json.
""";

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Encode(imageBytes)
                }
              }
            ]
          }
        ],
        "generationConfig": {"temperature": 0}
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 429) {
  throw Exception("RATE_LIMIT");
}

if (response.statusCode != 200) {
  throw Exception(response.body);
}

    final data = jsonDecode(response.body);
    final text =
        data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
   print("🧠 RAW AI TEXT: $text");

    final cleaned = _cleanJson(text);

    print("🧠 CLEANED TEXT: $cleaned");

    try {
      return jsonDecode(cleaned);
    } catch (e) {
      print("❌ JSON ERROR: $e");

      return {
        "detected_allergens": [],
        "hidden_sources": [],
        "warning_statements": [],
        "confidence": "low",
        "raw": cleaned
      };
    }
  }
}