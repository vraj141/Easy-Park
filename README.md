📌 Fully Updated README.md
md
Copy
Edit
# 🅿️ EasyPark - Smart Parking Solution

EasyPark is a **Flutter Web Application** integrated with **Firebase Authentication** to help users find nearby parking spots. This project also features **GitHub-JIRA integration** for issue tracking and collaboration.

---

## **🚀 Project Overview**
### 🔹 Features Implemented So Far
1. **Firebase Authentication**
   - User sign-up and login via email & password.
   - Secure authentication setup in Firebase.

2. **Location Detection**
   - Retrieves the user's real-time GPS location.
   - Displays latitude and longitude on the UI.

3. **JIRA-GitHub Integration**
   - Every code commit, branch, and pull request is linked to a **JIRA issue**.

---

## **📥 Getting Started**
### **🔹 Prerequisites**
Ensure you have the following installed:
- **Flutter** (Latest version) → [Download Here](https://flutter.dev/docs/get-started/install)
- **Dart SDK**
- **VS Code / Android Studio** (Optional for development)
- **Git** → [Download Here](https://git-scm.com/downloads)

### **🔹 Step 1: Clone the Repository**
```sh
git clone https://github.com/vraj141/Easy-Park.git
cd Easy-Park
🔹 Step 2: Install Dependencies
sh
Copy
Edit
flutter pub get
🔹 Step 3: Configure Firebase
Open Firebase Console
Create a new Firebase project or use the existing project: EasyPark141.
Register the app as a Web App.
Copy the Firebase SDK Config and replace it inside main.dart:
dart
Copy
Edit
await Firebase.initializeApp(
  options: FirebaseOptions(
    apiKey: "AIzaSyD3YJf3544zFcl2W17Cgx4BAJ3M4pjTNV8",
    authDomain: "easypark141.firebaseapp.com",
    projectId: "easypark141",
    storageBucket: "easypark141.firebasestorage.app",
    messagingSenderId: "1098576921917",
    appId: "1:1098576921917:web:cb174f4c5acb7a273b3154",
    measurementId: "G-9MJXH3W125",
  ),
);
🔹 Step 4: Run the Project
To launch the Flutter Web App:

sh
Copy
Edit
flutter run -d chrome
🛠️ JIRA Setup & Workflow
📌 JIRA Issue Tracking
JIRA is used for tracking project tasks, bug fixes, and new features.

🔹 How to Access JIRA
Accept the invitation link sent to your email.
Log in to JIRA Dashboard.
Navigate to the project EasyPark.
🔹 How to Create a JIRA Card (Issue)
Click on Create Issue.
Select Task, Story, or Bug.
Set a title (e.g., "Implement Login Feature").
Provide a detailed description of what needs to be done.
Click Create.
The Issue Key (e.g., EASYPARK-1) will be generated.
📌 Linking JIRA to GitHub
To ensure that JIRA tracks your Git commits, branches, and PRs, use the JIRA Issue Key in Git.

🔹 1️⃣ Create a Git Branch with the JIRA Issue Key
sh
Copy
Edit
git checkout -b EASYPARK-1-feature-name
git push origin EASYPARK-1-feature-name
✅ This will automatically appear in JIRA under the issue.

🔹 2️⃣ Make a Commit with the JIRA Issue Key
sh
Copy
Edit
git add .
git commit -m "Implemented Firebase Login - EASYPARK-1"
git push origin EASYPARK-1-feature-name
✅ JIRA will now track the commit.

🔹 3️⃣ Create a Pull Request (PR)
Go to GitHub → Easy-Park repository.
Click New Pull Request.
Set:
From branch: EASYPARK-1-feature-name
To branch: main
Title the PR using the JIRA issue key:
nginx
Copy
Edit
Added Login Feature - EASYPARK-1
Click Create Pull Request.
Merge the PR after review.
✅ JIRA will now automatically track the PR.

📌 Best Practices for JIRA-GitHub Workflow
✅ Always use the JIRA Issue Key in:

Branch names → EASYPARK-1-feature-name
Commit messages → "Updated UI for login - EASYPARK-1"
Pull Request titles → "Added login feature - EASYPARK-1"
🛠️ Troubleshooting
JIRA Not Showing Commits or Branches?
Ensure the JIRA Issue Key (e.g., EASYPARK-1) is in your commit message, branch name, and PR title.
Run:
sh
Copy
Edit
git remote -v
If it doesn’t show your GitHub repo, re-add it:
sh
Copy
Edit
git remote add origin https://github.com/vraj141/Easy-Park.git
git push -u origin main
Firebase Authentication Not Working?
Make sure Firebase Email/Password Sign-in is enabled.
Verify the firebase_options.dart file exists in the project.
📝 Contributors
Vraj Shah (@vraj141)
📄 License
This project is licensed under the MIT License.
For more details, see the LICENSE file.



---
