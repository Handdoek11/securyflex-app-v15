@echo off
REM Run SecuryFlex with Firebase environment variables

echo Starting SecuryFlex with environment configuration...
echo.

REM Check if .env file exists
if not exist .env (
    echo ERROR: .env file not found!
    echo Please run setup_firebase_env.bat first and configure your Firebase settings.
    pause
    exit /b 1
)

REM Run Flutter with environment variables from .env file
echo Running Flutter with environment variables from .env...
flutter run --dart-define-from-file=.env

pause