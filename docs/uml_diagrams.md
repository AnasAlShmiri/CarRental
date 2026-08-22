# المخططات الهيكلية والسلوكية — مشروع نظام تأجير السيارات

> ملاحظات الأسبوع الثالث (W3): المخططات مصممة لملف التوثيق الجامعي. يمكن تحويل كل مخطط إلى صورة PNG عبر `manus-render-diagram`.

## 1. مخطط المعمارية (Clean Architecture)

```mermaid
graph TB
    subgraph Presentation["طبقة العرض"]
        WEB["CarRental.Web<br/>ASP.NET Core 10 MVC<br/>(Dashboard, CRUD Views)"]
        API["CarRental.API<br/>RESTful Endpoints + JWT<br/>(/api/cars, /api/customers, /api/rentals)"]
        MOB["CarRental.Mobile<br/>Flutter (Android/iOS/Web)"]
    end
    subgraph Application["طبقة التطبيق"]
        SVC["Application Services<br/>+ DTOs<br/>+ Interfaces"]
    end
    subgraph Domain["طبقة النطاق"]
        ENT["Entities<br/>(Car, Customer, Rental)<br/>+ Enums + Business Rules"]
    end
    subgraph Infrastructure["طبقة البنية التحتية"]
        EF["EF Core 10<br/>+ DbContext"]
        DB[("SQLite / SQL Server")]
    end
    WEB --> SVC
    API --> SVC
    MOB --> API
    SVC --> ENT
    ENT --> EF
    EF --> DB
```

## 2. مخطط الحالات الاستخدامية (Use Case Diagram)

```mermaid
flowchart TB
    classDef actor fill:#1A73E8,color:white
    actor((Admin)):::actor
    actor2((Customer)):::actor
    subgraph System["نظام تأجير السيارات"]
        A1[حجز سيارة]
        A2[إلغاء / إكمال الإيجار]
        A3[إدارة السيارات<br/>إضافة/تعديل/حذف]
        A4[إدارة العملاء]
        A5[عرض لوحة الإحصائيات]
        A6[تسجيل الدخول JWT]
    end
    actor --> A1
    actor --> A2
    actor --> A3
    actor --> A4
    actor --> A5
    actor2 --> A1
    actor --> A6
    actor2 --> A6
```

## 3. مخطط التسلسل — حجز سيارة جديد (RentCar)

```mermaid
sequenceDiagram
    autonumber
    participant C as العميل / مدير النظام
    participant API as Web API (RentalsController)
    participant SVC as RentalService
    participant DB as قاعدة البيانات (EF Core)
    C->>API: POST /api/rentals (carId, startDate, endDate)
    API->>SVC: CreateRental(dto)
    SVC->>DB: البحث عن السيارة والتحقق من الحالة
    DB-->>SVC: Available
    SVC->>SVC: حساب المدة والسعر الإجمالي
    SVC->>DB: إدراج Rental + تحديث حالة السيارة إلى Rented
    DB-->>SVC: نجاح
    SVC-->>API: RentalDto
    API-->>C: 201 Created (بيانات الحجز)
```

## 4. مخطط التسلسل — المصادقة (Login)

```mermaid
sequenceDiagram
    autonumber
    participant C as المستخدم
    participant API as Web API (AuthController)
    participant SVC as AuthService
    participant DB as قاعدة البيانات
    C->>API: POST /api/auth/login (username, password)
    API->>SVC: Authenticate(dto)
    SVC->>DB: البحث عن المستخدم
    DB-->>SVC: المستخدم + Hash كلمة المرور
    SVC->>SVC: التحقق من كلمة المرور + إنشاء JWT
    SVC-->>API: Token + ExpiresAtUtc
    API-->>C: 200 OK (token, expiresAtUtc)
```

## 5. مخطط الأصناف (Class Diagram)

```mermaid
classDiagram
    class Car {
        +int Id
        +string Model
        +string Brand
        +decimal PricePerDay
        +string ImageUrl
        +CarStatus Status
        +DateTime CreatedAt
    }
    class CarStatus {
        <<enumeration>>
        Available
        Rented
        UnderMaintenance
    }
    class Customer {
        +int Id
        +string Name
        +string Phone
        +string Email
        +string LicenseNumber
        +DateTime CreatedAt
    }
    class Rental {
        +int Id
        +int CarId
        +int CustomerId
        +DateTime StartDate
        +DateTime EndDate
        +int DurationInDays
        +decimal TotalPrice
        +RentalStatus Status
    }
    class RentalStatus {
        <<enumeration>>
        Active
        Completed
        Cancelled
    }
    class User {
        +int Id
        +string Username
        +string PasswordHash
        +string Role
    }
    Car "1" -- "0..*" Rental : car
    Customer "1" -- "0..*" Rental : customer
    CarStatus ..> Car
    RentalStatus ..> Rental
```
