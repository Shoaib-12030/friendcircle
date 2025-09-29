#!/bin/bash

# Deploy Firestore Rules Script
# This script deploys the updated Firestore security rules to allow nickname validation

echo "🚀 Deploying Firestore Rules for Nickname Validation..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase:"
    firebase login
fi

# Deploy only Firestore rules
echo "📤 Deploying Firestore security rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully!"
    echo ""
    echo "📋 Changes made:"
    echo "   • Allowed nickname validation queries for unauthenticated users"
    echo "   • Added chat room and message permissions"
    echo "   • Updated friend request collection rules"
    echo ""
    echo "🎉 Your app should now be able to validate nicknames during registration!"
else
    echo "❌ Failed to deploy Firestore rules. Please check the error above."
    exit 1
fi