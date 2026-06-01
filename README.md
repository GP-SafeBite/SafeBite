# SafeBite 🍎
## Food Allergy Detection App | تطبيق الكشف عن حساسية الغذاء

**Smart AI-Powered Ingredient Analysis for Your Safety**
**تحليل ذكي مدعوم بالذكاء الاصطناعي لحماية صحتك**

---

## 📋 Table of Contents | جدول المحتويات
- [About SafeBite](#about-safebite) | [عن SafeBite](#عن-safebite)
- [Features](#features) | [المميزات](#المميزات)
- [Getting Started](#getting-started) | [البدء-السريع](#البدء-السريع)
- [How to Use](#how-to-use) | [كيفية-الاستخدام](#كيفية-الاستخدام)
- [FAQ](#faq) | [الأسئلة-الشائعة](#الأسئلة-الشائعة)
- [Technology Stack](#technology-stack) | [المكتبات-المستخدمة](#المكتبات-المستخدمة)
- [Team](#team) | [الفريق](#الفريق)

---

## 🎯 About SafeBite {#about-safebite}

SafeBite is a Flutter-based mobile application designed to protect individuals with food allergies by quickly and accurately detecting allergens in food products.

**How it works:**
1. Take a photo of the ingredient list on any food packaging
2. Our AI analyzes the ingredients instantly
3. Get a clear safety verdict
4. Browse safe alternatives if needed

**Supports 14 major allergen types** including dairy, eggs, shellfish, gluten, fish, soy, celery, peanuts, tree nuts, mustard, sesame, and more.

### عن SafeBite {#عن-safebite}

SafeBite تطبيق محمول مبني بـ Flutter مصمم لحماية الأشخاص الذين يعانون من حساسية الغذاء من خلال الكشف السريع والدقيق عن مسببات الحساسية في المنتجات الغذائية.

**طريقة العمل:**
1. التقط صورة لقائمة المكونات على غلاف أي منتج غذائي
2. يقوم الذكاء الاصطناعي بتحليل المكونات فوراً
3. احصل على نتيجة أمان واضحة
4. استعرض البدائل الآمنة إذا لزم الأمر

**يدعم 14 نوع من مسببات الحساسية الرئيسية** بما في ذلك الحليب والبيض والقشريات والجلوتين والسمك وفول الصويا والكرفس والفول السوداني والمكسرات والخردل والسمسم والمزيد.

---

## ✨ Key Features | المميزات الرئيسية {#features}

### 1️⃣ User Account & Allergy Profile | حساب المستخدم وملف الحساسية {#المميزات}

**Features:**
- Register with name, email and password
- Email verification with OTP code
- Create personalized allergy profile
- Select from 14 allergen categories
- Edit profile anytime

**Steps:**
1. Open SafeBite
2. Tap "Create Account"
3. Enter full name
4. Enter email
5. Enter password and confirm
6. Tap "Next"
7. Enter verification code (OTP)
8. Select allergies (one or more)
9. Confirm profile

**المميزات:**
- التسجيل باستخدام الاسم والبريد الإلكتروني وكلمة المرور
- التحقق من البريد برمز OTP
- إنشاء ملف حساسية شخصي
- الاختيار من 14 نوع من مسببات الحساسية
- تعديل الملف الشخصي في أي وقت

**الخطوات:**
1. افتح SafeBite
2. اضغط على "إنشاء حساب"
3. أدخل الاسم الكامل
4. أدخل البريد الإلكتروني
5. أدخل كلمة المرور وأكدها
6. اضغط "التالي"
7. أدخل رمز التحقق (OTP)
8. اختر الحساسيات (واحدة أو أكثر)
9. أكد الملف الشخصي

---

### 2️⃣ Smart Ingredient Scanning | مسح المكونات الذكي

**Features:**
- Real-time camera capture
- Upload from gallery
- Flash control for better clarity
- Automatic image compression

**Steps:**
1. Go to Home → Scan
2. Point camera at ingredient list
3. Tap camera button or choose from gallery
4. Enter product name (optional)
5. Wait for analysis

**المميزات:**
- التقاط الكاميرا في الوقت الفعلي
- تحميل الصور من المعرض
- تحكم بالفلاش لوضوح أفضل
- ضغط الصور التلقائي

**الخطوات:**
1. اذهب إلى الشاشة الرئيسية → مسح
2. وجه الكاميرا نحو قائمة المكونات
3. اضغط على زر الكاميرا أو اختر من المعرض
4. أدخل اسم المنتج (اختياري)
5. انتظر عملية التحليل

---

### 3️⃣ AI Analysis Results | نتائج التحليل بالذكاء الاصطناعي

#### ✅ SAFE Product

Product contains NO allergens matching your profile

**What you see:**
- Green checkmark
- Product ingredients listed
- Confirmation message
- Option to scan another product

#### ✅ منتج آمن

المنتج لا يحتوي على أي مسببات حساسية تطابق ملفك

**ما تراه:**
- علامة اختيار خضراء
- قائمة مكونات المنتج
- رسالة تأكيد
- خيار مسح منتج آخر

---

#### ❌ UNSAFE Product

Product contains allergens YOU are allergic to

**What you see:**
- Red warning icon
- List of detected allergens
- Ingredient breakdown
- Safe alternatives button

#### ❌ منتج غير آمن

المنتج يحتوي على مسببات حساسية أنت حساس لها

**ما تراه:**
- رمز تحذير أحمر
- قائمة مسببات الحساسية المكتشفة
- تفصيل المكونات
- زر البدائل الآمنة

---

### 4️⃣ Browse Safe Alternatives | استعراض البدائل الآمنة

When a product is unsafe, SafeBite suggests alternatives

**Sources:**
- ✅ Verified Saudi database (green badge)
- 🤖 AI-generated suggestions (yellow badge)

**Steps:**
1. View unsafe product result
2. Tap "View Safe Alternatives"
3. Browse suggested products
4. See ingredient details

عندما يكون المنتج غير آمن، يقترح SafeBite بدائل آمنة

**المصادر:**
- ✅ قاعدة بيانات سعودية موثقة (شارة خضراء)
- 🤖 اقتراحات من الذكاء الاصطناعي (شارة صفراء)

**الخطوات:**
1. اعرض نتيجة المنتج غير الآمن
2. اضغط على "عرض البدائل الآمنة"
3. استعرض المنتجات المقترحة
4. اطلع على التفاصيل

---

### 5️⃣ Scan History & Tracking | سجل المسح والتتبع

Keep track of all your scans

**Features:**
- Complete history of products
- Search by product name or allergen
- Quick access to previous results
- Delete individual scans

**Steps:**
1. Tap History icon
2. View all previous scans
3. Search or scroll
4. Tap to view details again
5. Swipe left to delete (optional)

احفظ سجل كل عمليات المسح الخاصة بك

**المميزات:**
- سجل كامل للمنتجات المفحوصة
- البحث باسم المنتج أو مسبب الحساسية
- الوصول السريع للنتائج السابقة
- حذف عمليات المسح الفردية

**الخطوات:**
1. اضغط على أيقونة السجل
2. اعرض جميع عمليات المسح السابقة
3. ابحث أو انقر
4. اضغط لرؤية التفاصيل مرة أخرى

---

### 6️⃣ Educational Content | محتوى توعوي تعليمي

Learn about food allergies from trusted sources

**Features:**
- Learn about food allergies from trusted sources
- Articles about common allergens
- Symptom recognition
- Prevention tips

**Steps:**
1. Tap Educational Content icon
2. Browse available content
3. Tap article to read full details

---

**المميزات:**
- تعلم عن حساسيات الغذاء من مصادر موثوقة
- مقالات عن مسببات الحساسية الشائعة
- التعرف على الأعراض
- نصائح الوقاية

**الخطوات:**
1. اضغط على أيقونة المحتوى التوعوي
2. استعرض المحتوى المتاح
3. اضغط على المقالة لقراءة التفاصيل الكاملة

---

### 7️⃣ Personal Profile | الملف الشخصي

Manage your account and preferences

**Options:**
- View/Edit name and photo
- Manage allergy list
- Toggle dark mode
- View app information
- Logout

**Steps:**
1. Tap Profile icon (bottom left)
2. View your information
3. Edit profile or allergies as needed
4. Toggle dark mode anytime

إدارة حسابك والتفضيلات الخاصة بك

**الخيارات:**
- عرض/تعديل الاسم والصورة
- إدارة قائمة الحساسيات
- تبديل الوضع الليلي
- عرض معلومات التطبيق
- تسجيل الخروج

**الخطوات:**
1. اضغط على أيقونة الملف الشخصي (أسفل اليسار)
2. اعرض معلوماتك
3. عدّل الملف الشخصي أو الحساسيات حسب الحاجة
4. بدّل الوضع الليلي في أي وقت
---

### 8️⃣ Dark Mode | الوضع الليلي

Easy on the eyes, available 24/7

**Steps:**
1. Go to Profile
2. Find "Dark Mode" toggle
3. Tap to switch
4. Automatic on all screens

سهل على العينين، متاح 24/7

**الخطوات:**
1. اذهب إلى الملف الشخصي
2. ابحث عن مفتاح "الوضع الليلي"
3. اضغط للتبديل
4. يتطبق تلقائياً على جميع الشاشات

---

## 🚀 Getting Started | البدء السريع {#getting-started}

### First Time Users | المستخدمون الجدد {#البدء-السريع}

#### Step 1: Download & Install | الخطوة 1: التحميل والتثبيت

**Requirements:**
- Flutter SDK installed
- Android device or emulator
- Git installed

**Installation:**
```bash
git clone https://github.com/your-repo/safebite.git
cd safebite
flutter pub get
flutter run
```

**المتطلبات:**
- تثبيت Flutter SDK
- جهاز Android أو محاكاة
- تثبيت Git

**التثبيت:**
```bash
git clone https://github.com/your-repo/safebite.git
cd safebite
flutter pub get
flutter run
```

#### Step 2: Create Account | الخطوة 2: إنشاء حساب
- Name, email and password required | الاسم والبريد الإلكتروني وكلمة المرور مطلوبة
- Confirm password | أكد كلمة المرور
- Verify email with OTP | تحقق من البريد برمز OTP

#### Step 3: Set Up Allergies | الخطوة 3: إعداد الحساسيات
- Choose allergies from list (14 options) | اختر الحساسيات من القائمة (14 خيار)
- Can select multiple | يمكنك اختيار عدة خيارات
- Save and continue | احفظ وتابع

#### Step 4: Start Scanning | الخطوة 4: ابدأ المسح
- Go to Home | اذهب إلى الشاشة الرئيسية
- Tap camera button | اضغط على زر الكاميرا
- Scan first product | امسح أول منتج
- See your first result! | اعرض النتيجة!

---

## 📱 How to Use - Step by Step | كيفية الاستخدام - خطوة بخطوة {#how-to-use}

### Scanning a Product | مسح منتج {#كيفية-الاستخدام}

```
1. Tap the camera button on home screen
2. Allow camera permission (first time only)
3. Point camera at ingredient list on package
4. Make sure text is clear and visible
5. Tap the big green circle to capture
6. (Optional) Enter product name
7. Tap "Confirm"
8. Wait 3-4 seconds for analysis
9. See result (Safe ✅ or Unsafe ❌)
```

اضغط على زر الكاميرا في الشاشة الرئيسية
السماح بإذن الكاميرا (المرة الأولى فقط)
وجه الكاميرا نحو قائمة المكونات على العبوة
تأكد من أن النص واضح ومركز
اضغط على الدائرة الخضراء الكبيرة للتقاط
(اختياري) أدخل اسم المنتج
اضغط على "تأكيد"
انتظر 3-4 ثواني للتحليل
اعرض النتيجة (آمن ✅ أو غير آمن ❌)


**Tips | النصائح:**
- Ensure good lighting | تأكد من الإضاءة الجيدة
- Keep text in focus | اجعل النص في التركيز
- Include all ingredients in frame | ضمّن جميع المكونات في الإطار
- Use flash if needed | استخدم الفلاش إذا لزم الأمر

---

### Checking Your History | فحص السجل الخاص بك

Tap History icon (bottom navigation)
Scroll through previous scans
Search by product name
Tap any product to see details again
Swipe left to delete (optional)



اضغط على أيقونة السجل (شريط التنقل السفلي)
مرر الشاشة خلال عمليات المسح السابقة
ابحث باسم المنتج
اضغط على أي منتج لرؤية التفاصيل مرة أخرى
اسحب لليسار للحذف (اختياري)


---

### Editing Your Allergies | تعديل الحساسيات


1. Tap Profile (bottom left)
2. Tap "Edit"
3. Toggle allergies on/off
4. Tap "Save Changes"
5. All future scans updated automatically


1. اضغط على الملف الشخصي (أسفل اليسار)
2. اضغط على "تعديل"
3. بدّل الحساسيات على/إيقاف
4. اضغط على "حفظ التغييرات"
5. جميع عمليات المسح المستقبلية ستُحدَّث تلقائياً

---

## 🖼️ Screenshots | لقطات الشاشة

### Main Flow | سير العمل الرئيسي
[Add GIF: Complete User Journey - Registration to Result | رحلة المستخدم الكاملة - من التسجيل إلى النتيجة]

### Feature Highlights | إبراز المميزات
- [Add GIF 1: Home Screen Overview | نظرة عامة على الشاشة الرئيسية]
- [Add GIF 2: Scanning & Analysis | المسح والتحليل]
- [Add GIF 3: Results & Alternatives | النتائج والبدائل]
- [Add GIF 4: History & Management | الإدارة والسجل]

---

## ❓ FAQ | الأسئلة الشائعة {#faq}

### Q: How accurate is SafeBite? {#الأسئلة-الشائعة}

**A:** 100% accuracy on tested products (50+ Saudi products). SafeBite uses advanced AI (Gemini 2.5 Flash) to analyze ingredients. However, always cross-check if you have severe allergies.

### س: ما دقة SafeBite؟

**ج:** دقة 100% على المنتجات المختبرة (50+ منتج سعودي). يستخدم SafeBite ذكاء اصطناعي متقدماً (Gemini 2.5 Flash) لتحليل المكونات. ومع ذلك، تحقق دائماً إذا كان لديك حساسية شديدة.

---

### Q: What allergens does SafeBite support?

**A:** 14 major allergen types:
1. Milk
2. Eggs
3. Shellfish
4. Cereals/Gluten
5. Fish
6. Soy
7. Celery
8. Peanuts
9. Tree Nuts
10. Mustard
11. Lupine
12. Mollusks
13. Sesame
14. Sulfites

### س: ما مسببات الحساسية التي يدعمها SafeBite؟

**ج:** 14 نوع من مسببات الحساسية الرئيسية:
1. الحليب
2. البيض
3. القشريات
4. الحبوب/الجلوتين
5. السمك
6. فول الصويا
7. الكرفس
8. الفول السوداني
9. المكسرات
10. الخردل
11. الترمس
12. الرخويات
13. السمسم
14. الكبريتيت

---

### Q: Can I add custom allergies?

**A:** Currently, SafeBite supports 14 standard allergens. If you have other allergies, please contact support.

### س: هل يمكنني إضافة حساسيات مخصصة؟

**ج:** حالياً، يدعم SafeBite 14 مسبب حساسية قياسي. إذا كان لديك حساسيات أخرى، يرجى التواصل مع الدعم.

---

### Q: How long does scanning take?

**A:** Average 3.6 seconds
- Image capture: <1s
- Compression: <1s
- AI analysis: ~1s
- Database lookup: ~1s

### س: كم يستغرق المسح؟

**ج:** متوسط 3.6 ثانية
- التقاط الصورة: <1 ثانية
- الضغط: <1 ثانية
- تحليل الذكاء الاصطناعي: ~1 ثانية
- البحث في قاعدة البيانات: ~1 ثانية

---

### Q: Is my data private?

**A:** Yes! Your health data is:
- Encrypted in transit
- Stored securely on Supabase
- Never shared with third parties
- Only accessible to you

### س: هل بياناتي خاصة؟

**ج:** نعم! بيانات صحتك آمنة:
- مشفرة أثناء النقل
- مخزنة بأمان على Supabase
- لا تُشارك مع أطراف ثالثة
- متاحة لك فقط

---

### Q: Can I use SafeBite offline?

**A:** No, SafeBite requires internet connection for:
- Image analysis (AI)
- Alternative suggestions
- Account sync

### س: هل يمكن استخدام SafeBite بدون إنترنت؟

**ج:** لا، يتطلب SafeBite اتصال إنترنت لـ:
- تحليل الصور (الذكاء الاصطناعي)
- اقتراحات البدائل
- مزامنة الحساب

---

### Q: What if SafeBite says "safe" but I'm unsure?

**A:** SafeBite is a helpful tool but not a substitute for professional advice. If you're unsure:
1. Check ingredients manually
2. Contact manufacturer
3. Consult your allergist
4. Use your best judgment

### س: ماذا لو قال SafeBite "آمن" لكنني غير متأكد؟

**ج:** SafeBite أداة مفيدة لكن ليست بديلاً عن المشورة الطبية. إذا كنت غير متأكد:
1. تحقق من المكونات يدوياً
2. اتصل بالمصنع
3. استشر طبيب الحساسية
4. استخدم أفضل حكم لديك

---

### Q: Can I edit my allergies later?

**A:** Yes, anytime!
1. Go to Profile
2. Tap "Edit"
3. Change selections
4. Save

All future scans will use new preferences.

### س: هل يمكنني تعديل الحساسيات لاحقاً؟

**ج:** نعم، في أي وقت!
1. اذهب إلى الملف الشخصي
2. اضغط على "تعديل "
3. غيّر الخيارات
4. احفظ

ستُحدَّث جميع عمليات المسح المستقبلية تلقائياً.

---

### Q: What's the difference between green and yellow badges?

**A:** 
- 🟢 **Green:** Verified from Saudi database
- 🟡 **Yellow:** AI-generated (unverified) - use with caution

### س: ما الفرق بين الشارات الخضراء والصفراء؟

**ج:** 
- 🟢 **أخضر:** موثق من قاعدة البيانات السعودية
- 🟡 **أصفر:** من الذكاء الاصطناعي (غير موثق) - استخدم بحذر

---

## 🛠️ Technology Stack | المكتبات المستخدمة {#technology-stack}

| Technology | Purpose | المكتبة | الغرض |
|-----------|---------|---------|--------|
| **Flutter** | Cross-platform UI | **Flutter** | واجهة المستخدم متعددة المنصات |
| **Dart** | Programming language | **Dart** | لغة البرمجة |
| **GetX** | State management | **GetX** | إدارة الحالة |
| **Supabase** | Backend & Auth | **Supabase** | الواجهة الخلفية والمصادقة |
| **Gemini AI** | Image analysis | **Gemini AI** | تحليل الصور |
| **Camera** | Photo capture | **Camera** | التقاط الصور |

---

## 👥 Team Members | أعضاء الفريق {#team}

- Muruj Haddad
- Hamsa Alharbi
- Rahaf AlMahmudi      
- Roba Almalki

**Academic Supervisor | المشرفة الأكاديمية:** Dr. Arwa Alsubhi

---

## 📊 Performance | الأداء

- ✅ 100% accuracy rate | معدل دقة 100%
- ✅ 3.6s average scan time | متوسط وقت المسح 3.6 ثانية
- ✅ 50+ tested products | 50+ منتج مختبر
- ✅ 100+ safe alternatives | 100+ بديل آمن
- ✅ 14 allergen categories | 14 فئة من مسببات الحساسية

---

## 🔒 Privacy & Security | الخصوصية والأمان

SafeBite takes your health seriously | SafeBite تأخذ صحتك على محمل الجد
- ✅ Encrypted data transmission | نقل بيانات مشفر
- ✅ Secure Supabase storage | تخزين آمن على Supabase
- ✅ No data sharing | عدم مشاركة البيانات

---

## 📄 License | الترخيص

SafeBite © 2025 - All Rights Reserved | جميع الحقوق محفوظة

---

## 🎉 Thank You | شكراً لك

Thank you for using SafeBite! Your safety is our priority.
شكراً لاستخدامك SafeBite! سلامتك هي أولويتنا.

**Made with ❤️ by the SafeBite Team**
**تم تطويره بـ ❤️ من قبل فريق SafeBite**

---

*Last Updated: June 2025 | آخر تحديث: يونيو 2025*
*Version 1.0.0 | الإصدار 1.0.0*