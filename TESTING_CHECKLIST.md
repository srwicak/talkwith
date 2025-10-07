# 🧪 UDI x ITB System Test Checklist

## Manual Testing Guide

### ✅ 1. **Regular Booking Form (Block UDI Input)**
- [ ] Go to: `http://localhost:3000`
- [ ] Try entering `[UDIxITB]` in subject field
- [ ] Should show error: "UDI x ITB bookings must use special booking link"
- [ ] Try entering `udi` or `itb` in subject
- [ ] Should also be blocked

### ✅ 2. **UDI Booking Interface**
- [ ] Go to: `http://localhost:3000/udi-booking`
- [ ] Should see Google Calendar-style interface
- [ ] Should show current week Thursday/Friday
- [ ] Should show session grouping (Morning/Afternoon/Evening)
- [ ] Should show available time slots

### ✅ 3. **Time Slot Selection**
- [ ] Click on any available time slot
- [ ] Should highlight with purple gradient
- [ ] Should show selected time in summary box
- [ ] Should enable submit button
- [ ] Form fields should work normally

### ✅ 4. **Admin Slot Management**
- [ ] Go to: `http://localhost:3000/manages/udi_settings`
- [ ] Should see current week slots with checkboxes
- [ ] Should show booking counts (0/1 for each slot)
- [ ] Should show color coding (🟢 Available, 🔴 Booked, ⚫ Disabled)
- [ ] Should show booking link copy functionality

### ✅ 5. **Slot Enable/Disable**
- [ ] Uncheck some slots in admin panel
- [ ] Click "Update Slot Settings"
- [ ] Go back to `/udi-booking`
- [ ] Disabled slots should not appear
- [ ] Re-enable slots in admin
- [ ] Should reappear in booking interface

### ✅ 6. **Booking Flow End-to-End**
- [ ] Select available slot in `/udi-booking`
- [ ] Fill all form fields (name, email, subject, description)
- [ ] Submit booking
- [ ] Should redirect to appointment page
- [ ] Should receive email confirmation
- [ ] Check admin panel - slot should show as booked

### ✅ 7. **Mobile Responsiveness**
- [ ] Test `/udi-booking` on mobile viewport
- [ ] Time slots should be touch-friendly
- [ ] Form should be responsive
- [ ] Admin panel should work on mobile

### ✅ 8. **Error Handling**
- [ ] Try booking same slot twice (should fail)
- [ ] Try accessing disabled slot directly
- [ ] Try booking past date
- [ ] Should show appropriate error messages

## Expected Time Slots

### Thursday (23 slots):
```
Morning (7):   08:00-08:30, 08:35-09:05, 09:10-09:40, 09:45-10:15, 10:20-10:50, 10:55-11:25, 11:30-12:00
Afternoon (8): 13:00-13:30, 13:35-14:05, 14:10-14:40, 14:45-15:15, 15:20-15:50, 15:55-16:25, 16:30-17:00, 17:05-17:35  
Evening (5):   19:00-19:30, 19:35-20:05, 20:10-20:40, 20:45-21:15, 21:20-21:50
```

### Friday (21 slots):
```
Morning (5):   08:00-08:30, 08:35-09:05, 09:10-09:40, 09:45-10:15, 10:20-10:50
Afternoon (8): 13:00-13:30, 13:35-14:05, 14:10-14:40, 14:45-15:15, 15:20-15:50, 15:55-16:25, 16:30-17:00, 17:05-17:35
Evening (5):   19:00-19:30, 19:35-20:05, 20:10-20:40, 20:45-21:15, 21:20-21:50
```

## 🐛 Common Issues & Solutions

### Issue: "Rails command not found"
**Solution**: Use `bundle exec rails server` instead

### Issue: Time slots not showing
**Solution**: Check if current date is Thursday/Friday of current week

### Issue: Slots appearing as disabled
**Solution**: Check admin panel `/manages/udi_settings` and enable them

### Issue: JavaScript not working
**Solution**: Check browser console for errors, ensure Stimulus is loaded

### Issue: Booking fails after slot selection
**Solution**: Check Rails logs for validation errors

## 📊 Success Criteria

- ✅ All 44 time slots display correctly
- ✅ Admin can control slot availability  
- ✅ Regular form blocks UDI input
- ✅ UDI booking form works end-to-end
- ✅ Mobile interface is usable
- ✅ Email notifications sent properly
- ✅ No JavaScript errors in console
- ✅ Server handles edge cases gracefully

---

**After completing all tests, the UDI x ITB Time Slot System is ready for production! 🎉**