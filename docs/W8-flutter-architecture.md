# W8 — Flutter Architecture, Screens, Navigation and API Integration

## 1. نطاق الأسبوع الثامن

يهدف تنفيذ W8 إلى تحويل تطبيق CarRental Mobile من شاشات مرتبطة مباشرة بخدمة HTTP إلى بنية منظمة قابلة للتوسعة والاختبار. يعتمد التطبيق على واجهة عربية RTL، ويستخدم JWT للمصادقة مع Web API الخاص بالمشروع.

## 2. Architecture

تم اعتماد بنية مبسطة متعددة الطبقات:

| الطبقة | المسار | المسؤولية |
|---|---|---|
| Core | `lib/core` | إعداد API، عميل HTTP، تخزين الجلسة، الأخطاء والثيم |
| Data | `lib/data` | نماذج DTOs وRepositories التي تتعامل مع عقود Web API |
| Presentation | `lib/presentation` | Controllers وإدارة حالة الشاشات باستخدام `ChangeNotifier` |
| Screens | `lib/screens` | Widgets والواجهات العربية وتدفقات المستخدم |
| App composition | `lib/app_scope.dart` | إنشاء الاعتمادات وحقنها في شجرة التطبيق |

يمر طلب البيانات بالمسار التالي:

> Screen → Controller → Repository → ApiClient → Web API

ولا تحتوي الشاشات الجديدة على تفاصيل HTTP أو تخزين JWT؛ إذ تقتصر مسؤوليتها على العرض والتفاعل.

## 3. Models and Repositories

تطابق نماذج `Car` و`Rental` و`Customer` و`AuthSession` عقود API الرسمية، بما في ذلك الحقول الفرعية للسيارة والعميل داخل `RentalDto`. تتولى `AuthRepository` تسجيل الدخول وتخزين الرمز وتستعيد الجلسة عند بدء التطبيق، بينما توفر `CarRepository` و`RentalRepository` و`CustomerRepository` عمليات القراءة والإنشاء المطلوبة للتدفقات الأساسية.

## 4. Navigation

يستخدم التطبيق `MaterialApp` مع مسارات مسماة مركزية:

| المسار | الشاشة |
|---|---|
| `/` | `AuthGate` لتحديد حالة الجلسة |
| `/login` | تسجيل الدخول |
| `/home` | الهيكل الرئيسي للتطبيق |

يحتوي `HomeScreen` على `IndexedStack` و`NavigationBar` للتنقل بين السيارات والإيجارات والملف الشخصي، بالإضافة إلى Drawer موحّد. عند نجاح تسجيل الدخول أو الخروج يتم تنظيف سجل التنقل باستخدام `pushNamedAndRemoveUntil`.

## 5. Screens

تشمل نسخة W8 الشاشات التالية:

- **LoginScreen:** تحقق من الحقول، إظهار/إخفاء كلمة المرور، حالة تحميل، ورسائل خطأ عربية.
- **HomeScreen:** تنقل رئيسي موحد وDrawer للحساب والمسارات.
- **CarsScreen:** إحصائيات الأسطول، تحديث بالسحب، حالات متاحة ومؤجرة، تفاصيل مختصرة، وحالة خطأ/فراغ.
- **RentalsScreen:** فلاتر الحالة، بطاقات الحجز، تواريخ ومدة وقيمة الإيجار، وتدفق إنشاء حجز.
- **ProfileScreen:** معلومات الحساب، حالة الجلسة، اللغة، وتسجيل الخروج.

## 6. API Integration and JWT

يستخدم `ApiClient` عنوان `ApiConfig.baseUrl` ويضيف رأس `Authorization: Bearer <token>` للطلبات المحمية. المسارات المستخدمة هي:

| العملية | المسار | الحماية |
|---|---|---|
| Register | `POST /api/customer-auth/register` | عامة |
| Login | `POST /api/customer-auth/login` | عامة |
| Profile | `GET /api/customer-auth/me` | Customer JWT |
| Update profile | `PUT /api/customer-auth/me` | Customer JWT |
| Available cars | `GET /api/cars/available` | عامة |
| My rentals | `GET /api/customer/rentals` | Customer JWT |
| Create rental | `POST /api/customer/rentals` | Customer JWT |
| Cancel rental | `POST /api/customer/rentals/{id}/cancel` | Customer JWT |

تقرأ `SessionStore` الرمز واسم المستخدم والدور ووقت الانتهاء من `SharedPreferences`. عند انتهاء الجلسة أو تسجيل الخروج يتم حذف جميع بيانات المصادقة محليًا.

## 7. التشغيل

من جذر المستودع على Windows يمكن تشغيل `Run-Mobile.cmd`؛ فهو يبحث عن Flutter في PATH والمسارات الشائعة ثم ينفذ `flutter pub get` و`flutter run`. يدويًا من مجلد `CarRental.Mobile`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

يختار `ApiConfig` عنوان `http://10.0.2.2:5109` تلقائيًا لمحاكي Android، و`http://localhost:5109` للويب وiOS Simulator. على جهاز حقيقي اضبط `physicalDeviceBaseUrl` على عنوان IP المحلي لجهاز تشغيل Web API، مثل `http://192.168.1.5:5109`.

## 8. المخرجات التعليمية لـ W8

يحقق التنفيذ متطلبات الأسبوع الثامن من خلال فصل المسؤوليات، بناء شاشات عملية، توحيد التنقل، استخدام إدارة حالة خفيفة قابلة للفهم، وربط التطبيق بعقود API محمية بـ JWT. كما أن الطبقات الجديدة تسمح بإضافة اختبارات Repository أو استبدال مصدر البيانات دون تعديل Widgets.
