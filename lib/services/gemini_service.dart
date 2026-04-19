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
أنت خبير تغذية وسلامة غذائية متخصص في قراءة ملصقات الأغذية واكتشاف مسببات الحساسية.

المهمة:
تحليل صورة قائمة مكونات منتج غذائي واستخراج مسببات الحساسية بدقة تامة.

السياق:
اسم المنتج المُدخل من المستخدم: ${productName.isEmpty ? 'غير محدد' : productName}
الحساسيات التي يجب تجنبها: ${userAllergies.isEmpty ? 'غير محددة' : userAllergies}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
تعليمات استخراج المكونات:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. اقرأ النص الظاهر في الصورة فقط. لا تخمّن ولا تضف مكونات غير موجودة.

2. تحديد نوع المنتج:
   - إذا كان اسم المنتج واضحاً → استخدمه لتحديد النوع.
   - إذا كان فارغاً أو غير واضح → استنتج النوع من المكونات الظاهرة.

3. استخراج المكونات في detected_allergens:
   - استخرج فقط المسببات التي تطابق حساسيات المستخدم المحددة أعلاه.
   - لكل مسبب، استخرج المكونات كما وردت حرفياً في النص.
   - قاعدة اللغة المزدوجة: إذا ظهر المكون بالعربية والإنجليزية معاً → ادمجهما:
     مثال: "لوز (almond)" أو "قمح (wheat)"
   - إذا كان بلغة واحدة فقط → اكتبه كما هو بدون ترجمة.
   - لا تفصل النسختين في عنصرين منفصلين.

4. المصادر الخفية — ابحث عنها وضعها في hidden_sources:
   - كازين / مصل اللبن / whey / casein → حليب (milk)
   - ليسيتين الصويا / soy lecithin → صويا (soybeans)
   - مالت الشعير / barley malt → جلوتين (gluten)
   - E220 حتى E228 → كبريتيت (sulfur)
   - أضف فقط ما يخص حساسيات المستخدم المحددة.
   - اكتب النص الكامل كما ورد في الصورة.

5. العبارات التحذيرية — ضعها في warning_statements:
   - "قد يحتوي على آثار من..."
   - "May contain traces of..."
   - "مُصنَّع في منشأة تتعامل مع..."
   - "Manufactured in a facility that also processes..."
   - "Contains:" / "يحتوي على:"
   - استخرج فقط التحذيرات المتعلقة بحساسيات المستخدم.
   - اكتبها بنفس اللغة التي وردت فيها، أو باللغتين إن وُجدتا.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
تصنيفات الحساسية المعتمدة (14 فئة):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- الحليب ومشتقاته (Milk & Dairy) — يشمل: حليب البقر، الماعز، الأغنام، الجاموس
- البيض (Eggs)
- الفول السوداني (Peanuts) — تنبيه: الفول السوداني بقولة وليس مكسرة
- المكسرات (Tree Nuts) — يشمل: لوز، كاجو، جوز، فستق، بندق، بيكان، ماكاديميا، جوز البرازيل، جوز الصنوبر، كستناء
  ⚠️ مهم: جوز الهند (coconut) ليس مكسرة وليس من Tree Nuts — لا تصنفه كحساسية مكسرات
  ⚠️ مهم: السمسم (sesame) له تصنيف منفصل — لا تضعه ضمن Tree Nuts
- الصويا (Soy/Soybeans) — يشمل: فول الصويا، ليسيتين الصويا، توفو
- القمح / الجلوتين (Wheat / Gluten) — يشمل: قمح، شعير، جاودار، هجين القمح، مالت
  ⚠️ مهم: الشوفان (oat) يُدرج هنا فقط إذا كان مُلوثاً بالجلوتين أو غير معتمد خالٍ من الجلوتين
- السمك (Fish) — يشمل: جميع أنواع الأسماك، أنشوجة، سردين
- المحار / القشريات (Shellfish/Crustaceans) — روبيان، كابوريا، جراد البحر
- السمسم (Sesame) — يشمل: بذور السمسم، طحينة، زيت السمسم
- الكرفس (Celery)
- الخردل (Mustard)
- الترمس (Lupin)
- الكبريتيت (Sulfites) — E220 حتى E228
- الرخويات (Molluscs) — حبار، محار، بطلينوس

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
قيم allergen_type المسموح بها (إنجليزية صغيرة فقط):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
milk, eggs, gluten, fish, peanuts, soybeans, treenuts, sesame, crustaceans, celery, mustard, sulfur, lupin, mollusks

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
حقل product_category — نوع المنتج فقط (بغض النظر عن الحساسية):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ مهم جداً: هذا الحقل يصف نوع المنتج فقط، وليس الحساسية.
لا تضع كلمات مثل "gluten-free" أو "dairy-free" أو "nut-free".
فقط اسم نوع المنتج كما هو موضح أدناه.

-- الحليب ومنتجات الألبان --
milk        → حليب سائل (أبقار، ماعز، كامل الدسم، خالي الدسم...)
yogurt      → زبادي / لبن رائب
labneh      → لبنة
cheese      → جبن (شيدر، موزاريلا، كريم تشيز...)
butter      → زبدة / مارجرين
ghee        → سمن
cream       → كريمة طبخ / كريمة خفق
ice-cream   → آيس كريم / جيلاتو
milkshake   → ميلك شيك / مشروب حليب منكّه
custard     → كاسترد / كريم بروليه

-- الشوكولاتة والحلويات --
chocolate         → شوكولاتة ألواح
chocolate-spread  → سبريد شوكولاتة (نوتيلا وما شابه)
candy             → حلوى / ماصات / جيلي
halawa            → حلاوة طحينية

-- المخبوزات --
bread         → خبز / توست / باغيت / صمون
pita          → خبز عربي / خبز مسطح / خبز تنور
pastry        → كرواسان / دانيش / باستري
cake          → كيك / مافن / كب كيك / براونيز
pancake-mix   → خليط بان كيك / وافل

-- المعكرونة والحبوب --
pasta       → معكرونة / باستا
noodles     → نودلز / شعرية
cereal      → حبوب إفطار / كورن فليكس / مسلي
oats        → شوفان
granola     → غرانولا
flour-mix   → دقيق / خليط خبيز

-- البسكويت والسناكس --
biscuit     → بسكويت / كوكيز / ويفر / كراكر
chips       → شيبس / كرسبي
snack-bar   → بار طاقة / بار حبوب
popcorn     → فشار

-- المنكّهات والصلصات --
mayo                → مايونيز
peanut-butter-alt   → زبدة فول سوداني
tahini-alt          → طحينة / سبريد سمسم
salad-dressing      → صوص سلطة / ديب
soy-sauce           → صلصة صويا / تاماري
pesto               → بيستو
sauce               → صوص جاهز (بيتزا، مكرونة...)

-- المشروبات --
coffee-creamer   → كريمر / مبيض قهوة
hot-chocolate    → مسحوق شوكولاتة ساخنة
protein-shake    → مسحوق بروتين / ميل ريبليسمنت
cooking-cream    → كريمة طبخ مخصصة

-- الشوربات --
soup   → شوربة جاهزة / مركز شوربة

""     → إذا لم يتطابق مع أي فئة أعلاه

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
البدائل المقترحة — suggested_alternatives:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ قاعدة السلامة الأولى — غير قابلة للتجاوز:
يجب أن يكون كل بديل مقترح خالياً تماماً من جميع حساسيات المستخدم المذكورة أعلاه:
${userAllergies.isEmpty ? 'لا توجد حساسيات محددة' : userAllergies}
لا تتحقق فقط من الحساسية المكتشفة في هذا المنتج — تحقق من القائمة الكاملة.
مثال خاطئ: المستخدم حساس للحليب والمكسرات → اقتراح حليب اللوز أو حليب الكاجو خطأ لأنها تحتوي على مكسرات.
مثال صحيح: في نفس الحالة → اقترح حليب الشوفان أو حليب الأرز أو حليب الصويا (إذا لم يكن المستخدم حساساً للصويا).
قواعد صارمة جداً — يجب الالتزام بها تماماً:

✅ اقترح فقط منتجات تجارية حقيقية تعرفها بيقين تام — علامة تجارية موجودة فعلاً وتنتج هذا النوع من المنتج بالفعل.
✅ الأولوية للعلامات التجارية العالمية المعروفة التي يمكن التحقق منها:
   Alpro, Oatly, Violife, Schär, No Moo, Enjoy Life, Bob's Red Mill, Barilla GF, San-J, Hellmann's Vegan, So Delicious, Silk, Kite Hill
✅ العلامات التجارية السعودية المحلية مقبولة فقط إذا كنت متأكداً 100% من وجود هذا المنتج تحديداً:
   Al Saudia, Nada, No Moo — فقط للمنتجات التي تعرف أنها موجودة بالتأكيد.

❌ يُمنع منعاً باتاً:
   - اختراع منتج غير موجود أو تسمية وهمية
   - إضافة اسم علامة تجارية محلية لمنتج لا تعرف إذا كانت تصنعه فعلاً
   - تخمين أو افتراض وجود منتج في السوق السعودي بدون يقين
   - اقتراح نفس المنتج أو العلامة التجارية بأسماء مختلفة

⚠️ القاعدة الذهبية: بديل واحد حقيقي مؤكد أفضل بكثير من خمسة مخترعة.
   إذا لم تكن متأكداً → اترك القائمة فارغة [] أو اقترح واحداً فقط مؤكداً.

- إذا كان المنتج آمناً → suggested_alternatives = []
- available_in_saudi: true فقط للعلامات التجارية المؤكدة الوجود في السوق السعودي
- available_in_saudi: false إذا كان هناك أي شك

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
قواعد عامة:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- إذا لم تجد مسببات تطابق حساسيات المستخدم → detected_allergens = [].
- لا تذكر مسببات غير مطلوبة من المستخدم.
- لا تخترع مكونات غير موجودة في الصورة.
- is_safe_for_user: false إذا وُجد أي مسبب حساسية من قائمة المستخدم.
- is_safe_for_user: true إذا لم يوجد أي تطابق.

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
      "available_in_saudi": true,
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