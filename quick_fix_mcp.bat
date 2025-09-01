@echo off
echo 🚨 QUICK FIX for Flutter-docs MCP Server
echo ==========================================
echo.

echo Removing failed configuration...
claude mcp remove flutter-docs

echo.
echo Installing Flutter MCP globally...
npm install -g flutter-mcp

echo.
echo Testing installation...
npx flutter-mcp --version

echo.
echo Re-adding Flutter MCP server...
claude mcp add flutter-docs -- npx -y flutter-mcp

echo.
echo Adding Firebase MCP for good measure...
claude mcp add firebase -- npx -y firebase-tools@latest experimental:mcp

echo.
echo Listing all MCP servers...
claude mcp list

echo.
echo ✅ DONE! Restart Claude Code now.
echo Then test with: claude "Use flutter-docs to get BLoC documentation"
echo.
pause
