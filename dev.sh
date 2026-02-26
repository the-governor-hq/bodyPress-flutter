#!/bin/bash
# BodyPress Flutter Development Script
# Run this to start development with hot reload

DEVICE="${1:-emulator-5554}"

echo "🚀 Starting BodyPress Flutter Development..."
echo ""

# Check if device is connected
echo "📱 Checking device connection..."
if ! flutter devices 2>&1 | grep -q "$DEVICE"; then
    echo "❌ Device $DEVICE not found. Available devices:"
    flutter devices
    exit 1
fi

echo "✅ Device found: $DEVICE"
echo ""

# Start the app with hot reload
echo "🔥 Starting Flutter with hot reload enabled..."
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Hot Reload Commands:"
echo "  • Press 'r' to hot reload (fast)"
echo "  • Press 'R' to hot restart (full restart)"
echo "  • Press 'h' for help"
echo "  • Press 'q' to quit"
echo "═══════════════════════════════════════════════════════"
echo ""

# Run Flutter
flutter run -d "$DEVICE" --hot
