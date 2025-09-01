@echo off
echo ===========================================
echo   SECURYFLEX MCP SETUP - DIRECT EXECUTION
echo ===========================================
echo.

echo [STEP 1] Installing Flutter MCP Server...
call npm install -g flutter-mcp
if %errorlevel% neq 0 (
    echo WARNING: Global install failed, trying local...
    call npx flutter-mcp --version
)

echo.
echo [STEP 2] Installing Firebase MCP Server...
call npm list -g firebase-tools >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Firebase Tools...
    call npm install -g firebase-tools
)

echo.
echo [STEP 3] Testing MCP Servers...
echo Testing Flutter MCP...
call npx flutter-mcp --version
echo Testing Firebase MCP...
call npx firebase-tools --version

echo.
echo [STEP 4] Setting up Claude Code MCP...
echo Adding Flutter Docs MCP Server...
call claude mcp add flutter-docs -- npx -y flutter-mcp

echo Adding Firebase MCP Server...
call claude mcp add firebase -- npx -y firebase-tools@latest experimental:mcp

echo.
echo [STEP 5] Verifying Setup...
call claude mcp list

echo.
echo ===========================================
echo   SETUP COMPLETE!
echo ===========================================
echo.
echo Next steps:
echo 1. Restart Claude Code completely
echo 2. Test with: claude "Use flutter-docs to get documentation for BLoC"
echo 3. Test Firebase: claude "Use firebase to check my Firestore structure"
echo.
pause
