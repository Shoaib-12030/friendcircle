@echo off
echo 🚀 Deploying Firestore Rules for Nickname Validation...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if errorlevel 1 (
    echo 🔐 Please login to Firebase:
    firebase login
)

REM Deploy only Firestore rules
echo 📤 Deploying Firestore security rules...
firebase deploy --only firestore:rules

if errorlevel 1 (
    echo ❌ Failed to deploy Firestore rules. Please check the error above.
    pause
    exit /b 1
) else (
    echo ✅ Firestore rules deployed successfully!
    echo.
    echo 📋 Changes made:
    echo    • Allowed nickname validation queries for unauthenticated users
    echo    • Added chat room and message permissions
    echo    • Updated friend request collection rules
    echo.
    echo 🎉 Your app should now be able to validate nicknames during registration!
    pause
)