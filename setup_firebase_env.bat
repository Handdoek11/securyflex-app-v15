@echo off
REM Setup Firebase Environment Variables for SecuryFlex
REM Run this script to configure Firebase for development

echo Setting up Firebase environment variables for SecuryFlex...
echo.

REM Create a .env file for development
echo Creating .env file for development...

(
echo # Firebase Configuration for SecuryFlex
echo # DO NOT COMMIT THIS FILE TO VERSION CONTROL
echo.
echo # Replace these with your actual Firebase project values
echo # You can find these in your Firebase Console:
echo # https://console.firebase.google.com/project/YOUR_PROJECT/settings/general/
echo.
echo FIREBASE_WEB_API_KEY=your-actual-web-api-key
echo FIREBASE_ANDROID_API_KEY=your-actual-android-api-key
echo FIREBASE_IOS_API_KEY=your-actual-ios-api-key
echo FIREBASE_PROJECT_ID=securyflex-prod
echo FIREBASE_MESSAGING_SENDER_ID=your-sender-id
echo FIREBASE_WEB_APP_ID=your-web-app-id
echo FIREBASE_ANDROID_APP_ID=your-android-app-id
echo FIREBASE_IOS_APP_ID=your-ios-app-id
echo FIREBASE_AUTH_DOMAIN=securyflex-prod.firebaseapp.com
echo FIREBASE_STORAGE_BUCKET=securyflex-prod.appspot.com
echo FIREBASE_MEASUREMENT_ID=your-measurement-id
echo.
echo # API Keys for external services
echo GOOGLE_MAPS_API_KEY=your-google-maps-api-key
echo STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
echo STRIPE_SECRET_KEY=your-stripe-secret-key
echo.
echo # Feature flags
echo ENABLE_BIOMETRIC_AUTH=true
echo ENABLE_LOCATION_TRACKING=true
echo ENABLE_ENCRYPTION=true
echo ENABLE_ANALYTICS=true
echo.
echo # Security settings
echo BSN_ENCRYPTION_ENABLED=true
echo LOCATION_ENCRYPTION_ENABLED=true
echo SESSION_TIMEOUT_MINUTES=30
echo MAX_LOGIN_ATTEMPTS=5
) > .env.example

echo.
echo .env.example file created successfully!
echo.
echo IMPORTANT STEPS:
echo 1. Copy .env.example to .env
echo 2. Replace all placeholder values with your actual Firebase configuration
echo 3. Add .env to your .gitignore file (if not already there)
echo 4. Never commit .env to version control
echo.
echo To run the app with environment variables, use:
echo flutter run --dart-define-from-file=.env
echo.
echo Or for production builds:
echo flutter build apk --dart-define-from-file=.env.production
echo.

REM Check if .gitignore exists and add .env if not present
if exist .gitignore (
    findstr /C:".env" .gitignore >nul
    if errorlevel 1 (
        echo. >> .gitignore
        echo # Environment files >> .gitignore
        echo .env >> .gitignore
        echo .env.* >> .gitignore
        echo !.env.example >> .gitignore
        echo Added .env to .gitignore
    ) else (
        echo .env is already in .gitignore
    )
) else (
    echo # Environment files > .gitignore
    echo .env >> .gitignore
    echo .env.* >> .gitignore
    echo !.env.example >> .gitignore
    echo Created .gitignore with .env entries
)

echo.
echo Setup complete!
pause