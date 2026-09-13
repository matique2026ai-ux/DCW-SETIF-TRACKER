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

1. **قاعدة البيانات**: يدعم النظام Dual DB (PostgreSQL على Render و SQL Server محلياً عبر ODBC).
2. **فحص الكود بعد كل تعديل**:
   - تشغيل `C:\src\flutter\bin\flutter.bat analyze`
3. **البناء والتصدير**:
   - بناء الويب: `flutter build web --release --dart-define=API_URL=https://drh-setif-api.onrender.com`
   - نسخ محتويات `build/web/` إلى `DCW-SETIF-BACKEND/public/`
   - بناء الـ APK: `flutter build apk --release --dart-define=API_URL=https://drh-setif-api.onrender.com`
   - نسخ ملف `app-release.apk` إلى `DCW-SETIF-BACKEND/public/download/` و `DCW-SETIF-BACKEND/public/`
4. **حفظ وتحديث ملفات التوثيق**: دائماً قم بعمل `git commit` مع رسالة واضحة وتحديث `AGENTS.md` و `README.md`.

---

## 🔑 جدول الحسابات وكلمات المرور الرسمية

| الدور الوظيفي | اسم المستخدم (Username) | كلمة المرور (Password) | الرمز البرمجي (Role) | الوصف |
| :--- | :--- | :--- | :--- | :--- |
| **مفتش رئيسي (كريبع كمال)** | `kriba` | `Agent@2024` | `inspector` | حساب البث المباشر التجريبي، تسجيل حضور/انصراف، زيارات ميدانية |
| **مفتش رئيسي (عام)** | `agent` | `Agent@2024` | `inspector` | تسجيل حضور/انصراف، زيارات ميدانية، QR، العمل بدون إنترنت |
| **مكتب المستخدمين** | `bureau_user` | `bureau123` | `bureau_chief` | إدارة حالة الموظفين الـ 267، تعيين قادة الفرق، النقل والتحويل |
| **رئيس مكتب المستخدمين** | `chef_bureau` | `Bureau@2024` | `bureau_chief` | إدارة المستخدمين والموظفين |
| **المدير الولائي** | `directeur` | `directeur123` | `director` | لوحة القيادة، خريطة الأقمار الصناعية، مقارنة الأدلة الميدانية |
| **رئيس مصلحة المنافسة** | `chef_concurrence` | `chef123` | `head_of_department` | متابعة المفتشين والزيارات |
| **رئيس مصلحة حماية المستهلك** | `chef_consommation` | `chef123` | `head_of_department` | متابعة الرقابة وقمع الغش |
| **مدير النظام (Admin)** | `tracker_admin` | `admin123` | `admin` | إدارة كاملة للنظام |

> [!IMPORTANT]
> كلمات المرور حساسة لحالة الأحرف (مثال: `Agent@2024` بحرف A كبير). أما أسماء المستخدمين فهي غير حساسة لحالة الأحرف ويتم إزالة الفراغات تلقائياً.

---

## 🚀 الميزات والوظائف المنجزة (Features Implemented)

### 1. شعار الميدالية الذهبية ثلاثية الأبعاد (3D Golden Medallion & Clean Login)
- تصميم شعار ذهبي ثلاثي الأبعاد مع طبقة لمعان مخصصة عبر `CustomPainter` لتعمل بكفاءة على كافة المتصفحات وهواتف الأندرويد والـ iOS دون أي تشويه أو دوائر بيضاء.
- تدفق تسجيل دخول مرن يسمح باختيار أي دور وظيفي وتجربة الحسابات المختلفة.

### 2. العمل في وضع عدم الاتصال والمزامنة التلقائية (Offline-First Storage & Auto-Sync)
- خدمة `OfflineSyncService` لحفظ الحضور والانصراف والزيارات محلياً في `SharedPreferences` عند غياب النت.
- توليد رمز QR فوري ومحلي في الميدان كإثبات رسمي بحالة `OFFLINE_PENDING_SYNC`.
- شارة وزر مزامنة ذكي `🔄 X معلق` في الـ AppBar مع مزامنة جماعية `syncAll()` فور عودة الاتصال.

### 3. احترام الخصوصية وتوقيت الجزائر (Algeria TZ & Privacy Masking)
- مزامنة كافة العمليات بتوقيت الجزائر الرسمي `Africa/Algiers` (UTC+1).
- إخفاء إحداثيات المفتش الجغرافية تلقائياً من خريطة المدير فور تسجيل الانصراف.

### 4. لوحة المدير وخريطة المراقبة الميدانية (Director Live Satellite Map)
- خريطة فضائية HD Satellite Map لمراقبة تموضع المفتشين النشطين ومواقع الزيارات في سطيف.
- إمكانية تصفير السجلات بضغطة زر لبدء تجارب حية جديدة.

### 5. تحميل التطبيق ورمز الاستجابة السريعة (QR & APK Download)
- روابط تحميل مباشرة وسريعة: `https://drh-setif-api.onrender.com/app-release.apk`
- ملف الـ APK الرئيسي: `DCW-SETIF-TRACKER.apk`.
