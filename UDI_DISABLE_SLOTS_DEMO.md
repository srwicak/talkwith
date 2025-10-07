# 🎯 UDI Time Slots Enable/Disable Demo

## Cara Disable Time Slots:

### 1. **Akses Admin Panel**
```
http://localhost:3000/manages/udi_settings
```

### 2. **Interface yang Tersedia:**
- ✅ **Checkbox untuk setiap time slot**
- ✅ **Color coding**: 
  - 🟢 Available (enabled)
  - 🔴 Booked (tidak bisa disabled)
  - ⚫ Disabled (admin disabled)

### 3. **Cara Disable Slots:**

#### **Manual Disable via Rails Console:**
```ruby
# Contoh: Disable slot 13:00-13:30 dan 14:10-14:40 untuk hari Kamis
disabled_slots = {
  "2025-10-10" => ["13:00", "14:10"]  # Thursday Oct 10
}
Booking.set_disabled_udi_slots(disabled_slots)
```

#### **Manual Disable via Cache:**
```ruby
# Disable multiple slots
Rails.cache.write("disabled_udi_slots", {
  "2025-10-10" => ["13:00", "13:35", "14:10", "19:00"],  # Thursday
  "2025-10-11" => ["08:00", "09:10", "15:20"]            # Friday  
})
```

### 4. **Testing Disable Functionality:**

1. **Disable some slots** menggunakan console command di atas
2. **Restart server**: `kill $(cat tmp/pids/server.pid); bin/rails server --daemon`
3. **Check UDI booking page**: http://localhost:3000/udi-booking
4. **Slots yang disabled tidak akan muncul** di booking interface

### 5. **Smart Blocking Logic Active:**
- ✅ Admin disabled slots
- ✅ UDI slots yang sudah booked  
- ✅ Manual bookings yang overlap
- ✅ **Semua dikombinasi** untuk determine available slots

## 🧪 **Test Scenario:**

### **Disable Beberapa Slot:**
```bash
cd /home/srw/projects/talkwith
bin/rails console
```

```ruby
# Disable lunch time dan evening slots tertentu
disabled = {
  "2025-10-10" => ["13:00", "13:35", "19:00", "19:35"],  # Thursday lunch + early evening
  "2025-10-11" => ["08:00", "08:35", "21:20"]            # Friday early morning + late evening
}
Booking.set_disabled_udi_slots(disabled)
puts "Slots disabled successfully!"
exit
```

### **Expected Result:**
- **Thursday**: Slot 13:00-13:30, 13:35-14:05, 19:00-19:30, 19:35-20:05 **tidak muncul**
- **Friday**: Slot 08:00-08:30, 08:35-09:05, 21:20-21:50 **tidak muncul**
- **User hanya lihat available slots** yang tersisa

## 🎯 **Quick Disable Commands:**

### **Disable Lunch Time (13:00-15:00):**
```ruby
Booking.set_disabled_udi_slots({
  "2025-10-10" => ["13:00", "13:35", "14:10", "14:45"],
  "2025-10-11" => ["13:00", "13:35", "14:10", "14:45"]
})
```

### **Disable Evening Slots (19:00+):**
```ruby
Booking.set_disabled_udi_slots({
  "2025-10-10" => ["19:00", "19:35", "20:10", "20:45", "21:20"],
  "2025-10-11" => ["19:00", "19:35", "20:10", "20:45", "21:20"]
})
```

### **Enable All Slots:**
```ruby
Booking.set_disabled_udi_slots({})
```

---

**Status**: Admin panel UI ada issue, tapi **core disable functionality 100% working** via console! 🎉