#!/usr/bin/env bash
#
# Documentation Validation Script
#
# This script validates the documentation setup and checks for common issues.
# It verifies that all documentation files exist, are properly formatted, and
# contain the expected content structure.
#
# Usage:
#   ./scripts/validate_docs.sh
#
# Exit codes:
#   0: All documentation checks passed
#   1: One or more documentation issues found
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

echo "🔍 Validating Hyperliquid Node Docker Documentation..."
echo

# Function to print test results
print_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "✅ ${GREEN}PASS${NC}: $test_name"
        ((PASSED++)) || true
    else
        echo -e "❌ ${RED}FAIL${NC}: $test_name - $message"
        ((FAILED++)) || true
    fi
}

# Function to check file exists
check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        print_result "$description" "PASS" ""
    else
        print_result "$description" "FAIL" "File not found: $file"
    fi
}

# Function to check file contains pattern
check_file_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        print_result "$description" "PASS" ""
    else
        print_result "$description" "FAIL" "Pattern '$pattern' not found in $file"
    fi
}

# Function to check file word count
check_file_min_words() {
    local file="$1"
    local min_words="$2"
    local description="$3"
    
    if [ -f "$file" ]; then
        local word_count=$(wc -w < "$file")
        if [ "$word_count" -ge "$min_words" ]; then
            print_result "$description" "PASS" ""
        else
            print_result "$description" "FAIL" "Only $word_count words (minimum $min_words required)"
        fi
    else
        print_result "$description" "FAIL" "File not found: $file"
    fi
}

echo "📁 Core Documentation Files"
echo "----------------------------"

# Check core documentation files exist
check_file_exists "README.md" "Main README exists"
check_file_exists "CONTRIBUTING.md" "Contributing guide exists"
check_file_exists "SECURITY.md" "Security policy exists"
check_file_exists "docs/README.md" "Docs index exists"
check_file_exists "docs/DOCKER_CONFIGURATION.md" "Docker configuration guide exists"

echo
echo "📋 README.md Content Validation"
echo "--------------------------------"

# Check README.md structure
check_file_contains "README.md" "## 🚀 Features" "Features section exists"
check_file_contains "README.md" "## 📋 Table of Contents" "Table of contents exists"
check_file_contains "README.md" "## Quick Setup" "Quick setup section exists"
check_file_contains "README.md" "## Configuration" "Configuration section exists"
check_file_contains "README.md" "## Node Operations" "Node operations section exists"
check_file_contains "README.md" "## Tools and Utilities" "Tools section exists"
check_file_contains "README.md" "## Security" "Security section exists"
check_file_contains "README.md" "## Troubleshooting" "Troubleshooting section exists"
check_file_contains "README.md" "## FAQ" "FAQ section exists"
check_file_contains "README.md" "## Advanced Configuration" "Advanced configuration section exists"

echo
echo "🤝 CONTRIBUTING.md Content Validation"
echo "--------------------------------------"

# Check CONTRIBUTING.md structure
check_file_contains "CONTRIBUTING.md" "## 🚀 Quick Start for Contributors" "Contributor quick start exists"
check_file_contains "CONTRIBUTING.md" "## 📝 Contribution Guidelines" "Contribution guidelines exist"
check_file_contains "CONTRIBUTING.md" "## 🧪 Testing" "Testing section exists"
check_file_contains "CONTRIBUTING.md" "## 🎯 Types of Contributions" "Contribution types exist"
check_file_contains "CONTRIBUTING.md" "## 📋 Pull Request Checklist" "PR checklist exists"

echo
echo "🔒 SECURITY.md Content Validation"
echo "----------------------------------"

# Check SECURITY.md structure
check_file_contains "SECURITY.md" "## 🚨 Reporting Security Vulnerabilities" "Vulnerability reporting exists"
check_file_contains "SECURITY.md" "## 🛡️ Security Best Practices" "Security best practices exist"
check_file_contains "SECURITY.md" "## 🔐 Operational Security" "Operational security exists"
check_file_contains "SECURITY.md" "## 📋 Security Checklist" "Security checklist exists"

echo
echo "🐳 Docker Configuration Documentation"
echo "-------------------------------------"

# Check Docker documentation
check_file_contains "docs/DOCKER_CONFIGURATION.md" "## 📋 Overview" "Docker config overview exists"
check_file_contains "docs/DOCKER_CONFIGURATION.md" "## 🔧 Configuration Files" "Configuration files section exists"
check_file_contains "docs/DOCKER_CONFIGURATION.md" "## 🚀 Usage Patterns" "Usage patterns exist"
check_file_contains "docs/DOCKER_CONFIGURATION.md" "## 🔧 Customization" "Customization section exists"

echo
echo "📊 Documentation Quality Checks"
echo "--------------------------------"

# Check minimum content length (ensures meaningful documentation)
check_file_min_words "README.md" 3000 "README.md has sufficient content"
check_file_min_words "CONTRIBUTING.md" 800 "CONTRIBUTING.md has sufficient content"
check_file_min_words "SECURITY.md" 1000 "SECURITY.md has sufficient content"
check_file_min_words "docs/DOCKER_CONFIGURATION.md" 800 "Docker config guide has sufficient content"

echo
echo "🔗 Link and Reference Validation"
echo "---------------------------------"

# Check for basic link patterns (simplified check)
if [ -f "README.md" ]; then
    if grep -q "\[.*\](.*.md)" README.md; then
        print_result "README.md contains internal links" "PASS" ""
    else
        print_result "README.md contains internal links" "FAIL" "No internal markdown links found"
    fi
fi

# Check for table of contents links
if [ -f "README.md" ]; then
    if grep -q "\[.*\](#.*)" README.md; then
        print_result "README.md has TOC anchor links" "PASS" ""
    else
        print_result "README.md has TOC anchor links" "FAIL" "No TOC anchor links found"
    fi
fi

echo
echo "📝 Script Documentation"
echo "------------------------"

# Check script headers
check_file_contains "scripts/check_sync.sh" "# This script compares" "Sync checker has description"
check_file_contains "scripts/wallet_transfer.py" "A comprehensive script for transferring" "Wallet transfer has description"

# Check script documentation completeness
if [ -f "scripts/check_sync.sh" ]; then
    if grep -q "Usage:" scripts/check_sync.sh && grep -q "Requirements:" scripts/check_sync.sh; then
        print_result "Sync checker has usage documentation" "PASS" ""
    else
        print_result "Sync checker has usage documentation" "FAIL" "Missing usage or requirements"
    fi
fi

echo
echo "📈 Documentation Statistics"
echo "---------------------------"

if [ -f "README.md" ]; then
    readme_lines=$(wc -l < README.md)
    readme_words=$(wc -w < README.md)
    echo "📄 README.md: $readme_lines lines, $readme_words words"
fi

if [ -f "CONTRIBUTING.md" ]; then
    contrib_lines=$(wc -l < CONTRIBUTING.md)
    contrib_words=$(wc -w < CONTRIBUTING.md)
    echo "🤝 CONTRIBUTING.md: $contrib_lines lines, $contrib_words words"
fi

if [ -f "SECURITY.md" ]; then
    security_lines=$(wc -l < SECURITY.md)
    security_words=$(wc -w < SECURITY.md)
    echo "🔒 SECURITY.md: $security_lines lines, $security_words words"
fi

# Count total documentation
total_md_files=$(find . -name "*.md" | wc -l)
total_docs_words=$(find . -name "*.md" -exec wc -w {} + | tail -1 | awk '{print $1}')
echo "📚 Total: $total_md_files markdown files, $total_docs_words words"

echo
echo "🎯 Validation Summary"
echo "====================="
echo -e "✅ ${GREEN}Passed${NC}: $PASSED tests"
echo -e "❌ ${RED}Failed${NC}: $FAILED tests"

if [ $FAILED -eq 0 ]; then
    echo -e "\n🎉 ${GREEN}All documentation validation tests passed!${NC}"
    echo "Documentation appears to be comprehensive and well-structured."
    exit 0
else
    echo -e "\n⚠️  ${YELLOW}Some documentation issues were found.${NC}"
    echo "Please review the failed tests above and update the documentation accordingly."
    exit 1
fi