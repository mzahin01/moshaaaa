#!/bin/bash

# Flutter Firebase Web Deploy Script
# This script builds the Flutter web app and deploys it to Firebase Hosting

set -e  # Exit on error

echo "🚀 Starting Flutter Web deployment to Firebase..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build web app for production
echo "🏗️  Building Flutter web app..."
flutter build web --release --no-tree-shake-icons

# Set Firebase project (from firebase.json)
echo "🔧 Setting Firebase project..."
firebase use moshaaaaaa

# Deploy to Firebase
echo "☁️  Deploying to Firebase Hosting..."
firebase deploy --only hosting --project moshaaaaaa

echo "✅ Deployment complete!"
echo "🌐 Your app is now live on Firebase Hosting"
