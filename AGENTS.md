# DCW-SETIF-TRACKER — AGENTS.md
## نظام تتبع مفتشي مديرية التجارة لولاية سطيف

> **الريبو**: https://github.com/toufiknation/DCW-SETIF-TRACKER
> **تاريخ البدء:** سبتمبر 2026
> **المشروع:** Frontend فقط (Flutter) — لا يوجد باك اند ولا قاعدة معطيات حقيقية

---

## ⚠️ تعليمات لأي وكيل/مطور جديد

### لا تلمس:
- المشروع القديم WPF في `DRH-Setif-1` — مستقل تماماً

### قواعد العمل:
1. بعد كل تعديل: `flutter analyze` للتأكد من صفر أخطاء
2. بعد كل تعديل: commit + push للريبو
3. حديث AGENTS.md بأي تغيير كبير

---

## 🔑 بيانات الدخول (للتجربة — hardcoded في auth_service.dart)

| الدور | اسم المستخدم | كلمة المرور | role |
|-------|-------------|-------------|------|
| مدير | `admin` | `admin123` | `director` |
| رئيس مصلحة | `chef` | `chef123` | `head_of_department` |
| مفتش | `agent` | `agent123` | `inspector` |

**ملاحظة**: لا يوجد حفظ في قاعدة بيانات — البيانات في الذاكرة فقط (Frontend فقط)

---

## 👥 الأدوار والصلاحيات

| الدور | الصلاحيات |
|-------|-----------|
| **مدير** | لوحة القيادة — يشوف كل المفتشين — يصادق الخصم |
| **رئيس المصلحة** | يكتب/يوزّع البرنامج الأسبوعي والشهري — يراقب مفتشيه |
| **مكتب المستخدمين** | يسجل الغيابات — يطبّق قرارات الخصم |
| **مفتش** | يسجل حضوره — يتبع البرنامج |

---

## 📐 البنية التقنية

- **Flutter SDK**: `C:\src\flutter` (v3.11.4+)
- **المشروع**: `C:\Users\PCIB\Desktop\drh_setif_tracker\`
- **الثيم**: Burgundy (#881337) + Gold (#D4AF37) — مطابق لتطبيق WPF
- **الخط**: Tajawal + Cairo
- **الاتجاه**: RTL عربي
- **ijk.Database**: SQLite (sqflite) — لكن لا يعمل بشكل موثوق على Flutter Web

### الهيكل:
```
lib/
├── main.dart                    # نقطة البداية — MaterialApp + Provider
├── models/
│   ├── employee.dart            # نموذج الموظف
│   ├── program.dart             # نموذج البرنامج
│   ├── attendance.dart          # نموذج الحضور
│   ├── absence.dart             # نموذج الغياب
│   ├── deduction.dart           # نموذج الخصم
│   └── user.dart                # نموذج المستخدم
├── screens/
│   ├── auth/login_screen.dart   # شاشة تسجيل الدخول
│   ├── main_navigation_screen.dart  # التنقل الرئيسي (Scaffold + AppBar + BottomNav)
│   ├── dashboard_screen.dart    # لوحة القيادة
│   ├── attendance_screen.dart   # الحضور والانصراف
│   ├── program_screen.dart      # البرامج
│   ├── reports_screen.dart      # التقارير
│   └── profile_screen.dart      # الملف الشخصي
├── services/
│   ├── auth_service.dart        # المصادقة (hardcoded — لا قاعدة بيانات)
│   ├── database_service.dart    # SQLite (غير مستخدم حالياً على Web)
│   ├── gps_service.dart         # خدمة الموقع GPS
│   └── sync_service.dart        # خدمة التزامن (stub)
├── utils/
│   ├── theme.dart               # الثيم الكامل (ألوان + أنماط)
│   └── constants.dart           # الثوابت والأسماء
└── widgets/
    ├── app_bar.dart             # الشريط العلوي
    ├── bottom_nav.dart          # الشريط السفلي
    └── stat_card.dart           # بطاقة الإحصائيات
```

---

## 📊 الحالة الحالية

### ✅ مكتمل:
- [x] هيكل المشروع + pubspec.yaml
- [x] ثيم كامل مطابق لـ WPF (Burgury + Gold + RTL)
- [x] خطوط Tajawal + Cairo
- [x] 6 نماذج بيانات (models)
- [x] 4 خدمات (services)
- [x] شاشة تسجيل الدخول (login_screen)
- [x] شاشة لوحة القيادة (dashboard) — إحصائيات + نشاطات
- [x] شاشة الحضور (attendance) — قائمة مفتشين + أزرار حضور/انصراف
- [x] شاشة البرامج (program) — فلتر أسبوعي/شهري + شريط تقدم
- [x] شاشة التقارير (reports) — 4 أنواع تقارير + تصدير
- [x] شاشة الملف الشخصي (profile) — معلومات + إعدادات + تسجيل خروج
- [x] شريط سفلي (BottomNav) — 5 تبويبات
- [x] AppBar موحد — لا يوجد تكرار
- [x] RTL كامل
- [x] تسجيل دخول يعمل (hardcoded)
- [x] Git repo + GitHub
- [x] صفر أخطاء compile

### 🔜 قادم:
- [ ] بيانات حقيقية (nstqdam هرم المفتشين)
- [ ] SQLite يعمل على Web (أو تخطيه بالكامل)
- [ ] GPS real check-in/check-out
- [ ] برامج توزيع حقيقية
- [ ] تصدير Excel/PDF
- [ ] تزامن مع SQL Server (backend)
- [ ] BCrypt تشفير كلمات المرور

---

## 🔑 كلمات المرور

- `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` — **تم حذفه من Git config** — يجب حذفه من GitHub أيضاً

---

## 📌 ملاحظات تقنية

### مشكلة sqflite على Web:
- `sqflite` لا يعمل بشكل موثوق على Flutter Web (Chrome)
- الحل الحالي: تسجيل دخول hardcoded بدون قاعدة بيانات
- مستقبلاً: نستخدم SharedPreferences أو Hive بدلاً من sqflite على Web

### الألوان المستخدمة:
| الاسم | الكود | الاستخدام |
|-------|-------|-----------|
| PrimaryColor | `#881337` | العنابي الرئيسي |
| AccentColor | `#D4AF37` | الذهبي |
| SidebarColor | `#4C0519` | الشريط الجانبي |
| BackgroundColor | `#FAF5F5` | الخلفية |
| CardColor | `#FFFFFF` | البطاقات |
| SuccessColor | `#10B981` | النجاح (أخضر) |
| WarningColor | `#F59E0B` | تحذير (أصفر) |
| DangerColor | `#EF4444` | خطأ/حذف (أحمر) |
