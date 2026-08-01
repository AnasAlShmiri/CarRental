# CarRental API

نظام إدارة تأجير السيارات — الواجهة الخلفية (ASP.NET Core Web API) ببنية **Clean Architecture** و **Repository Pattern**.

| البند | التقنية |
|---|---|
| الإطار | ASP.NET Core **net10.0** |
| قاعدة البيانات | SQL Server + Entity Framework Core 10 |
| التوثيق | Swagger / OpenAPI (Swashbuckle) |
| المصادقة | JWT Bearer |
| ملف الحل | `CarRental.slnx` — بما أن المشروع يستهدف net10.0 فهو يتطلب **.NET SDK 10** (صيغة slnx نفسها مدعومة من SDK 9.0.200 فما فوق) |

---

## 1. بنية المشروع

```
CarRental.slnx
├── CarRental.Domain          # الكيانات وثوابت الحالات (لا يعتمد على أي طبقة)
│   └── Models/               Car, Customer, Rental, CarStatus, RentalStatus
├── CarRental.Application     # العقود و DTOs (يعتمد على Domain فقط)
│   ├── DTOs/                 Create/Update/Read DTOs + Auth DTOs
│   ├── Interfaces/           ICarRepository, ICustomerRepository, IRentalRepository, ITokenService
│   └── Mapping/              تحويل الكيانات إلى DTOs
├── CarRental.Infrastructure  # الوصول للبيانات والخدمات
│   ├── Data/                 ApplicationDbContext
│   ├── Migrations/           مُهاجَرات EF (خاصة بـ SQL Server)
│   ├── Repositories/         التنفيذ الفعلي للمستودعات
│   ├── Auth/                 JwtSettings, AdminUserSettings
│   └── Services/             TokenService
└── CarRental.API             # نقطة الدخول
    ├── Controllers/          Auth, Cars, Customers, Rentals
    ├── Errors/               GlobalExceptionHandler
    └── wwwroot/uploads/      صور السيارات
```

---

## 2. التشغيل

```bash
# 1) تحديث قاعدة البيانات (مطلوب — هناك مُهاجَرة جديدة أضافت عمود ImageUrl)
dotnet ef database update --project CarRental.Infrastructure --startup-project CarRental.API

# 2) التشغيل
dotnet run --project CarRental.API
```

ثم افتح **Swagger** على: `http://localhost:5109/swagger`

> **مهم:** لا تنسَ الخطوة الأولى. أُضيفت مُهاجَرة `AddCarImageUrlAndIndexes`، وبدون تطبيقها ستفشل عمليات السيارات.

### فحص الجاهزية
`GET /health`

---

## 3. المصادقة (JWT)

معظم عمليات القراءة العامة للسيارات مفتوحة، أما الإدارة فتحتاج رمزاً.

```bash
POST /api/auth/login
{ "username": "admin", "password": "Admin@12345" }
```

الاستجابة تحتوي على `token` — أرسله في كل طلب محمي:

```
Authorization: Bearer <token>
```

في Swagger اضغط زر **Authorize** والصق الرمز.

> ⚠️ **قبل التسليم أو النشر:** غيّر `Jwt:Key` و `AdminUser:Password` في `appsettings.json`.
> الأفضل استخدام `dotnet user-secrets` أو متغيّرات البيئة (`Jwt__Key`) بدلاً من وضعها في الكود.
> الحساب الحالي مُخزَّن في الإعدادات لتبسيط المشروع الدراسي؛ النظام الحقيقي يحتاج جدول مستخدمين بكلمات مرور مُشفَّرة (hashed).

### مستوى الحماية لكل نقطة

| النقاط | الحماية |
|---|---|
| `GET /api/cars`, `/api/cars/available`, `/api/cars/{id}` | مفتوحة (كتالوج عام للتطبيق) |
| `POST /api/rentals` · `GET /api/rentals/customer/{id}` | مفتوحة (العميل يحجز ويرى إيجاراته — التطبيق بلا تسجيل دخول) |
| باقي عمليات السيارات والإيجارات | تحتاج رمزاً |
| **كل** عمليات العملاء | تحتاج رمزاً (بيانات شخصية) |

---

## 4. نقاط النهاية (Endpoints)

### السيارات
| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/api/cars` | الكل، مع فلترة اختيارية `?status=` |
| GET | `/api/cars/available` | المتاحة للتأجير فقط |
| GET | `/api/cars/{id}` | سيارة واحدة |
| POST | `/api/cars` | إضافة — **نموذج multipart واحد: البيانات + الصورة معاً**، حقل `image` اختياري |
| PUT | `/api/cars/{id}` | تعديل — اترك `status` فارغاً للحفاظ على الحالة، واترك `image` فارغاً للحفاظ على الصورة، و`removeImage=true` لإزالتها |
| DELETE | `/api/cars/{id}` | حذف (409 إذا لها إيجارات) — يحذف ملف الصورة أيضاً |

### العملاء
| الطريقة | المسار |
|---|---|
| GET | `/api/customers` · `/api/customers/{id}` |
| POST | `/api/customers` |
| PUT | `/api/customers/{id}` |
| DELETE | `/api/customers/{id}` |

### الإيجارات
| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/api/rentals` | الكل |
| GET | `/api/rentals/customer/{customerId}` | سجل عميل — **مفتوحة** (شاشة «إيجاراتي» في التطبيق بلا تسجيل دخول) |
| GET | `/api/rentals/{id}` | إيجار واحد |
| POST | `/api/rentals` | حجز (السعر يُحسب في الخادم) |
| PUT | `/api/rentals/{id}` | تعديل الفترة |
| PUT | `/api/rentals/{id}/complete` | **إكمال — يُحرِّر السيارة** |
| PUT | `/api/rentals/{id}/cancel` | **إلغاء — يُحرِّر السيارة** |
| DELETE | `/api/rentals/{id}` | حذف (يُحرِّر السيارة) |

### الإحصائيات (للوحة التحكم)
| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/api/statistics?months=6` | أرقام اللوحة: الأسطول، العملاء، الإيجارات، الإيراد الكلي، وسلسلة الإيراد الشهري للرسوم البيانية |

### الحالات المسموحة
- **السيارة:** `Available` · `Rented` · `UnderMaintenance`
- **الإيجار:** `Active` · `Completed` · `Cancelled`

---

## 5. قواعد العمل المُطبَّقة

- `TotalPrice` **يُحسب في الخادم دائماً** (`PricePerDay × عدد الأيام`، بحد أدنى يوم واحد) — العميل لا يستطيع تحديد السعر.
- لا يمكن الحجز بتاريخ بداية في الماضي.
- `EndDate` يجب أن يكون بعد `StartDate` بيوم على الأقل.
- لا يمكن حجز سيارة بفترة تتعارض مع إيجار نشط آخر لنفس السيارة.
- لا يمكن تأجير سيارة حالتها `UnderMaintenance`.
- عند الحجز: إنشاء الإيجار وتغيير حالة السيارة يحدثان في **معاملة واحدة** (`SaveChanges` واحد).
- عند الإكمال/الإلغاء/الحذف: تُعاد السيارة إلى `Available` **فقط** إذا لم يبق إيجار نشط آخر عليها، ولا تُلمس إن كانت `UnderMaintenance`.
- الحذف محمي بالعلاقات: 409 مع سبب واضح بدلاً من خطأ 500.
- **صور السيارات:** تُرفع من الجهاز في نفس نموذج الإضافة/التعديل (Swagger يعرض زر اختيار ملف). الأنواع: jpg/jpeg/png/gif/webp حتى 5MB، والنوع الحقيقي يُفحص من بايتات الملف لا من الامتداد. الملفات تُحفظ في `wwwroot/uploads/` باسم مُولَّد آمن، وتُحذف تلقائياً عند الاستبدال أو الإزالة أو حذف السيارة.

---

## 6. تبديل مزوّد قاعدة البيانات

المزوّد الافتراضي **SQL Server**. يمكن تغييره للاختبار على أجهزة لا تتوفر فيها:

```json
{ "DatabaseProvider": "SqlServer" }   // SqlServer | Sqlite | InMemory
```

أو عبر متغيّرات البيئة:

```bash
DatabaseProvider=Sqlite \
ConnectionStrings__DefaultConnection="Data Source=carrental.db" \
dotnet run --project CarRental.API
```

**ملاحظة مهمة:** المُهاجَرات في `Migrations/` مُولَّدة لـ SQL Server. لذلك يُطبِّق المشروع
`Migrate()` على SQL Server فقط، ويستخدم `EnsureCreated()` مع المزوّدات البديلة —
لأن إعادة تشغيل مُهاجَرات SQL Server على SQLite تُطلق تحذير
`PendingModelChangesWarning` كاذباً بسبب اختلاف تحويل الأنواع بين المزوّدات.

---

## 7. CORS

للسماح لتطبيق Flutter ولوحة التحكم بالاتصال، حدّد النطاقات في `appsettings.json`:

```json
{ "Cors": { "AllowedOrigins": [ "https://localhost:7001", "http://localhost:3000" ] } }
```

إذا تُركت القائمة فارغة يُسمح لأي نطاق (مناسب للتطوير فقط — قيّدها قبل النشر).

---

## 8. معالجة الأخطاء

كل الاستجابات الخطأ بصيغة **ProblemDetails** (RFC 7807):

| الحالة | المعنى |
|---|---|
| 400 | مدخلات غير صحيحة |
| 401 | رمز مفقود أو غير صالح |
| 404 | المورد غير موجود |
| 409 | تعارض (بريد مكرر، تعارض تواريخ، حذف ممنوع بعلاقة) |
| 503 | قاعدة البيانات غير متاحة |

إذا تعذّر الوصول لقاعدة البيانات عند بدء التشغيل فإن التطبيق **يبدأ ويُسجّل الخطأ**
بدلاً من الانهيار، حتى يظهر السبب بوضوح.

---

## 9. توثيق Postman

مجموعة Postman كاملة في: `docs/CarRental.postman_collection.json`

- استوردها في Postman: **Import** ← اختر الملف.
- نفّذ طلب **Auth → Login** أولاً — سكربت الاختبار فيه يحفظ الرمز تلقائياً في متغيّر `{{token}}`، وكل الطلبات المحمية تستخدمه مباشرة.
- طلبات السيارات جاهزة بصيغة form-data — اختر الصورة من **Body → form-data → image → Select Files**.

---

## 10. الاختبار

يوجد سكربت اختبار شامل يضرب كل نقطة نهاية بطلبات HTTP حقيقية ويتحقق من رموز الحالة
ومن قواعد العمل: `tests/test_api.sh`

```bash
# نافذة 1
DatabaseProvider=Sqlite \
ConnectionStrings__DefaultConnection="Data Source=/tmp/carrental_test.db" \
ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS="http://127.0.0.1:5109" \
dotnet run --project CarRental.API

# نافذة 2
./tests/test_api.sh
```

آخر نتيجة: **101 اختبار ناجح، 0 فاشل.**
