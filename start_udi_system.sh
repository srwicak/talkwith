#!/bin/bash

# 🎯 UDI x ITB Quick Setup & Test Guide
echo "🎯 Setting up UDI x ITB Time Slot System..."

# Check if Rails is available
if command -v rails &> /dev/null; then
    echo "✅ Rails detected"
    RAILS_CMD="rails"
elif command -v bundle &> /dev/null; then
    echo "✅ Bundle detected, using bundle exec"
    RAILS_CMD="bundle exec rails"
else
    echo "❌ Rails not found. Please install Rails first."
    exit 1
fi

# Start Rails server
echo "🚀 Starting Rails server..."
echo "📱 UDI Booking URL: http://localhost:3000/udi-booking"
echo "⚙️  Admin Settings URL: http://localhost:3000/manages/udi_settings"
echo "📊 Regular Dashboard: http://localhost:3000/manage"
echo ""
echo "🧪 Test Scenarios:"
echo "1. Try booking with [UDIxITB] in regular form - should be blocked"
echo "2. Use /udi-booking to select time slots"
echo "3. Use admin panel to enable/disable slots"
echo "4. Check email notifications for UDI sessions"
echo ""
echo "Press Ctrl+C to stop server"
echo "============================================"

$RAILS_CMD server