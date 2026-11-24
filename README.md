# LSRMS — Limkokwing Student Results Management System

**Course:** Software Engineering  
**Assignment:** Assignment 2  
**Framework:** Flutter (Android APK & Web)

---

## Group Members (5 Members)

Fill in each group member's full name and Student ID below before submission:

| # | Full Name | Student ID | Role / Contribution |
| :- | :--- | :--- | :--- |
| 1 | *[Member 1 Full Name]* | *[Student ID 1]* | *[e.g., UI/UX Design & Dashboard]* |
| 2 | *[Eng Zeyad Mohamed Elgabry]* | *[905005887]* | *[e.g., State Management & RBAC]* |
| 3 | *[Member 3 Full Name]* | *[Student ID 3]* | *[e.g., Students & Modules Screens]* |
| 4 | *[Member 4 Full Name]* | *[Student ID 4]* | *[e.g., Summary, GPA & Account Management]* |
| 5 | *[Member 5 Full Name]* | *[Student ID 5]* | *[e.g., Android APK Build, Testing & Report]* |

---

## How the Application Works

**LSRMS** is structured around a centralized state and business-logic service (`ResultsService`) that manages student profiles, academic modules, recorded marks, prototype user accounts, and role-based access permissions.

1. **Authentication & Session Management:**
   - Users sign in with their email and password against the seeded or administrator-created accounts in `ResultsService`.
   - The active session tracks the current user's email and role (`Administrator`, `Lecturer`, or `Student`), updating the UI reactively via `ChangeNotifier` and `AnimatedBuilder`.

2. **Role-Based Access Control (RBAC):**
   - **Administrator:** Full system access—can register students and modules, record or update marks, delete student records, manage accounts (create, edit credentials, delete), and promote/demote Lecturer accounts to/from `Administrator` using a green toggle switch in `ManageAccountsScreen`.
   - **Lecturer:** Can browse all students, modules, and class summaries, and record or update student marks (`canRecordMarks`), without permissions to add/delete students or modules or manage user accounts.
   - **Student:** Strictly **read-only** access restricted to their own linked student record (`currentStudentRecord`). Students cannot view other students' records, cannot record/update marks, and cannot delete records.

3. **Academic Overview, Modules & Summary:**
   - **Dashboard (`DashboardPage`):** Displays a role-aware welcome banner, compact `StatCard` metrics, role-filtered `Quick Actions`, and student results preview.
   - **Students (`StudentsPage` & `StudentDetailScreen`):** Supports live search by name, ID, or programme for staff, and presents module-by-module marks, grades, remarks, and overall standing.
   - **Modules (`ModulesPage`):** Lists registered academic modules with credit hours, module averages (or the signed-in student's individual score), and grade chips (`GradeChip`).
   - **Summary (`SummaryPage`):** Displays a personal academic summary (average score, estimated GPA, graded modules, and overall grade) for `Student` users, and class-wide `Overview` analytics plus `Grade Distribution` for `Administrator` and `Lecturer` users.

---

## Key Features

- **Role-Based Views & Read-Only Enforcement:** Separate workflows and permissions for `Administrator`, `Lecturer`, and `Student` roles.
- **Account Management & Admin Promotion Toggle:** Administrators can create `Lecturer` and `Student` accounts (with optional `linkedStudentId`), inspect and edit credentials, remove accounts, and promote or demote Lecturers using a green toggle switch.
- **Personal Student Summary & GPA Estimation:** Tailored summary view for students displaying their personal average, estimated GPA, graded modules, and overall standing.
- **Module & Class Analytics:** Automatic calculation of module averages, student averages, pass rates, highest/lowest averages, and grade distribution bars.
- **Built-in Academic Utilities:** Interactive Grade Calculator, official Grading Scale reference, and About LSRMS screen accessible from the navigation drawer.

---

## Seeded Accounts & Student Credentials

### Staff Accounts
- **Administrator:** Configured via `AppConstants.adminEmail` and `AppConstants.adminPassword`
- **Lecturer:** Configured via `AppConstants.lecturerEmail` and `AppConstants.lecturerPassword`

### Seeded Student Accounts (`@lincolnqueen.education`)
Each student account is linked to its respective `studentId` so signing in displays that student's personal academic record:

| Student Name | Student ID | Email | Default Password |
| :--- | :--- | :--- | :--- |
| Aminata Kamara | `BSEM1201F` | `aminata.kamara@lincolnqueen.education` | `Student@1201` |
| Mohamed Sesay | `BSEM1202F` | `mohamed.sesay@lincolnqueen.education` | `Student@1202` |
| Zeyad Elgabry | `BSEM1203F` | `zeyad.elgabry@lincolnqueen.education` | `Student@1203` |
| Fatmata Koroma | `BSIT1104F` | `fatmata.koroma@lincolnqueen.education` | `Student@1104` |
| Ibrahim Bangura | `BSIT1105F` | `ibrahim.bangura@lincolnqueen.education` | `Student@1105` |
| Mariama Conteh | `BBIT1098F` | `mariama.conteh@lincolnqueen.education` | `Student@1098` |

---

## Running & Building the Project

```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run on Chrome (Web)
flutter run -d chrome

# Build Android Release APK
flutter build apk --release
```