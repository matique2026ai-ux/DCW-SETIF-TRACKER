# 🏛️ DCW-SETIF-TRACKER — دليل الوكيل والمطور (AGENTS.md)
### تطبيق فلاتر لمنصة الرقابة والتفتيش الميداني — مديرية التجارة لولاية سطيف

> **تاريخ آخر تحديث**: 14 سبتمبر 2026  
> **مستودع المشروع**: [DCW-SETIF-TRACKER](https://github.com/matique2026ai-ux/DCW-SETIF-TRACKER)  
> **السيرفر السحابي الحي**: `https://drh-setif-api.onrender.com/api`  
> **مسار ملف APK الإنتاجي**: `c:\Users\ASUS 2\Nouveau dossier\DCW-SETIF-TRACKER.apk`

---

## 📌 الميزات التقنية والهندسية المنفذة (Implemented Logic)

1. **تسجيل الحضور الإلزامي برمز الاستجابة السريعة (Mandatory QR Attendance)**:
   * تم إلغاء التقاط صور الوجه (السيلفي) لحماية خصوصية الموظفين.
   * الحضور يتطلب فتح الكاميرا لمسح **رمز الـ QR الرسمي** المعلق بنقطة الحضور بالمقر + قياس إحداثيات الـ **GPS** والتأكد من التواجد ضمن نطاق المديرية/المصلحة (`AppConstants.isWithinHQ`).
2. **استعراض وطباعة رمز الحضور الرسمي (Official QR Display)**:
   * مدمج بأزرار AppBar في شاشات المدير ورئيس المصلحة (`DirectorScreen`, `HeadScreen`) لعرض وطباعة رمز الحضور الرسمي لأي مصلحة أو مقر.
3. **توثيق المعاينات التجارية (Field Proof)**:
   * استخدام الكاميرا مخصص حصراً للمحلات التجارية والسلع المخالفة والمحاضر.
4. **المزامنة دون اتصال (Offline-First Architecture)**:
   * محرك `OfflineSyncService` لحفظ الحضور والزيارات محلياً في الذاكرة ومزامنتها تلقائياً مع السيرفر.
5. **لوحات القيادة والتأشير والتقارير الرسمية (PDF Export & RBAC)**:
   * تقارير عربية كاملة RTL لـ 267 موظفاً وتأشير المعاينات من رؤساء المصالح.

---

## 🔑 الحسابات الرسمية المعتمدة
* **Admin**: `tracker_admin` / `admin123`
* **المدير الولائي**: `directeur` / `directeur123`
* **رئيس مصلحة المنافسة**: `chef_concurrence` / `chef123`
* **رئيس مصلحة حماية المستهلك**: `chef_consommation` / `chef123`
* **رئيس مكتب المستخدمين**: `bureau_user` / `bureau123`
* **مفتش رئيسي**: `kriba` / `Agent@2024` أو `agent` / `Agent@2024`

---

## 🚀 أوامر البناء
```powershell
flutter build apk --release
flutter build web --release
```
