# 🔐 Google Meet OAuth2 Setup Guide

## Overview
Sistem ini menggunakan **OAuth2** untuk membuat Google Meet link dari **Gmail B** (yang punya Google One unlimited), lalu event-nya masuk ke kalender **Gmail A** (TalkWith).

## 🎯 Tujuan
- **Gmail B**: Bikin Google Meet (karena punya Google One unlimited)
- **Gmail A**: Kalender TalkWith tempat event disimpan
- **User**: Terima email dengan Google Meet link yang real

---

## 📋 Setup Steps

### 1️⃣ Google Cloud Console Setup

1. **Buka Google Cloud Console**
   ```
   https://console.cloud.google.com/
   ```

2. **Pilih Project** (atau buat baru)
   - Project ID: `talkwith-473623` (atau sesuaikan)

3. **Enable Google Calendar API**
   - Navigation menu → APIs & Services → Library
   - Search "Google Calendar API"
   - Click Enable

4. **Create OAuth 2.0 Credentials**
   - APIs & Services → Credentials
   - Click "Create Credentials" → OAuth client ID
   - **Application type**: Desktop app
   - **Name**: TalkWith Gmail B OAuth
   - Click "Create"

5. **Download Credentials**
   - Click download icon (⬇️) pada OAuth client yang baru dibuat
   - Save file JSON

### 2️⃣ Rails App Setup

1. **Copy credentials file**
   ```bash
   cp ~/Downloads/client_secret_*.json config/google_oauth_credentials.json
   ```

2. **Share Kalender Gmail A ke Gmail B**
   - Buka Google Calendar
   - Pilih kalender TalkWith (Gmail A)
   - Settings → Share with specific people
   - Add Gmail B email
   - Permission: **"Make changes to events"**
   - Save

3. **Restart Rails Server**
   ```bash
   touch tmp/restart.txt
   # atau restart bin/dev
   ```

### 3️⃣ Authorize Gmail B

1. **Akses OAuth Setup Page**
   ```
   http://localhost:3000/manages/oauth/setup
   ```

2. **Copy Authorization URL**
   - Klik "Copy" atau "Open"

3. **Login dengan Gmail B**
   - **PENTING**: Login dengan Gmail B (yang punya Google One)
   - BUKAN Gmail A

4. **Grant Permissions**
   - Allow access to Google Calendar
   - Allow creating events

5. **Copy Authorization Code**
   - Google akan tampilkan code
   - Copy code tersebut

6. **Paste & Submit**
   - Kembali ke OAuth Setup page
   - Paste code di form
   - Click "Complete Authorization"

7. **Verify Success**
   - Page akan reload
   - Status berubah jadi "✅ Active"

---

## ✅ Testing

### Test UDI Booking
```bash
bin/rails runner "
booking = Booking.create!(
  name: 'Test User',
  email: 'test@example.com',
  subject: '[UDIxITB] Test Meeting',
  description: 'Test OAuth Google Meet',
  start_time: 2.days.from_now.change(hour: 10, min: 0),
  end_time: 2.days.from_now.change(hour: 10, min: 30),
  date: 2.days.from_now.strftime('%m/%d/%Y'),
  timezone_offset: 'Asia/Jakarta',
  is_approved: true
)

SyncGoogleCalendarJob.perform_now(booking)
booking.reload

puts '📧 Email: ' + booking.email
puts '🔗 Meet Link: ' + booking.meeting_link.to_s
puts '📅 Event ID: ' + booking.google_calendar_event_id.to_s
"
```

### Expected Result
```
✅ Meet Link: https://meet.google.com/abc-defg-hij
✅ Event in Gmail A calendar
✅ Meet created by Gmail B
```

---

## 🔧 Troubleshooting

### "OAuth2 credentials not found"
- Pastikan file `config/google_oauth_credentials.json` ada
- Restart Rails server

### "No authorization found"
- Jalankan OAuth setup di `/manages/oauth/setup`
- Login dengan **Gmail B** (bukan Gmail A)

### "Invalid conference type"
- Pastikan menggunakan OAuth2 (bukan Service Account)
- Cek log: harus ada "Using OAuth2 for UDI booking"

### "Calendar not found"
- Pastikan kalender Gmail A sudah di-share ke Gmail B
- Permission: "Make changes to events"

### Token Expired
- Token akan auto-refresh
- Jika gagal, reset di OAuth Setup page

---

## 📁 Files Created

```
config/google_oauth_credentials.json  # OAuth2 credentials (dari Google Cloud)
config/google_oauth_token.yaml        # Refresh token (auto-generated)
```

**⚠️ JANGAN commit file-file ini ke Git!** (sudah ada di `.gitignore`)

---

## 🔄 How It Works

```
User books UDI slot
    ↓
System creates booking (approved)
    ↓
SyncGoogleCalendarJob detects OAuth is authorized
    ↓
Uses GoogleOauthService (Gmail B credentials)
    ↓
Creates event in Gmail A calendar WITH Google Meet
    ↓
Google Meet link extracted & saved
    ↓
Email sent to user with Meet link
    ↓
✅ Done!
```

---

## 🎉 Success Indicators

- ✅ OAuth Setup page shows "Integration Active"
- ✅ UDI bookings get real Google Meet links
- ✅ Meet links start with `https://meet.google.com/`
- ✅ Links work when opened
- ✅ Events appear in Gmail A calendar
- ✅ Gmail B is listed as organizer/creator

---

## 🔐 Security Notes

- OAuth token stored locally di `config/google_oauth_token.yaml`
- Token auto-refresh setiap 1 jam
- Hanya Gmail B yang bisa create Meet links
- Service Account masih dipakai untuk non-UDI bookings

---

## 📞 Support

Jika ada masalah:
1. Check logs: `tail -f log/development.log`
2. Reset OAuth: OAuth Setup page → Reset button
3. Re-authorize Gmail B
