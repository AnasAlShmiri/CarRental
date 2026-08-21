# CarRental — نظام إدارة تأجير السيارات

نظام **Full-Stack** لإدارة تأجير السيارات، يتكون من لوحة إدارة عربية RTL مبنية بـ ASP.NET Core MVC، وواجهة Web API محمية بـ JWT، وتطبيق Flutter مخصص للعميل. يعتمد المشروع على قاعدة SQLite مشتركة في جذر المستودع حتى ترى لوحة الإدارة وواجهة API وتطبيق الجوال البيانات نفسها عند التشغيل المحلي.

> هذا المستودع يستهدف .NET 10 وFlutter 3.35 أو أحدث. تشغيل API وMVC محليًا لا يحتاج إلى متغيرات بيئية يدوية؛ ملفات Windows الموجودة في الجذر تهيئ التشغيل المحلي تلقائيًا.

## المكونات

| المكوّن | الوظيفة | التقنية |
|---|---|---|
| `CarRental.API` | API للمصادقة والكتالوج والعملاء والحجوزات والإحصائيات والصور | ASP.NET Core Web API 10 + JWT |
| `CarRental.Web` | لوحة الإدارة وإدارة السيارات والعملاء والحجوزات والإحصائيات | ASP.NET Core MVC 10 + Cookie Authentication |
| `CarRental.Mobile` | تطبيق العميل للتسجيل وتصفح السيارات والحجز وإدارة الحجوزات والملف الشخصي | Flutter |
| `CarRental.Domain` | الكيانات وقواعد النطاق والحالات | .NET Class Library |
| `CarRental.Application` | DTOs والعقود وعمليات التحويل | .NET Class Library |
| `CarRental.Infrastructure` | EF Core وSQLite والمستودعات والتخزين المحلي وJWT | EF Core 10 |

يُحافظ المشروع على اسم الخاصية `CarModel` في `CarRental.Web/Models/CarViewModel.cs` لأنه جزء من عقد لوحة MVC الحالي.

## البنية

```text
CarRental/
├── CarRental.API/             # Web API على المنفذ 5109
├── CarRental.Web/             # لوحة الإدارة على المنفذ 5110
├── CarRental.Mobile/          # تطبيق Flutter للعميل
├── CarRental.Domain/          # Domain models and exceptions
├── CarRental.Application/     # DTOs, interfaces, mappings
├── CarRental.Infrastructure/  # DbContext, repositories, storage, auth
├── tests/test_api.sh          # اختبارات HTTP شاملة
├── docs/professional_audit.md # سجل التدقيق والإصلاحات
├── Run-CarRental.cmd          # تشغيل API ثم MVC وفتح المتصفح
├── Run-API.cmd                # تشغيل API فقط
├── Run-MVC.cmd                # تشغيل لوحة MVC فقط
└── Run-Mobile.cmd             # تشغيل تطبيق Flutter
```

## المتطلبات

يحتاج تشغيل الواجهة الخلفية إلى **.NET SDK 10**. يحتاج تطبيق الجوال إلى **Flutter SDK** مع جهاز أو محاكي متصل. في Windows يجب تثبيت Visual Studio أو .NET SDK مع أدوات ASP.NET Core، وفي Android يجب تفعيل Android SDK أو استخدام جهاز Android متصل بوضع التصحيح.

لا يحتاج التشغيل المحلي إلى SQL Server؛ فالإعداد الافتراضي هو SQLite. لا تُرفع قاعدة `car-rental.db` إلى GitHub، فهي ملف تشغيل محلي وموجود في `.gitignore`.

## التشغيل السريع على Windows

بعد استنساخ المستودع، افتح PowerShell داخل مجلد `CarRental` وتأكد أن الملفات `Run-CarRental.cmd` و`Run-API.cmd` و`Run-MVC.cmd` موجودة في **جذر المستودع**. شغّل السكربت من PowerShell بالطريقة التالية:

```powershell
cd C:\path\to\CarRental
.\Run-CarRental.cmd
```

يشغّل السكربت API على `http://localhost:5109`، ينتظر أن تصبح نقطة `/health` جاهزة، ثم يشغّل لوحة MVC على `http://localhost:5110` ويفتح المتصفح. إذا لم يتعرف Windows على `dotnet` فتأكد من تثبيت .NET SDK وإعادة فتح PowerShell. لا تستخدم `.Run-CarRental.cmd`؛ الصيغة الصحيحة هي ` .\Run-CarRental.cmd` كما في المثال، مع حذف المسافة الموجودة قبل الأمر عند النسخ.

للتشغيل المنفصل:

```powershell
.\Run-API.cmd
.\Run-MVC.cmd
```

يجب تشغيل API قبل MVC لأن لوحة الإدارة ترسل طلباتها إلى API. لا تفتح نسخة ثانية من API على المنفذ نفسه؛ إذا ظهر خطأ `address already in use` أغلق النسخة القديمة أو أعد تشغيل الجهاز ثم شغّل السكربت مرة واحدة.

## التشغيل من Visual Studio

افتح `CarRental.slnx` في Visual Studio الذي يدعم .NET 10، ثم اختر مشروع `CarRental.Web` كمشروع التشغيل. شغّل API أولًا أو استخدم ملف `Run-CarRental.cmd` خارج Visual Studio لضمان ترتيب التشغيل. يمكن أيضًا تشغيل المشروعين معًا من إعدادات **Multiple startup projects**، مع تشغيل `CarRental.API` قبل `CarRental.Web`.

بعد التشغيل افتح لوحة الإدارة على:

```text
http://localhost:5110
```

وتتوفر Swagger على:

```text
http://localhost:5109/swagger
```

وفحص الجاهزية على:

```text
http://localhost:5109/health
```

## قاعدة البيانات والمسار المشترك

الافتراضي هو:

```text
Data Source=../car-rental.db
```

يُحوّل `DatabasePathResolver` هذه القيمة إلى ملف مطلق في جذر المستودع، لذلك تستخدم API وMVC قاعدة SQLite نفسها حتى عند بدء التشغيل من مجلدات مختلفة. عند أول تشغيل تُنشأ الجداول تلقائيًا، وتُطبق ترقية توافق SQLite لإضافة الأعمدة المطلوبة دون حذف البيانات. كما تُستخدم إعدادات `WAL` و`foreign_keys` و`busy_timeout` لتحسين تحمل الإيقاف المفاجئ وتقليل تعارضات الكتابة.

يمكن تشغيل الاختبارات على قاعدة مؤقتة بدل قاعدة التطوير:

```powershell
$env:DatabaseProvider = "Sqlite"
$env:ConnectionStrings__DefaultConnection = "Data Source=C:\Temp\carrental-test.db"
dotnet run --project CarRental.API\CarRental.API.csproj --no-launch-profile
```

في بيئة الإنتاج يجب استخدام إعدادات أسرار آمنة وقاعدة مدارة أو مسار تخزين دائم. لا تعتمد على ملف SQLite داخل مجلد مؤقت أو على النسخ الموجودة داخل `CarRental.API` أو `CarRental.Web`.

## حسابات المستخدمين والمصادقة

هناك نوعان منفصلان من الحسابات:

| النوع | مكان الاستخدام | الآلية |
|---|---|---|
| Admin | لوحة MVC وإدارة السيارات والعملاء والحجوزات والإحصائيات | Cookie في MVC وJWT عند استدعاء API |
| Customer | تطبيق Flutter وموارد العميل الذاتية | JWT مع `customer_id` وRole=`Customer` |

تسجيل العميل ودخوله:

```text
POST /api/customer-auth/register
POST /api/customer-auth/login
GET  /api/customer-auth/me
PUT  /api/customer-auth/me
```

لا يستطيع العميل الوصول إلى مسارات الإدارة، ولا يستطيع المدير استخدام مسارات ملف العميل الذاتية. يأخذ API هوية العميل من مطالبة JWT ولا يثق بمعرف عميل يرسله المستخدم في مساراته الذاتية.

إعدادات التطوير المحلية موجودة في `appsettings.Development.json` ولا يجب نسخها إلى بيئة إنتاج. في بيئة غير Development يرفض API التشغيل إذا كان مفتاح JWT مفقودًا أو قصيرًا أو افتراضيًا، أو إذا بقيت كلمة مرور المدير الافتراضية. يجب توفير القيم عبر Secret Manager أو متغيرات البيئة، مثل `Jwt__Key` و`AdminUser__Password`.

مسارات المصادقة محددة المعدل. عند تجاوز الحد يعيد API `429 Too Many Requests` بصيغة ProblemDetails بدل السماح بمحاولات تخمين غير محدودة.

## لوحة الإدارة MVC

لوحة الإدارة عربية RTL وبتصميم Premium Luxury، وتوفر إدارة السيارات والعملاء والحجوزات والإحصائيات. عمليات الإنشاء والتعديل والحذف محمية بالمصادقة والتفويض، وتتحقق من السعر والحالة والهاتف والبريد قبل إرسال الطلب. تعرض اللوحة تعارضات الحجز ورسائل أخطاء API بصورة مفهومة، وتتعامل مع انتهاء جلسة الإدارة بدل عرض خطأ عام للمستخدم.

للدخول المحلي، استخدم بيانات التطوير الموجودة في `CarRental.API/appsettings.Development.json` فقط. لا تظهر كلمة المرور في صفحة الدخول أو في README ولا ينبغي استخدام بيانات التطوير خارج الجهاز المحلي.

## تطبيق Flutter للعميل

تطبيق Flutter ليس لوحة إدارة. وظيفته هي تجربة العميل الكاملة:

1. إنشاء حساب عميل بالبريد الإلكتروني والهاتف وكلمة مرور قوية.
2. تسجيل الدخول واستعادة جلسة العميل من التخزين المحلي.
3. عرض السيارات المتاحة والصور التي ترفعها لوحة MVC عبر API.
4. إنشاء حجز مع اختيار فترة الإيجار، بينما يحسب الخادم السعر النهائي.
5. عرض حجوزات العميل الحالي فقط وإلغاء الحجز.
6. عرض وتحديث ملف العميل.
7. تحويل أخطاء API وProblemDetails إلى رسائل عربية واضحة.
8. حذف جلسة JWT محليًا عند استجابة `401` حتى لا تستمر الطلبات باستخدام جلسة منتهية.

عنوان API مضبوط مركزيًا في `CarRental.Mobile/lib/core/api_config.dart`:

| بيئة Flutter | العنوان الافتراضي |
|---|---|
| Android Emulator | `http://10.0.2.2:5109` |
| Flutter Web أو Windows | `http://localhost:5109` |
| هاتف فعلي | ضع عنوان LAN للحاسوب في `physicalDeviceBaseUrl` مثل `http://192.168.1.5:5109` |

لتشغيل التطبيق:

```powershell
cd C:\path\to\CarRental
.\Run-API.cmd
.\Run-Mobile.cmd
```

أو يدويًا:

```powershell
cd CarRental.Mobile
flutter pub get
flutter run
```

يجب أن يكون الهاتف أو المحاكي قادرًا على الوصول إلى الحاسوب عبر الشبكة، وأن يسمح جدار Windows الناري بالاتصال بالمنفذ `5109` عند استخدام هاتف فعلي. عند إضافة سيارة من لوحة MVC، تُحفظ الصورة في مجلد `CarRental.Web/wwwroot/uploads` ويقدمها API من المسار نفسه لتظهر في Flutter.

## أهم نقاط API

### السيارات

| الطريقة | المسار | الحماية | الوصف |
|---|---|---|---|
| `GET` | `/api/cars` | عام | كتالوج السيارات مع فلترة اختيارية |
| `GET` | `/api/cars/available` | عام | السيارات المتاحة |
| `GET` | `/api/cars/{id}` | عام | سيارة واحدة |
| `POST` | `/api/cars` | Admin | إضافة سيارة وصورة اختيارية بصيغة multipart |
| `PUT` | `/api/cars/{id}` | Admin | تعديل سيارة أو استبدال/إزالة الصورة |
| `DELETE` | `/api/cars/{id}` | Admin | حذف السيارة إذا لم تمنعه علاقة إيجار |

### العملاء

| الطريقة | المسار | الحماية | الوصف |
|---|---|---|---|
| `GET` | `/api/customers` | Admin | قائمة العملاء |
| `GET` | `/api/customers/{id}` | Admin | بيانات عميل |
| `POST` | `/api/customers` | Admin | إنشاء عميل من لوحة الإدارة |
| `PUT` | `/api/customers/{id}` | Admin | تعديل بيانات عميل |
| `DELETE` | `/api/customers/{id}` | Admin | حذف عميل عند عدم وجود علاقات مانعة |
| `POST` | `/api/customer-auth/register` | عام | تسجيل عميل جديد |
| `POST` | `/api/customer-auth/login` | عام | دخول العميل |
| `GET` | `/api/customer-auth/me` | Customer | الملف الشخصي للعميل الحالي |
| `PUT` | `/api/customer-auth/me` | Customer | تعديل الملف الشخصي |

### الحجوزات

| الطريقة | المسار | الحماية | الوصف |
|---|---|---|---|
| `GET` | `/api/rentals` | Admin | جميع الحجوزات |
| `GET` | `/api/rentals/{id}` | Admin | حجز واحد |
| `POST` | `/api/customer/rentals` | Customer | إنشاء حجز للعميل المصادق عليه |
| `GET` | `/api/customer/rentals` | Customer | حجوزات العميل الحالي فقط |
| `POST` | `/api/customer/rentals/{id}/cancel` | Customer | إلغاء حجز العميل الحالي |
| `POST` | `/api/rentals` | Admin | إنشاء حجز إداري من لوحة الإدارة |
| `PUT` | `/api/rentals/{id}` | Admin | تعديل فترة الحجز الإداري |
| `PUT` | `/api/rentals/{id}/complete` | Admin | إكمال الحجز وتحرير السيارة |
| `PUT` | `/api/rentals/{id}/cancel` | Admin | إلغاء الحجز وتحرير السيارة |
| `DELETE` | `/api/rentals/{id}` | Admin | حذف الحجز |

`totalPrice` يحسبه الخادم دائمًا. تبدأ التواريخ من يوم UTC كامل، ولا يسمح النظام بتاريخ بداية ماضٍ أو بفترة نهاية غير صحيحة أو بتداخل حجزين نشطين للسيارة نفسها. تعارض التوافر يعيد `409 Conflict` بدل استجابة `500` غامضة.

### الإحصائيات والصور

```text
GET /api/statistics?months=6       # Admin
GET /uploads/{fileName}            # صورة سيارة عامة عبر API
```

تقبل صور السيارات `jpg` و`jpeg` و`png` و`gif` و`webp` حتى 5MB، ويُفحص نوع الملف من محتواه الفعلي لا من الامتداد وحده. يستخدم API ومجلد MVC مسار الصور المشترك نفسه.

## التحقق ومعالجة الأخطاء

تستخدم DTOs قواعد تحقق للحقول النصية والبريد والهاتف والسعر والتاريخ والحالات المسموحة. كلمة مرور العميل يجب أن تحقق طولًا أدنى، وتحتوي على أحرف كبيرة وصغيرة ورقم ورمز، ولا تقبل المسافات أو القيم الضعيفة وفق القاعدة المشتركة بين API وFlutter.

كل أخطاء API المهمة تستخدم صيغة ProblemDetails أو ValidationProblemDetails:

| الحالة | المعنى |
|---|---|
| `400` | مدخلات غير صحيحة |
| `401` | رمز مفقود أو منتهي أو غير صالح |
| `403` | الدور لا يملك الصلاحية |
| `404` | المورد غير موجود |
| `409` | تعارض بريد أو حجز أو علاقة حذف |
| `429` | تجاوز معدل المصادقة |
| `503` | عدم توفر قاعدة البيانات أو مورد تابع |

## الاختبارات

تشغيل اختبارات API من PowerShell بعد تشغيل API:

```powershell
bash tests/test_api.sh
python3 /tmp/test_customer_flow.py
python3 /tmp/test_role_boundaries.py
```

تشغيل اختبارات Flutter:

```powershell
cd CarRental.Mobile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

آخر بوابة جودة موثقة في هذا الفرع:

| الفحص | النتيجة |
|---|---|
| بناء API وMVC | ناجح دون أخطاء ترجمة |
| Flutter analyze | ناجح دون أخطاء |
| Flutter test | جميع الاختبارات الحالية ناجحة |
| اختبار API الشامل | **126 ناجحًا، 0 فاشل** |
| رحلة تسجيل العميل والحجز والإلغاء | ناجحة |
| حدود أدوار Customer وAdmin | ناجحة |

التفاصيل والمخاطر المتبقية موثقة في [`docs/professional_audit.md`](docs/professional_audit.md).

## Git workflow

الفرع الحالي للتعديلات هو `fix/portable-windows-config`، وPull Request رقم `#8` مفتوح باتجاه `mvc-dashboard`. بعد مراجعة التغييرات محليًا:

```bash
git status
git diff --stat
git add -A
git commit -m "fix: professional quality improvements"
git push origin fix/portable-windows-config
```

لا ترفع `car-rental.db` أو ملفات الأسرار أو مجلدات build. لا تستخدم `appsettings.Development.json` كإعداد إنتاج. قبل الدمج النهائي راجع أن Pull Request رقم `#8` يحتوي آخر commit وأن الاختبارات المذكورة أعلاه مرت من قاعدة SQLite مؤقتة نظيفة.

## حدود النشر الحقيقي

الإعداد الحالي مناسب لتشغيل محلي أو مشروع دراسي متكامل. قبل النشر العام يجب استخدام مفتاح JWT طويل وسري، تغيير كلمة مرور المدير، تقييد CORS إلى نطاقات معروفة، استخدام تخزين صور دائم وآمن، إضافة نظام مستخدمي إدارة متعدد الحسابات مع كلمات مرور مجزأة، وتوفير نسخ احتياطية لقاعدة البيانات ومراقبة تشغيلية. لا تعتبر قيم `appsettings.Development.json` أسرار نشر.
