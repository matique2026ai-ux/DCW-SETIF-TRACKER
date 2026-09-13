# DCW-SETIF-TRACKER — AGENTS.md

## نظام تتبع مفتشي مديرية التجارة وترقية الصادرات لولاية سطيف

> **المستودع (Frontend / Flutter)**: [DCW-SETIF-TRACKER](https://github.com/matique2026ai-ux/DCW-SETIF-TRACKER)  
> **المستودع (Backend / API)**: [DCW-SETIF-BACKEND](https://github.com/matique2026ai-ux/DCW-SETIF-BACKEND)  
> **السيرفر السحابي الحي (Live Render)**: `https://drh-setif-api.onrender.com`  
> **الرابط القصير**: `https://tinyurl.com/24ywuw53`  
> **بيئة العمل الحالية**: `C:\Users\ASUS 2\Nouveau dossier\`  
> **مسار Flutter SDK**: `C:\src\flutter\bin`  
> **مسار JDK 17**: `C:\src\jdk`  
> **مسار Android SDK**: `C:\src\android-sdk`  

---

## ⚠️ دليل وقواعد العمل للوكلاء والمطورين

1. **لا تلمس ولا تعدل قاعدة البيانات الأصلية القديمة بدون اختبار**: يدعم النظام Dual DB (PostgreSQL على Render و SQL Server محلياً عبر ODBC).
2. **فحص الكود بعد كل تعديل**:
   - تشغيل `C:\src\flutter\bin\flutter.bat analyze`
3. **البناء والتصدير**:
   - بناء الويب: `flutter build web --release --dart-define=API_URL=https://drh-setif-api.onrender.com`
   - نسخ محتويات `build/web/` إلى `DCW-SETIF-BACKEND/public/`
   - بناء الـ APK: `flutter build apk --release --dart-define=API_URL=https://drh-setif-api.onrender.com`
   - نسخ ملف `app-release.apk` إلى `DCW-SETIF-BACKEND/public/download/`
4. **حفظ وتحديث ملفات التوثيق**: دائماً قم بعمل `git commit` مع رسالة واضحة وتحديث `AGENTS.md` و `README.md`.

---

## 🔑 جدول الحسابات وكلمات المرور الرسمية

| الدور الوظيفي | اسم المستخدم (Username) | كلمة المرور (Password) | الرمز البرمجي (Role) | الوصف |
| :--- | :--- | :--- | :--- | :--- |
| **مفتش رئيسي (Agent)** | `agent` | `Agent@2024` | `inspector` | تسجيل حضور/انصراف، زيارات ميدانية، QR، العمل بدون إنترنت |
| **رئيس مكتب المستخدمين** | `chef_bureau` | `Bureau@2024` | `bureau_chief` | إدارة المستخدمين والموظفين |
| **المدير الولائي** | `directeur` | `directeur123` | `director` | لوحة القيادة، خريطة الأقمار الصناعية، مقارنة الأدلة |
| **رئيس مصلحة المنافسة** | `chef_concurrence` | `chef123` | `head_of_department` | متابعة المفتشين والزيارات |
| **رئيس مصلحة حماية المستهلك** | `chef_consommation` | `chef123` | `head_of_department` | متابعة الرقابة وقمع الغش |
| **مدير النظام (Admin)** | `tracker_admin` | `admin123` | `admin` | إدارة كاملة للنظام |

> [!IMPORTANT]
> كلمات المرور حساسة لحالة الأحرف (مثال: `Agent@2024` بحرف A كبير). أما أسماء المستخدمين فهي غير حساسة لحالة الأحرف ويتم إزالة الفراغات تلقائياً.

---

## 🚀 الميزات والوظائف المنجزة (Features Implemented)

### 1. العمل في وضع عدم الاتصال والمزامنة التلقائية (Offline-First Storage & Auto-Sync)
- خدمة `OfflineSyncService` لحفظ الحضور والانصراف والزيارات محلياً في `SharedPreferences` عند غياب النت.
- توليد رمز QR فوري ومحلي في الميدان كإثبات رسمي بحالة `OFFLINE_PENDING_SYNC`.
- شارة وزر مزامنة ذكي `🔄 X معلق` في الـ AppBar مع مزامنة جماعية `syncAll()` فور عودة الاتصال.
- استبقاء الجلسة `tryAutoLogin()` لفتح التطبيق دون تسجيل دخول متكرر في المناطق منعدمة التغطية.

### 2. واجهة وتطبيق الآيفون (iOS Safari PWA)
- دعم كامل لتثبيت التطبيق على الشاشة الرئيسية (Add to Home Screen) ليعمل بملء الشاشة وبدون اتصال.

### 3. لوحة المدير وخريطة المراقبة (Director Command Center)
- خريطة فضائية HD Satellite Map لمراقبة تموضع المفتشين والزيارات في سطيف.
- مواجهة الأدلة الرقمية والتقارير الشهرية والمقتطعات المالية.

### 4. رمز الاستجابة السريعة (QR Code)
- حفظ صورة الـ QR في المجلد الرئيسي `QR_Code_DCW_SETIF.png` وعبر الرابط المباشر `https://drh-setif-api.onrender.com/qr-code.png`.
- الرابط المختصر: `https://tinyurl.com/24ywuw53`.
