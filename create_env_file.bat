@echo off
REM Create .env file from .env.example

echo Creating .env file for Firebase configuration...
echo.

REM First run the setup script to create .env.example if it doesn't exist
if not exist .env.example (
    echo Creating .env.example first...
    call setup_firebase_env.bat
    echo.
)

REM Check if .env already exists
if exist .env (
    echo WARNING: .env file already exists!
    echo.
    choice /C YN /M "Do you want to overwrite it"
    if errorlevel 2 (
        echo Keeping existing .env file.
        pause
        exit /b 0
    )
)

REM Copy .env.example to .env
echo Copying .env.example to .env...
copy .env.example .env >nul

if errorlevel 1 (
    echo ERROR: Failed to create .env file!
    pause
    exit /b 1
)

echo.
echo SUCCESS: .env file created!
echo.
echo NEXT STEPS:
echo 1. Open .env file in a text editor (Notepad, VS Code, etc.)
echo 2. Replace these placeholder values with your real Firebase configuration:
echo    - your-actual-web-api-key
echo    - your-actual-android-api-key
echo    - your-actual-ios-api-key
echo    - securyflex-prod (your Firebase project ID)
echo    - etc.
echo.
echo 3. You can find these values in Firebase Console:
echo    https://console.firebase.google.com
echo    Go to Project Settings ^> General
echo.
echo 4. Save the .env file
echo.
echo 5. Run the app with: flutter run --dart-define-from-file=.env
echo.

REM Open the .env file in notepad for editing
choice /C YN /M "Do you want to open .env file now for editing"
if errorlevel 1 if not errorlevel 2 (
    notepad .env
)

pause