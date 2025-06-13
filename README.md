🌾 Agri-Track Mobile App Setup Guide
Welcome to the setup guide for the Agri-Track mobile application. This document will help you set up your development environment and run the Flutter app on your device or emulator.

✅ 01. Prerequisites
Please install the following tools:

Flutter SDK: 3.29.0

Dart SDK: 3.7.0 (comes with Flutter)

Java JDK: 21.0.1

Git

Visual Studio Code (with Flutter & Dart extensions)

Android Studio (with Flutter plugin)

🛠️ 02. System Requirements
Ensure your PC has:

OS: Windows 10 or higher

RAM: 8 GB (Minimum 4 GB)

Disk Space: At least 20 GB free (Flutter, Android Studio, Emulator)

Screen Resolution: 1280x800 or higher

⚙️ 03. Enable Developer Mode (Windows Only)
To enable developer mode:

Press Win + S, search cmd

Right-click Command Prompt → Run as Administrator

Paste and run:

bash
Copy
Edit
ms-settings:developers
Enable Developer Mode from the settings window.

☕ 04. Install Java JDK (21.0.1)
Download from: https://www.oracle.com/java/technologies/

Install it normally.

Add JAVA_HOME to environment variables:

Right-click This PC → Properties → Advanced → Environment Variables

Add new system variable:

Name: JAVA_HOME

Value: C:\Program Files\Java\jdk-21.0.1

Open terminal and type:

bash
Copy
Edit
java -version
You should see java version "21.0.1".

💻 05. Install Android Studio + Emulator Setup
Download from https://developer.android.com/studio

Install and open Android Studio.

Go to Settings > Plugins → Install Flutter plugin (Dart will install automatically).

Go to AVD Manager → Create new emulator:

Device: Pixel 6a (or similar)

System Image: API 33 (Tiramisu - Android 13)

Finish setup and launch emulator

🧪 06. VSCode Setup (Recommended Editor)
Install VSCode

Go to Extensions (Ctrl + Shift + X)

Search and install:

Flutter

Dart

Verify Flutter Installation
Open terminal in VSCode and run:

bash
Copy
Edit
flutter doctor
Follow instructions to fix any errors.

📱 07. Run the App on Emulator
Launch emulator from Android Studio

In VSCode:

Open the project folder

Press Ctrl + Shift + P, search:

Flutter: Select Device → Choose emulator

Flutter: Run Project

App will now build and run on emulator. Use Hot Reload to see changes instantly.

✅ 08. Accept Android Licenses
Open terminal and run:

bash
Copy
Edit
flutter doctor --android-licenses
If any error comes:

Open Android Studio

Go to File > Settings > Appearance & Behavior > System Settings > Android SDK > SDK Tools

Install Android SDK Command-line Tools

Try the command again

🧪 09. Final Check (Flutter Doctor)
Run this command in terminal to verify everything:

bash
Copy
Edit
flutter doctor
Make sure all checks have ✅.

🧯 10. Troubleshooting
If you face issues:

Visit: https://docs.flutter.dev

Check VSCode or Android Studio terminal for error logs

Ask help from your team or search on StackOverflow

📞 11. Contact
Wanushka Lakmal
Email: wanushkalakmal@gmail.com
