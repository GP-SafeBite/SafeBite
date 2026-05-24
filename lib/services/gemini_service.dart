import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyAWeLFW1G5H-qGPHeIy86_T3dslEHeCGNE";
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
   - لكل مسبب حساسية مكتشف، أنشئ كائناً يحتوي على:
     • allergen_type: نوع الحساسية بالإنجليزية الصغيرة (من القائمة المعتمدة أدناه)
     • allergen_ar: الاسم العربي لمسبب الحساسية — مثال: "الحليب ومشتقاته" أو "القمح / الجلوتين" أو "فول الصويا"
     • ingredients: قائمة بكل المكونات الموجودة في النص التي تنتمي لهذا المسبب — يجب أن تكون القائمة مكتملة وغير فارغة
   - قاعدة كتابة كل مكون في ingredients (مُلزمة لجميع أنواع الحساسية بدون استثناء — سواء كانت صويا أو حليب أو غيرها):
     • إذا ظهر المكون بالعربية والإنجليزية في الصورة → ادمجهما: العربية أولاً ثم الإنجليزية بين قوسين
       ✅ صحيح: "ليسيثين الصويا (soy lecithin)" أو "دقيق القمح (wheat flour)" أو "حليب (milk)"
     • إذا ظهر بالعربية فقط → اكتبه بالعربي كما ورد
     • إذا ظهر بالإنجليزية فقط → اكتبه بالإنجليزي كما ورد
     • ممنوع الفصل بفاصلة أو شرطة أو سطر جديد بين النسختين

   ⚠️ مهم جداً: حقل ingredients يجب أن يكون دائماً قائمة غير فارغة — اذكر كل مكون وجدته في النص ينتمي لهذا المسبب.

   مثال كامل على detected_allergens (لاحظ الفورمات موحّد بغض النظر عن نوع الحساسية):
   [
     {
       "allergen_type": "soybeans",
       "allergen_ar": "فول الصويا",
       "ingredients": ["ليسيثين الصويا (soy lecithin)", "زيت الصويا (soybean oil)"]
     },
     {
       "allergen_type": "milk",
       "allergen_ar": "الحليب ومشتقاته",
       "ingredients": ["حليب كامل الدسم (whole milk)", "مصل اللبن (whey)"]
     },
     {
       "allergen_type": "gluten",
       "allergen_ar": "القمح / الجلوتين",
       "ingredients": ["دقيق القمح (wheat flour)", "نشا القمح (wheat starch)"]
     }
   ]

4. المصادر الخفية — ابحث عنها وضعها في hidden_sources 
⚠️ قاعدة أساسية: hidden_sources فقط للمكونات التي لم تُذكر صراحة في قائمة المكونات — أي مكون موجود بالفعل في detected_allergens.ingredients يجب أن لا يُكرر هنا أبداً.
إذا لم تكن مذكورة صراحة في قائمة المكونات ولكنها معروفة بأنها مشتقة من مكونات أخرى
بعض الأمثلة الشائعة:
   - أي مكون يحمل رقم E يجب تحديد مصدره، فبعض المضافات الغذائية مثل المستحلبات والمثبتات قد تكون مشتقة من مصادر تحتوي على مسببات حساسية مثل الصويا أو الحليب أو الغلوتين
   - كازين / مصل اللبن / whey / casein → حليب (milk)
   - ليسيتين الصويا / soy lecithin → صويا (soybeans)
   - مالت الشعير / barley malt → جلوتين (gluten)
   - E220 حتى E228 → كبريتيت (sulfur)
   - أضف فقط ما يخص حساسيات المستخدم المحددة.
   - اكتب النص الكامل كما ورد في الصورة.
   - المضافات الغذائية التي قد تحتوي على مسببات حساسية:
	•	E322 / E442 ← صويا أو عباد الشمس
	•	E471 / E472 ← حليب أو صويا
	•	E120 ← قد يكون من مصادر حيوانية
	•	E1404 / E1422 / E1442 ← قمح أو ذرة (غلوتين)
	•	E153 ← قد يحتوي على غلوتين
  يجب أن يكون كل عنصر في hidden_sources على الشكل التالي:
     - إذا ورد بلغتين: اكتب العربية أولاً ثم الإنجليزية بين قوسين في نص واحد — مثال: "مصل اللبن (whey)" أو "كازين (casein)" — ممنوع الفصل بفاصلة أو شرطة أو سطر جديد.

{
  "allergen_type": "نوع مسبب الحساسية بالإنجليزية مثل soybeans أو milk أو gluten",
  "ingredient": "اسم المكون كما ظهر في قائمة المكونات"
}

أمثلة:
{
  "allergen_type": "soybeans",
  "ingredient": "ليسيثين الصويا (E322)"
},
{
  "allergen_type": "milk",
  "ingredient": "كازين (E966)"
}

⚠️ مهم: إذا كان المصدر الخفي يتعلق بحساسية المستخدم، أضفه أيضاً إلى detected_allergens مع تحديد allergen_type والمكونات المكتشفة. هذا يضمن ظهور مسبب الحساسية بوضوح للمستخدم.

5. العبارات التحذيرية — ضعها في warning_statements:
   - "قد يحتوي على آثار من..."
   - "May contain traces of..."
   - "مُصنَّع في منشأة تتعامل مع..."
   - "Manufactured in a facility that also processes..."
   - "Contains:" / "يحتوي على:"
   - استخرج فقط التحذيرات المتعلقة بحساسيات المستخدم.
   - إذا وردت التحذيرة بالعربية والإنجليزية معاً: اكتب العربية أولاً ثم الإنجليزية بين قوسين في نص واحد — مثال: "قد يحتوي على آثار من المكسرات (may contain traces of tree nuts)" — ممنوع الفصل بفاصلة أو شرطة أو سطر جديد.

6. قاعدة التحقق من الادعاءات الغذائية (Claims vs. Flavors):
   - إذا ذكر المنتج صراحة أنه "خالٍ من الألبان" (Free from dairy) أو "نباتي" (Vegan):
     * تعامل مع أوصاف النكهات مثل "[cream]" أو "[butter]" على أنها "بروفايل نكهة" وليست مكونات ألبان حقيقية.
     * لا تصنفها كمسبب حساسية إلا إذا وُجد مشتق حليبي صريح (مثل: كازين، مصل لبن، casein, whey).
     * في هذه الحالة، يجب أن تكون قيمة is_safe_for_user هي true.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
تصنيفات الحساسية المعتمدة (14 فئة):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- الحليب ومشتقاته (Milk & Dairy) — يشمل: حليب البقر، الماعز، الأغنام، الجاموس
- البيض (Eggs)
- الفول السوداني (Peanuts) — تنبيه: الفول السوداني بقولة وليس مكسرات
- المكسرات (Tree Nuts) — يشمل: لوز، كاجو، جوز، فستق، بندق، بيكان، ماكاديميا، جوز البرازيل، جوز الصنوبر، كستناء
  ⚠️ مهم: جوز الهند (coconut) ليس مكسرة وليس من Tree Nuts — لا تصنفه كحساسية مكسرات
  ⚠️ مهم: السمسم (sesame) له تصنيف منفصل — لا تضعه ضمن Tree Nuts
- صويا (Soy/Soybeans) — يشمل: فول الصويا، ليسيتين الصويا، توفو
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
cooking-cream    → كريمة طبخ 

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
cooking-cream    → كريمة طبخ 

-- المشروبات --
coffee-creamer   → كريمر / مبيض قهوة
hot-chocolate    → مسحوق شوكولاتة ساخنة
protein-shake    → مسحوق بروتين / ميل ريبليسمنت

-- الشوربات --
soup   → شوربة جاهزة / مركز شوربة

⚠️ إذا لم يتطابق المنتج مع أي فئة أعلاه بشكل مباشر:
   - حاول تحديد أقرب فئة ممكنة بناءً على المكونات الظاهرة في الصورة أو اسم المنتج.
   - لا تترك product_category فارغاً إلا إذا كان المنتج غير غذائي تماماً.
   - تجاهل الأخطاء الإملائية الطفيفة في اسم المنتج وحاول تفسيره.
   - أمثلة: "زبادى" أو "زبادة" → yogurt / "لبنه" → labneh / "شوكولاته" → chocolate
   - إذا كان المنتج غير غذائي أو لا يمكن تصنيفه بأي شكل → ""

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
البدائل المقترحة — suggested_alternatives:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ قاعدة السلامة الأولى — غير قابلة للتجاوز:
يجب أن يكون كل بديل مقترح خالياً تماماً من جميع حساسيات المستخدم المذكورة أعلاه:
${userAllergies.isEmpty ? 'لا توجد حساسيات محددة' : userAllergies}
لا تتحقق فقط من الحساسية المكتشفة في هذا المنتج — تحقق من القائمة الكاملة.
مثال خاطئ: المستخدم حساس للحليب والمكسرات → اقتراح حليب اللوز أو حليب الكاجو خطأ لأنها تحتوي على مكسرات.
مثال صحيح: في نفس الحالة → اقترح حليب الشوفان أو حليب الأرز أو حليب الصويا (إذا لم يكن المستخدم حساساً للصويا).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
قواعد اختيار البدائل — اقرأها بعناية:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ مهمتك: اقتراح منتجات حقيقية موجودة في أي مكان بالعالم.
   لا يهم إن كانت متوفرة في السعودية أم لا — هذا ليس دورك.
   دورك فقط: هل هذا المنتج موجود فعلاً في الأسواق العالمية؟

✅ اقترح فقط علامات تجارية عالمية معروفة وموثوقة تعرفها بيقين تام:
   Alpro, Oatly, Violife, Schär, Enjoy Life, Bob's Red Mill,
   So Delicious, Silk, Kite Hill, Barilla GF, San-J, Hellmann's Vegan,
   Follow Your Heart, Daiya, Good Karma, Califia Farms

✅ اسم المنتج: اكتب العلامة التجارية + اسم المنتج فقط، بدون وصف إضافي.
   صحيح: "Alpro Oat Milk" أو "Oatly Barista Edition"
   خاطئ: "Alpro Plant-Based Yogurt Alternative (e.g., Soy, Oat, Coconut)"

❌ يُمنع منعاً باتاً:
   - اختراع منتج غير موجود أو إضافة كلمة "vegan" أو "plant-based" لعلامة محلية لا تصنعه
   - ذكر علامات سعودية محلية (Nada، Al Saudia) إلا إذا كنت متأكداً 100% أن هذا المنتج تحديداً موجود
     مثال مسموح: "Nada Oat Drink" — موجود فعلاً
     مثال ممنوع: "Nada Vegan Yogurt" — غير موجود
   - إضافة أي وصف أو أقواس أو أمثلة داخل اسم المنتج
   - اقتراح نفس المنتج بأسماء مختلفة

⚠️ القاعدة الذهبية: بديل واحد حقيقي مؤكد أفضل بكثير من خمسة مخترعة.
   إذا لم تكن متأكداً → اترك القائمة فارغة [] أو اقترح واحداً فقط مؤكداً.

- إذا كان المنتج آمناً → suggested_alternatives = []
- available_in_saudi: true فقط إذا كنت متأكداً 100% أن هذا المنتج موجود في السوق السعودي
- available_in_saudi: false إذا كان المنتج عالمي لكن لا تعرف إن كان في السعودية

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
قواعد عامة:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- إذا لم تجد مسببات تطابق حساسيات المستخدم → detected_allergens = [].
- لا تذكر مسببات غير مطلوبة من المستخدم.
- لا تخترع مكونات غير موجودة في الصورة.
- مراجعة الادعاءات الكبيرة على العبوة (مثل Dairy Free) قبل اتخاذ القرار النهائي في حقل is_safe_for_user.
- is_safe_for_user: false إذا وُجد أي مسبب حساسية من قائمة المستخدم.
- is_safe_for_user: true إذا لم يوجد أي تطابق.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
حقل confidence:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- "high" → الصورة واضحة والمكونات مقروءة بوضوح
- "medium" → الصورة مقبولة لكن بعض المكونات غير واضحة
- "low" → الصورة غير واضحة أو مظلمة أو لا تحتوي على قائمة مكونات مرئية
  في حالة low: أعد جميع الحقول فارغة، product_type_ar = ""، product_category = ""،
  detected_allergens = []، is_safe_for_user = true، suggested_alternatives = []

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
  "hidden_sources": [
  {
    "allergen_type": "",
    "ingredient": ""
  }
],
  "warning_statements": [],
  "is_safe_for_user": true,
  "suggested_alternatives": [
    {
      "name": "",
      "available_in_saudi": false
    }
  ],
  "confidence": "high"
}
""";

    http.Response? response;
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        response = await http.post(
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

        if (response.statusCode == 200) break;
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception(response.body);
        }
        if (attempt == 2) throw Exception(response.body);
      } catch (e) {
        if (attempt == 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    final data = jsonDecode(response!.body);
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