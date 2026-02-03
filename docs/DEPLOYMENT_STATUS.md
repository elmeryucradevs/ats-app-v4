# Testing - FCM Edge Function Deployment

## ✅ Status: Deployed Successfully

- **Project:** kholyiqxboourdwavkci
- **Function URL:** `https://kholyiqxboourdwavkci.supabase.co/functions/v1/send-notification`
- **Dashboard:** https://supabase.com/dashboard/project/kholyiqxboourdwavkci/functions

## 🔐 Configuration Status

### Firebase Secrets (Configured ✅)
- `FIREBASE_PROJECT_ID`: atesur-app-v4
- `FIREBASE_CLIENT_EMAIL`: firebase-adminsdk-fbsvc@atesur-app-v4.iam.gserviceaccount.com
- `FIREBASE_PRIVATE_KEY`: ✅ Set (not displayed for security)

## 🧪 Testing the Function

### Option 1: PowerShell Script (Recommended)

1. **Configure the script:**
   - Open `test_notification.ps1`
   - Update `$SUPABASE_ANON_KEY` with your key from Dashboard → Settings → API

2. **Run test:**
   ```powershell
   .\test_notification.ps1
   ```

3. **Custom notification:**
   ```powershell
   .\test_notification.ps1 -Title "Breaking News" -Body "Important update!" -Type "news"
   ```

### Option 2: From Flutter App

The app automatically calls this Edge Function when you:
1. Have FCM tokens in the `fcm_tokens` table
2. The NotificationService is initialized
3. You trigger a notification from the backend

### Option 3: Manual HTTP Request

```powershell
# Using Invoke-RestMethod
$headers = @{
    "Authorization" = "Bearer YOUR_ANON_KEY"
    "apikey" = "YOUR_ANON_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    title = "Test Notification"
    body = "This is a test"
    type = "general"
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "https://kholyiqxboourdwavkci.supabase.co/functions/v1/send-notification" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

## 📊 Expected Response

### Success
```json
{
  "success": true,
  "sentTo": 3,
  "total": 3,
  "failed": 0
}
```

### Common Errors

#### "No se encontraron tokens"
- **Cause:** No FCM tokens in database
- **Fix:** Launch the Flutter app to register a token first

#### "Firebase credentials no configuradas"
- **Cause:** Secrets not set or misspelled
- **Fix:** Verify secrets in Supabase Dashboard

#### "Invalid JWT"
- **Cause:** FIREBASE_PRIVATE_KEY incorrectly formatted
- **Fix:** Ensure `\n` characters are preserved in the private key

## 🔍 Monitoring

### View Logs
```powershell
npx supabase functions logs send-notification
```

### Check Function Status
https://supabase.com/dashboard/project/kholyiqxboourdwavkci/functions/send-notification

### Query Sent Notifications
```sql
SELECT title, body, type, sent_at 
FROM notifications 
ORDER BY sent_at DESC 
LIMIT 10;
```

## 🎯 Next Steps

1. ✅ Test the function with the PowerShell script
2. ⏳ Verify notifications are received on devices
3. ⏳ Integrate notification triggers in the Flutter app
4. ⏳ Set up automated notifications based on events
