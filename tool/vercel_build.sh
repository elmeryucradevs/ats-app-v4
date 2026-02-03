#!/bin/bash

echo "🚀 Starting Vercel Build for Flutter..."

# 1. Install Flutter
if [ -d "flutter" ]; then
  echo "Flutter directory already exists."
else
  echo "📥 Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Verify Install
echo "✅ Flutter version:"
flutter --version

# 3. Enable Web
flutter config --enable-web

# 4. Get Dependencies
echo "📦 Getting packages..."
flutter pub get

# 5. Pre-build Setup
echo "🔧 Creating dummy .env and assets for build..."

# Debug: Check where we are
pwd
ls -la

# Create dummy .env since pubspec.yaml includes it
touch .env
echo "Dummy .env created"

# Ensure asset directories exist AND have content to satisfy pubspec.yaml
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/data

touch assets/images/.keep
touch assets/icons/.keep
touch assets/data/.keep

echo "📂 Assets structure:"
ls -R assets

# 6. Build for Web
# We construct the --dart-define args from environment variables
# Ensure these variables are set in Vercel Project Settings

echo "🏗️  Building web application..."

flutter build web --release --verbose \
  --dart-define=STREAM_URL="$STREAM_URL" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=WORDPRESS_API_URL="$WORDPRESS_API_URL" \
  --dart-define=FACEBOOK_URL="$FACEBOOK_URL" \
  --dart-define=TWITTER_URL="$TWITTER_URL" \
  --dart-define=INSTAGRAM_URL="$INSTAGRAM_URL" \
  --dart-define=YOUTUBE_URL="$YOUTUBE_URL" \
  --dart-define=TIKTOK_URL="$TIKTOK_URL" \
  --dart-define=WHATSAPP_URL="$WHATSAPP_URL" \
  --dart-define=CONTACT_EMAIL="$CONTACT_EMAIL" \
  --dart-define=DEBUG_MODE="${DEBUG_MODE:-false}"

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
else
  echo "❌ Build failed!"
  exit 1
fi
