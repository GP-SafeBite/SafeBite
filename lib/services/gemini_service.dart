// Gemini.service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyCtJbiIuu_eK8_YmBcGWK22Sw81Sk3vNq0";
  final String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  String _cleanJson(String text) {
    return text.replaceAll("```json", "").replaceAll("```", "").trim();
  }

  Future<Map<String, dynamic>> analyzeProductImage(Uint8List imageBytes) async {
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    const prompt = """
أنت خبير تغذية وسلامة غذائية متخصص في اكتشاف مسببات الحساسية.

المهمة:
تحليل صورة تحتوي على قائمة مكونات منتج غذائي، واستخراج مسببات الحساسية بدقة عالية، واقتراح بدائل تجارية من نفس نوع المنتج.

التعليمات:
1. اقرأ النص الظاهر في الصورة فقط (لا تخمّن مكونات غير موجودة).
2. استخرج مسببات الحساسية التالية إن وُجدت. لكل مكون:
- إذا كان مكتوباً بالعربية والإنجليزية معاً في الصورة → ادمجهما في نص واحد بهذا الشكل: "العربي (English)"
- إذا كان مكتوباً بالعربية فقط → اكتبه كما هو
- إذا كان مكتوباً بالإنجليزية فقط → اكتبه كما هو
- لا تفصل العربي والإنجليزي في عنصرين منفصلين، ادمجهما دائماً في عنصر واحد
- لا تترجم، لا تلخص، لا تضف شيئاً غير موجود في الصورة:
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
- "قد يحتوي على آثار من..."
- "مصنع في منشأة تتعامل مع..."
- أي جملة تبدأ بـ "May contain"
- أي جملة تبدأ بـ "قد يحتوي على"
- أي جملة تبدأ بـ "Contains:"
- أي جملة تبدأ بـ "يحتوي على:"

4. انتبه للأسماء غير المباشرة مثل:
- كازين، مصل اللبن = حليب
- ليسيثين الصويا = صويا
- مالت الشعير = غلوتين
- ثاني أكسيد الكبريت E220 = الكبريتيت
(Sulphur Dioxide (E220), Sodium Sulfite (E221), Sodium Bisulfite (E222), Potassium Metabisulfite (E224), وغيرها من E220–E228)
- أي E-code يدل على مسبب حساسية يجب إضافته إلى hidden_sources

في hidden_sources: أعد النص الكامل كما هو مكتوب في الصورة ولا تختصره إلى الرمز فقط.

اعرض كل مسبب حساسية بصيغة: "العربية (English)"

5. حدد نوع المنتج من مكوناته (مثل: زبادي، حليب، جبن، خبز، شوكولاتة، معكرونة، صلصة...) ثم اقترح 4-5 بدائل تجارية معبأة من نفس نوع المنتج:
- إذا كان المنتج زبادي بالحليب → اقترح: زبادي الصويا ألبرو، زبادي الشوفان أويلي، زبادي جوز الهند سيلك
- إذا كان المنتج مشروب حليب → اقترح: حليب الشوفان أويلي، حليب اللوز ألبرو، حليب الصويا ألبرو
- إذا كان المنتج جبن → اقترح: جبن نباتي فيوليف، جبن نباتي دايا، جبن كاشيو نباتي
- إذا كان المنتج خبز بالقمح → اقترح: خبز شار خالٍ من الجلوتين، خبز بي فري، خبز كانيون بيكهاوس
- إذا كان المنتج شوكولاتة → اقترح: شوكولاتة إنجوي لايف، لينت 85% داكن، شوكولاتة هيو
- إذا كان المنتج معكرونة → اقترح: معكرونة شار خالية من الجلوتين، باريلا خالية من الغلوتين
- إذا كان المنتج مايونيز → اقترح: مايونيز هيلمانز نباتي، فولو يور هارت فيجينيز
- إذا لم يتضح نوع المنتج → اقترح بدائل معروفة خالية من مسببات الحساسية المكتشفة

المخرجات يجب أن تكون بصيغة JSON فقط بدون شرح وبالشكل التالي:

{
  "product_type_ar": "",
  "detected_allergens": [
    {
      "allergen_type": "",
      "allergen_ar": "",
      "ingredients": ["", ""]
    }
  ],
  "hidden_sources": [],
  "warning_statements": [],
  "suggested_alternatives": [
    {
      "allergen_type": "",
      "product_type_ar": " ",
      "alternatives_ar": ["", ""]
    }
  ],
  "confidence": "high | medium | low | -"
}

قيم allergen_type المسموح بها فقط (بالإنجليزية الصغيرة):
milk, eggs, gluten, fish, peanuts, soybeans, treenuts, sesame, crustaceans, celery, mustard, sulfur, lupin, mollusks

Do not add explanations.
Do not wrap with backticks.
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
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
  throw Exception("RATE_LIMIT");
}

if (response.statusCode != 200) {
  throw Exception(response.body);
}

    final data = jsonDecode(response.body);
    final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
    print("🧠 RAW AI TEXT: $text");

    final cleaned = _cleanJson(text);
    print("🧠 CLEANED TEXT: $cleaned");

    try {
      return jsonDecode(cleaned);
    } catch (e) {
      print("❌ JSON ERROR: $e");
      return {
        "product_type_ar": "",
        "detected_allergens": [],
        "hidden_sources": [],
        "warning_statements": [],
        "suggested_alternatives": [],
        "confidence": "low",
        "raw": cleaned
      };
    }
  }
}