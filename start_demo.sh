#!/bin/bash

# WaterSaver - Start Script for Demo
# This script ensures everything is running with proper encoding

echo "============================================"
echo "WaterSaver - Starting Demo Environment"
echo "============================================"

# Set Oracle encoding for French characters
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

# Kill any existing backend process
echo "Stopping existing backend..."
lsof -ti:5000 | xargs kill -9 2>/dev/null

# Start backend
echo "Starting backend with UTF-8 encoding..."
cd "$(dirname "$0")/backend"
python main.py &
BACKEND_PID=$!

# Wait for backend to start
echo "Waiting for backend to start..."
sleep 3

# Check if backend is running
if curl -s http://localhost:5000/api/health > /dev/null; then
    echo "✅ Backend running on http://localhost:5000"
else
    echo "❌ Backend failed to start"
    exit 1
fi

# Check if frontend is running
if curl -s http://localhost:8000 > /dev/null; then
    echo "✅ Frontend running on http://localhost:8000"
else
    echo "⚠️  Frontend not running. Start with:"
    echo "   cd frontend && python3 -m http.server 8000"
fi

echo ""
echo "============================================"
echo "Demo Environment Ready!"
echo "============================================"
echo ""
echo "Frontend: http://localhost:8000"
echo "Backend:  http://localhost:5000"
echo ""
echo "Test Accounts (password: test123):"
echo "  AGRICULTEUR: ayalem@test.com"
echo "  TECHNICIEN:  tech@test.com"
echo "  INSPECTEUR:  inspect@test.com"
echo "  ADMIN:       admin@test.com"
echo ""
echo "Press Ctrl+C to stop"
echo "============================================"

# Wait for Ctrl+C
wait $BACKEND_PID
