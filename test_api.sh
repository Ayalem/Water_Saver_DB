#!/bin/bash
# ============================================================================
# WaterSaver Application - Comprehensive API Test Script
# ============================================================================
# This script tests all API endpoints and verifies functionality
# ============================================================================

BASE_URL="http://localhost:5000"
COOKIE_FILE="test_cookies.txt"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_code=$4
    local description=$5
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method -b $COOKIE_FILE "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method -H "Content-Type: application/json" -d "$data" -b $COOKIE_FILE -c $COOKIE_FILE "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_code" ]; then
        print_result 0 "$description (HTTP $http_code)"
        echo "  Response: $(echo $body | jq -c '.' 2>/dev/null || echo $body | head -c 100)"
    else
        print_result 1 "$description (Expected $expected_code, got $http_code)"
        echo "  Response: $(echo $body | jq -c '.' 2>/dev/null || echo $body | head -c 200)"
    fi
    
    # Store response for later use
    LAST_RESPONSE="$body"
}

echo "============================================================================"
echo "WaterSaver Application - Comprehensive API Tests"
echo "============================================================================"
echo ""

# Clean up old cookie file
rm -f $COOKIE_FILE

echo "--- AUTHENTICATION TESTS ---"
echo ""

# Test 1: Register new user
echo "Test 1: Register new user"
test_endpoint "POST" "/api/auth/register" \
    '{"email":"test_'$(date +%s)'@test.com","password":"test123","nom":"Test","prenom":"User","telephone":"0600000000","role":"AGRICULTEUR"}' \
    "201" \
    "Register new user"
echo ""

# Test 2: Login with existing user
echo "Test 2: Login"
test_endpoint "POST" "/api/auth/login" \
    '{"email":"ayalem@test.com","password":"test123"}' \
    "200" \
    "Login with existing user"
echo ""

# Test 3: Get current user
echo "Test 3: Get current user"
test_endpoint "GET" "/api/auth/me" \
    "" \
    "200" \
    "Get current user info"
echo ""

echo "--- CHAMPS MANAGEMENT TESTS ---"
echo ""

# Test 4: List all champs
echo "Test 4: List all champs"
test_endpoint "GET" "/api/champs" \
    "" \
    "200" \
    "List all champs"
echo ""

# Test 5: Create new champ
echo "Test 5: Create new champ"
test_endpoint "POST" "/api/champs" \
    '{"nom":"Test Champ","superficie":15.5,"type_champs":"AGRICOLE","type_sol":"ARGILEUX","systeme_irrigation":"GOUTTE_A_GOUTTE","region":"Casablanca","ville":"Casablanca"}' \
    "201" \
    "Create new champ"

# Extract champ_id from response
CHAMP_ID=$(echo $LAST_RESPONSE | jq -r '.champ_id' 2>/dev/null)
echo "  Created champ_id: $CHAMP_ID"
echo ""

# Test 6: Get specific champ
if [ ! -z "$CHAMP_ID" ] && [ "$CHAMP_ID" != "null" ]; then
    echo "Test 6: Get specific champ"
    test_endpoint "GET" "/api/champs/$CHAMP_ID" \
        "" \
        "200" \
        "Get champ by ID"
    echo ""
    
    # Test 7: Update champ
    echo "Test 7: Update champ"
    test_endpoint "PUT" "/api/champs/$CHAMP_ID" \
        '{"nom":"Updated Test Champ","superficie":20}' \
        "200" \
        "Update champ"
    echo ""
fi

echo "--- PARCELLES MANAGEMENT TESTS ---"
echo ""

# Test 8: List all parcelles
echo "Test 8: List all parcelles"
test_endpoint "GET" "/api/parcelles" \
    "" \
    "200" \
    "List all parcelles"
echo ""

# Test 9: Create new parcelle
if [ ! -z "$CHAMP_ID" ] && [ "$CHAMP_ID" != "null" ]; then
    echo "Test 9: Create new parcelle"
    test_endpoint "POST" "/api/parcelles" \
        '{"nom":"Test Parcelle","superficie":5,"champ_id":'$CHAMP_ID'}' \
        "201" \
        "Create new parcelle"
    
    PARCELLE_ID=$(echo $LAST_RESPONSE | jq -r '.parcelle_id' 2>/dev/null)
    echo "  Created parcelle_id: $PARCELLE_ID"
    echo ""
    
    # Test 10: Get specific parcelle
    if [ ! -z "$PARCELLE_ID" ] && [ "$PARCELLE_ID" != "null" ]; then
        echo "Test 10: Get specific parcelle"
        test_endpoint "GET" "/api/parcelles/$PARCELLE_ID" \
            "" \
            "200" \
            "Get parcelle by ID"
        echo ""
        
        # Test 11: Update parcelle
        echo "Test 11: Update parcelle"
        test_endpoint "PUT" "/api/parcelles/$PARCELLE_ID" \
            '{"nom":"Updated Test Parcelle","superficie":7}' \
            "200" \
            "Update parcelle"
        echo ""
    fi
fi

echo "--- ALERTES TESTS ---"
echo ""

# Test 12: List all alertes
echo "Test 12: List all alertes"
test_endpoint "GET" "/api/alertes" \
    "" \
    "200" \
    "List all alertes"
echo ""

# Test 13: List active alertes
echo "Test 13: List active alertes"
test_endpoint "GET" "/api/alertes?statut=ACTIVE" \
    "" \
    "200" \
    "List active alertes"
echo ""

echo "--- NOTIFICATIONS TESTS ---"
echo ""

# Test 14: List all notifications
echo "Test 14: List all notifications"
test_endpoint "GET" "/api/notifications" \
    "" \
    "200" \
    "List all notifications"
echo ""

# Test 15: Count unread notifications
echo "Test 15: Count unread notifications"
test_endpoint "GET" "/api/notifications/count-unread" \
    "" \
    "200" \
    "Count unread notifications"
echo ""

echo "--- CLEANUP & LOGOUT ---"
echo ""

# Test 16: Logout
echo "Test 16: Logout"
test_endpoint "POST" "/api/auth/logout" \
    "" \
    "200" \
    "Logout"
echo ""

# Clean up
rm -f $COOKIE_FILE

echo "============================================================================"
echo "TEST SUMMARY"
echo "============================================================================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
