# DCW-SETIF-TRACKER — AGENTS.md
## نظام تتبع مفتشي مديرية التجارة لولاية سطيف

> **الريبو**: https://github.com/toufiknation/DCW-SETIF-TRACKER
> **تاريخ البدء:** سبتمبر 2026
> **المشروع:** Frontend (Flutter) + Backend (Node.js) + SQL Server

---

## ⚠️ تعليمات لأي وكيل/مطور جديد

### لا تلمس:
- المشروع القديم WPF في `DRH-Setif-1` — مستقل تماماً (للقراءة فقط)
- قاعدة البيانات الأصلية `DRH_Setif_DB` — لا نغير فيها شيء

### قواعد العمل:
1. بعد كل تعديل: `flutter analyze` للتأكد من صفر أخطاء
2. بعد كل تعديل: commit + push للريبو
3. حديث AGENTS.md بأي تغيير كبير
4. Backend في مجلد منفصل `drh_setif_backend`

---

## 🔑 بيانات الدخول (SQL Server عبر Backend API)

| الدور | اسم المستخدم | كلمة المرور | role |
|-------|-------------|-------------|------|
| مدير النظام | `tracker_admin` | `admin123` | `admin` |
| مدير | `directeur` | `directeur123` | `director` |
| رئيس مصلحة | `chef_concurrence` | `chef123` | `head_of_department` |
| رئيس مكتب | `bureau_user` | `bureau123` | `bureau_chief` |
| رئيس مكتب | `chef_bureau` | `Bureau@2024` | `bureau` |
| مفتش | `agent` | `Agent@2024` | `inspector` |

**ملاحظة**: المستخدمون يأتون من قاعدة SQL Server الحقيقية عبر Backend API

---

## 👥 الهيكل التنظيمي (قانوني)

### المرجع القانوني:
- المرسوم التنفيذي 03-409 (2003) — تنظيم المصالح الخارجية
- المرسوم التنفيذي 11-09 (2011) — تنظيم خدمات وزارة التجارة
- القرار الوزاري المشترك 16 أوت 2011 — تنظيم المديريات في مكاتب

### المصلحتان المعنيتان فقط:
1. **مصلحة مراقبة الممارسات التجارية والمضادة للمنافسة** — 145 عامل
2. **صلة حماية المستهلك وقمع الغش** — 122 عامل
3. **المجموع**: 267 تكنيك فقط

### الهيكل داخل كل مصلحة:
```
رئيس المصلحة
    ↓
رئيس فرقة (chef de groupe)
    ↓
رئيس مهمة (chef de mission)
    ↓
مفتش رئيسي / محقق رئيسي
    ↓
محقق (تيكنيك / تقني)
```

### الفلتر المطبق:
- **القسم**: مصلحتين فقط (منافسة + حماية المستهلك)
- **الرتبة**: جميع الرتب (100-115)
- **المنصب**: excludes (إعادة ادماج، ترسيم، موقفة تحفظيا)

---

## 📐 البنية التقنية

### المشروعين:
```
C:\Users\PCIB\Desktop\
├── drh_setif_tracker\    ← تطبيق Flutter (موبايل)
└── drh_setif_backend\    ← Backend API (Node.js + Express)
```

### Frontend (Flutter):
- **Flutter SDK**: `C:\src\flutter` (v3.11.4+)
- **المشروع**: `C:\Users\PCIB\Desktop\drh_setif_tracker\`
- **الثيم**: Burgundy (#881337) + Gold (#D4AF37) — مطابق لتطبيق WPF
- **الخط**: Tajawal + Cairo
- **الاتجاه**: RTL عربي

### Backend (Node.js):
- **المشروع**: `C:\Users\PCIB\Desktop\drh_setif_backend\`
- **التقنية**: Node.js + Express + ODBC
- **قاعدة البيانات**: SQL Server LocalDB → DRH_Setif_DB
- **المنفذ**: http://localhost:8080
- **المصادقة**: JWT + BCrypt

### API Endpoints:
```
POST   /api/auth/login          → تسجيل الدخول
GET    /api/auth/me              → بيانات المستخدم الحالي
GET    /api/employees            → قائمة الموظفين
GET    /api/employees/departments → قائمة الأقسام
GET    /api/employees/:id        → بيانات موظف
GET    /api/dashboard/stats      → إحصائيات Dashboard
GET    /api/dashboard/recent-activity → آخر النشاطات
GET    /api/attendance           → بيانات الحضور
POST   /api/attendance/checkin   → تسجيل حضور
POST   /api/attendance/checkout  → تسجيل انصراف
GET    /api/programs             → البرامج
POST   /api/programs             → إنشاء برنامج
GET    /api/health               → فحص الخادم
```

---

## 🗃️ قاعدة البيانات (SQL Server)

### الجداول الأصلية (WPF — لا نلمسها):
- `Employes` — 329 موظف (نأخذ 267 فقط)
- `UtilisateursSysteme` — المستخدمون
- `StructuresAdministratives` — الأقسام
- + 20 جدول آخر مرتبط بالرواتب والوثائق

### الجداول الجديدة (Tracker):
- `TrackerAttendance` — الحضور والانصراف
- `TrackerPrograms` — البرامج الأسبوعية/الشهرية
- `TrackerAssignments` — توزيع المهام
- `TrackerAbsences` — الغيابات
- `TrackerDeductions` — قرارات الخصم

---

## 📊 الحالة الحالية

### ✅ مكتمل:
- [x] هيكل المشروع + pubspec.yaml
- [x] ثيم كامل مطابق لـ WPF
- [x] خطوط Tajawal + Cairo
- [x] Backend API كامل (Node.js + Express + ODBC)
- [x] الاتصال بـ SQL Server الحقيقية
- [x] 267 موظف من المصلحتين فقط
- [x] 5 جداول جديدة للتتبع
- [x] تسجيل الدخول عبر JWT + API
- [x] Dashboard مع إحصائيات حقيقية (267)
- [x] شاشة الحضور مع بيانات حقيقية (267 موظف)
- [x] شاشة البرامج من API
- [x] شاشة الملف الشخصي بالبيانات الحقيقية
- [x] RTL كامل
- [x] صفر أخطاء compile
- [x] Git repos + GitHub (Flutter + Backend)

### 🔜 قادم:
- [ ] شاشة التقارير (ربطها بالـ API)
- [ ] GPS real check-in/check-out
- [ ] تصدير Excel/PDF
- [ ] نظام الإشعارات
- [ ] BCrypt تشفير كلمات المرور

### 🔜 قادم:
- [ ] إصلاح type casting errors
- [ ] ربط برامج التوزيع بالـ API
- [ ] GPS real check-in/check-out
- [ ] تصدير Excel/PDF
- [ ] نظام الإشعارات
- [ ] BCrypt تشفير كلمات المرور

---

## 📌 ملاحظات تقنية

### الاتصال بالـ Backend:
```dart
// في api_service.dart
static const String baseUrl = 'http://localhost:8080/api';
```

### الألوان:
| الاسم | الكود |
|-------|-------|
| PrimaryColor | `#881337` |
| AccentColor | `#D4AF37` |
| SidebarColor | `#4C0519` |
| BackgroundColor | `#FAF5F5` |
| SuccessColor | `#10B981` |
| WarningColor | `#F59E0B` |
| DangerColor | `#EF4444` |
