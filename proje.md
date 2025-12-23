# 📱 Besliyorum Satıcı - Technical Specification

> [!NOTE]
> This document serves as the **Single Source of Truth** for the project's architecture, coding standards, and workflows. All contributors must adhere to these guidelines.

## 🏗️ Architecture Overview

This project follows the **MVVM (Model-View-ViewModel)** architectural pattern to ensure separation of concerns, testability, and maintainability.

```mermaid
graph TD
    View[📱 View (UI)] <--> ViewModel[⚡ ViewModel (State)]
    ViewModel <--> Service[🔌 Service (Logic/API)]
    Service <--> Model[📦 Model (Data)]
    Service <--> API[🌐 Remote API]
```

| Component | Responsibility |
|-----------|----------------|
| **View** | Renders the UI and observes the ViewModel. No logic here. |
| **ViewModel** | Manages variable state and business logic. Bridges View and Service. |
| **Service** | Handles data operations (API calls) and transforms raw data into Models. |
| **Model** | Data structures defining the shape of API requests/responses. |

---

## 📂 Project Structure

Verified directory structure for the `lib` folder:

```text
lib/
├── core/
│   └── constants/
│       └── api_constants.dart      # Centralized API Endpoints
├── models/
│   ├── auth/                       # Authentication Models (Login, Register)
│   └── ...                         # Feature-specific Models
├── services/
│   ├── api_service.dart            # Core HTTP Client (Dio/Http)
│   ├── auth_service.dart           # Authentication Logic
│   └── ...                         # Feature Services
├── viewmodels/
│   ├── auth_viewmodel.dart         # Authentication State Management
│   └── ...                         # Feature ViewModels
└── views/
    ├── auth/                       # Login/Register Screens
    ├── home/                       # Dashboard Screens
    └── ...                         # Feature Views
```

---

## 📏 Development Standards

### 1. API Management
> [!IMPORTANT]
> **Hardcoding Endpoints is STRICTLY FORBIDDEN.**
> All URLs must be defined in `lib/core/constants/api_constants.dart`.

- **Base URL**: Managed centrally.
- **Endpoints**: Defined as static constants.

### 2. Error Handling Protocol
We use a specific protocol for backend validation errors.

- **Status Code 417**: Represents a **business logic/validation error** (e.g., "Wrong password", "User not found").
- **Action**: Display the `message` field from the API response directly to the user.
- **Do Not**: Write static error messages in the app for these cases.

**✅ Correct Implementation:**
```dart
if (response.statusCode == 417) {
  // Show the exact message from backend
  UiUtils.showError(response.data['message']);
}
```

**❌ Incorrect Implementation:**
```dart
if (response.statusCode == 417) {
  // NEVER do this
  UiUtils.showError("Hatalı giriş yaptınız.");
}
```

### 3. State Management (ViewModel)
- Extend `ChangeNotifier`.
- Expose strictly typed state variables.
- Use `Consumer` or `Provider.of` in Views to listen to changes.
- **Profile Data Policy**: Always fetch fresh user data (`getUser`) on Profile page entry (`initState`). Do not rely on cached data for profile views.

### 4. Models
- Every API interaction requires a typed **Request** and **Response** model.
- Use `json_serializable` or manual `fromJson`/`toJson` factories.
- All models must reside in `lib/models/`.

---

## 🚀 Workflow: Adding a New Feature

1.  **Define Models**: Create request/response classes in `lib/models/<feature>/`.
2.  **Add Service**: Create `lib/services/<feature>_service.dart` for API calls.
3.  **Create ViewModel**: Implement logic in `lib/viewmodels/<feature>_viewmodel.dart`.
4.  **Build View**: Create UI in `lib/views/<feature>/` and connect to ViewModel.
5.  **Register Provider**: Add the new ViewModel to the global provider list (if using MultiProvider).

---

## 📡 API Reference Example

### Login Flow
**Endpoint**: `POST {{BASE_URL}}/service/auth/login`

#### Request Payload
```json
{
  "user_name": "user_identifier",
  "password": "secure_password"
}
```

#### Response (Success 200)
```json
{
  "error": false,
  "success": true,
  "data": {
    "token": "ntc7P9L4YbmphYgCmuiaiCnuQDa6uYyY",
    "userID": 123
  }
}
```