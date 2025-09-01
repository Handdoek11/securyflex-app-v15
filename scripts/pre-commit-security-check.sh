#!/bin/bash

# 🛡️ SecuryFlex Pre-Commit Security Check
# Prevents hardcoded secrets, API keys, and credentials from being committed

echo "🛡️ Running SecuryFlex Security Checks..."

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Exit code (0 = success, 1 = failure)
exit_code=0

# Function to check for patterns
check_pattern() {
    local pattern=$1
    local description=$2
    local files=$3
    
    echo "Checking for $description..."
    
    if echo "$files" | xargs grep -l "$pattern" 2>/dev/null; then
        echo -e "${RED}❌ SECURITY VIOLATION: Found $description${NC}"
        echo -e "${RED}   Files containing violations listed above${NC}"
        echo -e "${YELLOW}   Please remove hardcoded secrets and use environment variables${NC}"
        exit_code=1
    else
        echo -e "${GREEN}✅ No $description found${NC}"
    fi
    echo ""
}

# Get list of staged Dart files
staged_dart_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.dart$')

if [ -z "$staged_dart_files" ]; then
    echo "No Dart files to check"
    exit 0
fi

echo "Checking files:"
echo "$staged_dart_files" | sed 's/^/  - /'
echo ""

# Security pattern checks
check_pattern "password.*=.*['\"][^'\"]*['\"]" "hardcoded passwords" "$staged_dart_files"
check_pattern "apiKey.*=.*['\"]AIzaSy[^'\"]*['\"]" "Google API keys" "$staged_dart_files"
check_pattern "api_?key.*=.*['\"][^'\"]{20,}['\"]" "API keys" "$staged_dart_files"
check_pattern "secret.*=.*['\"][^'\"]*['\"]" "hardcoded secrets" "$staged_dart_files"
check_pattern "token.*=.*['\"][^'\"]*['\"]" "hardcoded tokens" "$staged_dart_files"
check_pattern "credential.*=.*['\"][^'\"]*['\"]" "hardcoded credentials" "$staged_dart_files"

# Check for demo credentials pattern
check_pattern "_demoCredentials.*=.*{" "demo credentials maps" "$staged_dart_files"
check_pattern "demo.*password.*:" "demo password assignments" "$staged_dart_files"

# Check for Firebase hardcoded values
check_pattern "static const FirebaseOptions.*=" "hardcoded Firebase configuration" "$staged_dart_files"
check_pattern "AIzaSy[a-zA-Z0-9_-]{35}" "Firebase API keys" "$staged_dart_files"

# Check for common secret keywords that shouldn't be in code
check_pattern "private_key.*=" "private keys" "$staged_dart_files"
check_pattern "oauth.*secret" "OAuth secrets" "$staged_dart_files"
check_pattern "database.*password" "database passwords" "$staged_dart_files"

# Additional security checks
echo "🔍 Running additional security checks..."

# Check for TODO comments about security
if echo "$staged_dart_files" | xargs grep -i "TODO.*security\|FIXME.*security" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Security-related TODO/FIXME comments found${NC}"
    echo -e "${YELLOW}   Consider addressing these before deployment${NC}"
    echo ""
fi

# Check for debug-only secrets (which should be removed in production)
if echo "$staged_dart_files" | xargs grep -i "debug.*key\|debug.*secret\|debug.*token" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Debug-only secrets found${NC}"
    echo -e "${YELLOW}   Ensure these are properly conditionally compiled${NC}"
    echo ""
fi

# Check for environment variable misuse
if echo "$staged_dart_files" | xargs grep -E "const.*String\.fromEnvironment.*=.*['\"][^'\"]+['\"]" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Default values for environment variables found${NC}"
    echo -e "${YELLOW}   Ensure defaults are safe for production${NC}"
    echo ""
fi

# Success message
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}🎉 All security checks passed!${NC}"
    echo -e "${GREEN}   No hardcoded secrets detected${NC}"
else
    echo ""
    echo -e "${RED}🚨 COMMIT BLOCKED: Security violations detected${NC}"
    echo -e "${RED}   Please fix the issues above before committing${NC}"
    echo ""
    echo -e "${YELLOW}💡 Security Best Practices:${NC}"
    echo -e "${YELLOW}   1. Use environment variables for all secrets${NC}"
    echo -e "${YELLOW}   2. Use EnvironmentConfig class for configuration${NC}"
    echo -e "${YELLOW}   3. Test with --dart-define for different environments${NC}"
    echo -e "${YELLOW}   4. Never commit real API keys or passwords${NC}"
    echo ""
    echo -e "${YELLOW}📚 See SECURITY_DEPLOYMENT_GUIDE.md for details${NC}"
fi

exit $exit_code