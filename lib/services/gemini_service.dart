import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyC4B3EAdDJh4Oge_qhJwzkyRLZw0zNMwq8";
  final String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  String _cleanJson(String text) {
    return text.replaceAll("```json", "").replaceAll("```", "").trim();
  }

  Future<Map<String, dynamic>> analyzeProductImage(
    Uint8List imageBytes, {
    String productName = '',
    String userAllergies = '',
  }) async {
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    final prompt = """
أنت خبير تغذية وسلامة غذائية متخصص في قراءة ملصقات الأغذية واكتشاف مسببات الحساسية في السوق السعودي.

المهمة:
تحليل صورة قائمة مكونات منتج غذائي، استخراج مسببات الحساسية بدقة، واقتراح بدائل تجارية حقيقية متوفرة في السوق السعودي.

السياق:
اسم المنتج المُدخل من المستخدم: ${productName.isEmpty ? 'غير محدد' : productName}
الحساسيات التي يجب تجنبها: ${userAllergies.isEmpty ? 'غير محددة' : userAllergies}

التعليمات:
1. اقرأ النص الظاهر في الصورة فقط ولا تخمّن مكونات غير موجودة.
2. إذا كان اسم المنتج واضحاً ومفيداً، استخدمه لتحديد نوع المنتج. إذا كان فارغاً أو غير واضح، استنتج نوع المنتج من المكونات الظاهرة في الصورة.
3. استخرج مسببات الحساسية التالية إن وُجدت بشرط أن تكون ضمن الحساسيات التي حددها المستخدم، وضعها في detected_allergens. لكل مسبب حساسية مكتشف:
    * استخرج المكونات (ingredients) التي تسببت في هذا التنبيه كما وردت في النص.
    * قاعدة الدمج: إذا كان المكون مكتوباً بالعربية والإنجليزية معاً في الصورة، ادمجهما في عنصر واحد هكذا: "العربي (English)".
    * إذا كان بلغة واحدة → اكتبه كما هو.
    * لا تفصل العربي والإنجليزي في عنصرين منفصلين داخل مصفوفة المكونات.
    * لا تترجم، لا تلخص. الفئات الـ 14 المعتمدة:
    * الحليب ومشتقاته (Milk & Dairy)
    * البيض (Eggs)
    * الفول السوداني (Peanuts)
    * المكسرات (Tree Nuts)
    * الصويا (Soy)
    * القمح / الغلوتين (Wheat / Gluten)
    * السمك (Fish)
    * المحار (Shellfish)
    * السمسم (Sesame)
    * الكرفس (Celery)
    * الخردل (Mustard)
    * الترمس (Lupin)
    * الكبريتيت (Sulfites)
    * الرخويات (Molluscs)
4. ابحث عن المصادر الخفية مثل:
    * كازين، مصل اللبن = حليب
    * ليسيثين الصويا = صويا
    * مالت الشعير = غلوتين
    * E220–E228 = الكبريتيت
    ضعها في hidden_sources مع النص الكامل كما ورد في الصورة فقط إذا كانت تخص الحساسيات المحددة.
5. استخرج العبارات التحذيرية المتعلقة بالحساسيات المحددة فقط مثل:
    * "قد يحتوي على آثار من..."
    * "May contain"
    * "مصنع في منشأة تتعامل مع..."
    * "Contains:"
6. اقترح بدائل تجارية معبأة من نفس فئة المنتج خالية تماماً من الحساسيات المحددة (من 1 إلى 5 بدائل كحد أقصى):
    * حدد نوع المنتج أولاً من اسمه أو مكوناته (زبادي، حليب سائل، جبن، خبز، شوكولاتة، معكرونة، مايونيز...)
    * اقترح بديلاً من نفس النوع تماماً: إذا كان زبادي → بديل زبادي، إذا كان جبن → بديل جبن، إذا كان حليب → بديل حليب
    * يجب أن يكون البديل منتجاً تجارياً محدداً بعلامة تجارية حقيقية
    * حدد المتجر/المتاجر السعودية المحددة (بنده، كارفور، التميمي، الدانوب، لولو، بن داود، نينجا)
    * يُمنع اختراع منتجات وهمية — الاكتفاء ببديل واحد حقيقي أفضل من اختراع خمسة
    * إذا كان المنتج آمناً → اترك suggested_alternatives فارغة []
    * قاعدة التوافر: إذا كانت العلامة التجارية محلية سعودية أو عالمية مؤكدة الوجود → available_in_saudi: true
    * إذا كان هناك شك → available_in_saudi: false

قواعد مهمة:
* إذا لم تجد مسببات تطابق الحساسيات المحددة → تكون detected_allergens فارغة [].
* لا تذكر مسببات حساسية غير مطلوبة من المستخدم.
* لا تخترع شيئاً غير موجود في الصورة.

قيم allergen_type المسموح بها (إنجليزية صغيرة فقط):
milk, eggs, gluten, fish, peanuts, soybeans, treenuts, sesame, crustaceans, celery, mustard, sulfur, lupin, mollusks

حقل product_category:
✅ يجب أن يكون إحدى هذه القيم الثابتة بالضبط (بالإنجليزية) بناءً على نوع المنتج الممسوح:

-- الحليب ومنتجات الألبان --
- plant-based milk          → حليب سائل (أبقار، ماعز، كامل الدسم، خالي الدسم...)
- plant-based yogurt        → زبادي / لبن رائب
- plant-based labneh        → لبنة
- plant-based cheese        → جبن بأي نوع (شيدر، موزاريلا، كريم چيز...)
- plant-based butter        → زبدة / مارجرين
- plant-based ghee          → سمن
- dairy-free cream          → كريمة طبخ / كريمة خفق
- dairy-free ice cream      → آيس كريم / جيلاتو
- dairy-free milkshake      → ميلك شيك / مشروب حليب منكّه
- dairy-free custard        → كاسترد / كريم بروليه

-- الشوكولاتة والحلويات --
- dairy-free chocolate          → شوكولاتة ألواح
- dairy-free chocolate-spread   → سبريد شوكولاتة (نوتيلا وما شابه)
- nut-free chocolate            → شوكولاتة تحتوي على مكسرات (عند البحث عن بديل بدون مكسرات)
- free-from candy               → حلوى / ماصات / جيلي
- free-from halawa              → حلاوة طحينية

-- المخبوزات --
- gluten-free bread         → خبز / توست / باغيت / صمون
- gluten-free pita          → خبز عربي / خبز مسطح / خبز تنور
- gluten-free pastry        → كرواسان / دانيش / باستري
- dairy-free cake           → كيك / مافن / كب كيك / براونيز
- free-from pancake-mix     → خليط بان كيك / وافل

-- المعكرونة والحبوب --
- gluten-free pasta         → معكرونة / باستا
- gluten-free noodles       → نودلز / شعرية
- gluten-free cereal        → حبوب إفطار / كورن فليكس / مسلي
- gluten-free oats          → شوفان
- gluten-free granola       → غرانولا
- gluten-free flour-mix     → دقيق / خليط خبيز

-- البسكويت والسناكس --
- gluten-free biscuit       → بسكويت / كوكيز / ويفر / كراكر
- free-from chips           → شيبس / كرسبي
- nut-free snack-bar        → بار طاقة / بار حبوب
- free-from popcorn         → فشار

-- المنكّهات والصلصات --
- vegan mayo                → مايونيز
- nut-free peanut-butter-alt → زبدة فول سوداني (عند الحاجة لبديل بدون مكسرات)
- sesame-free tahini-alt    → طحينة / سبريد سمسم
- free-from salad-dressing  → صوص سلطة / ديب
- gluten-free soy-sauce     → صلصة صويا / تاماري
- nut-free pesto            → بيستو
- free-from sauce           → صوص جاهز (بيتزا، مكرونة...)

-- المشروبات --
- dairy-free coffee-creamer → كريمر / مبيض قهوة
- dairy-free hot-chocolate  → مسحوق شوكولاتة ساخنة
- free-from protein-shake   → مسحوق بروتين / ميل ريبليسمنت
- dairy-free cooking-cream  → كريمة طبخ مخصصة

-- الشوربات --
- free-from soup            → شوربة جاهزة / مركز شوربة

- ""                        → إذا لم يتطابق مع أي فئة أعلاه

المخرجات JSON فقط بدون أي شرح وبدون علامات التنصيص:
{
  "product_type_ar": "",
  "product_category": "",
  "detected_allergens": [
    {
      "allergen_type": "",
      "allergen_ar": "",
      "ingredients": []
    }
  ],
  "hidden_sources": [],
  "warning_statements": [],
  "is_safe_for_user": true,
  "suggested_alternatives": [
    {
      "name": "",
      "allergen_type": "",
      "available_in_saudi": true,
      "availability_status": "",
      "found_in_stores": []
    }
  ],
  "confidence": "high"
}
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

    if (response.statusCode != 200) throw Exception(response.body);

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
        "product_category": "",
        "detected_allergens": [],
        "hidden_sources": [],
        "warning_statements": [],
        "is_safe_for_user": true,
        "suggested_alternatives": [],
        "confidence": "low",
        "raw": cleaned
      };
    }
  }
}