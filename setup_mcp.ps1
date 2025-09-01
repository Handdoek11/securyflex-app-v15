# SECURYFLEX MCP SETUP - PowerShell Version
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   SECURYFLEX MCP SETUP - DIRECT EXECUTION" -ForegroundColor Cyan  
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install Flutter MCP Server
Write-Host "[STEP 1] Installing Flutter MCP Server..." -ForegroundColor Yellow
try {
    npm install -g flutter-mcp
    Write-Host "✅ Flutter MCP installed globally" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Global install failed, testing npx..." -ForegroundColor Yellow
    npx flutter-mcp --version
}

# Step 2: Install Firebase Tools
Write-Host ""
Write-Host "[STEP 2] Installing Firebase MCP Server..." -ForegroundColor Yellow
try {
    npm list -g firebase-tools | Out-Null
    Write-Host "✅ Firebase Tools already installed" -ForegroundColor Green
} catch {
    Write-Host "Installing Firebase Tools..."
    npm install -g firebase-tools
}

# Step 3: Test installations
Write-Host ""
Write-Host "[STEP 3] Testing MCP Servers..." -ForegroundColor Yellow
Write-Host "Testing Flutter MCP..."
npx flutter-mcp --version
Write-Host "Testing Firebase MCP..."
npx firebase --version

# Step 4: Setup Claude Code MCP
Write-Host ""
Write-Host "[STEP 4] Setting up Claude Code MCP..." -ForegroundColor Yellow
Write-Host "Adding Flutter Docs MCP Server..."
claude mcp add flutter-docs -- npx -y flutter-mcp

Write-Host "Adding Firebase MCP Server..."
claude mcp add firebase -- npx -y firebase-tools@latest experimental:mcp

# Step 5: Verify
Write-Host ""
Write-Host "[STEP 5] Verifying Setup..." -ForegroundColor Yellow
claude mcp list

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   SETUP COMPLETE!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart Claude Code completely"
Write-Host "2. Test with: claude `"Use flutter-docs to get documentation for BLoC`""
Write-Host "3. Test Firebase: claude `"Use firebase to check my Firestore structure`""
Write-Host ""
Read-Host "Press Enter to continue..."
