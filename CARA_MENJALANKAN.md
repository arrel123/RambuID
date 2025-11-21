# 🚀 Panduan Menjalankan RambuID - Login & Register

## 📋 Prerequisites
- Python 3.12+ terinstall
- Flutter SDK terinstall
- Backend dependencies sudah terinstall

---

## 🔧 LANGKAH 1: Menjalankan Backend

### Opsi A: Menggunakan Script (Paling Mudah)
1. Buka File Explorer
2. Masuk ke folder `D:\RambuID\backend`
3. **Double-click** file `start_server.bat`
4. Terminal akan terbuka dan server otomatis berjalan
5. Pastikan muncul log: `Uvicorn running on http://0.0.0.0:8000`

### Opsi B: Manual (PowerShell)
```powershell
# 1. Buka PowerShell
cd D:\RambuID\backend

# 2. Aktifkan virtual environment
.\venv\Scripts\Activate.ps1

# 3. Install dependencies (jika belum)
pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]

# 4. Jalankan server
uvicorn app:app --host 0.0.0.0 --port 8000
```

### ✅ Verifikasi Backend Berjalan
Buka browser dan akses:
- **http://localhost:8000** → Harus muncul `{"message": "Server Rambuid Berjalan!"}`
- **http://localhost:8000/docs** → Harus muncul halaman Swagger UI
- **http://localhost:8000/health** → Harus muncul `{"status": "ok", "message": "Backend is running"}`

---

## 📱 LANGKAH 2: Menjalankan Frontend

### Terminal Baru (Jangan tutup terminal backend!)
```powershell
# 1. Buka terminal baru
cd D:\RambuID\frontend

# 2. Jalankan Flutter
flutter run -d chrome
# atau untuk Android emulator:
# flutter run
```

### ✅ Verifikasi Frontend Berjalan
- Aplikasi akan terbuka di browser (Chrome) atau emulator
- Pastikan halaman login/register bisa dibuka

---

## 🧪 LANGKAH 3: Test Login & Register

### Test Register
1. Buka halaman **Register**
2. Isi form:
   - **NAMA**: (opsional, tidak dikirim ke backend)
   - **EMAIL**: `test@example.com` (ini akan jadi username)
   - **KATA SANDI**: minimal 8 karakter
   - **KONFIRMASI KATA SANDI**: sama dengan password
3. Klik **DAFTAR**
4. **Harus muncul**: Snackbar hijau "Registrasi berhasil!"
5. Akan otomatis redirect ke halaman login

### Test Login
1. Di halaman **Login**
2. Masukkan:
   - **EMAIL**: `test@example.com` (username yang tadi didaftarkan)
   - **PASSWORD**: password yang tadi digunakan
3. Klik **MASUK**
4. **Harus muncul**: Snackbar hijau "Login sukses!"
5. Akan redirect ke halaman beranda (`/home`)

---

## 🔍 Troubleshooting

### ❌ Error: "Koneksi ke server gagal"
**Penyebab**: Backend tidak berjalan atau tidak bisa diakses

**Solusi**:
1. ✅ Pastikan backend berjalan (lihat terminal backend)
2. ✅ Buka http://localhost:8000 di browser → harus muncul JSON response
3. ✅ Cek console browser (F12 → Console) untuk melihat log error detail
4. ✅ Pastikan tidak ada firewall yang memblokir port 8000

### ❌ Error: "Username sudah terdaftar!"
**Penyebab**: Email/username sudah ada di database

**Solusi**:
1. Gunakan email/username lain
2. Atau hapus data lama dari database `rambuid.db` menggunakan Browser for SQLite

### ❌ Error: "ModuleNotFoundError: No module named 'sqlalchemy'"
**Penyebab**: Dependencies belum terinstall

**Solusi**:
```powershell
cd D:\RambuID\backend
.\venv\Scripts\Activate.ps1
pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]
```

### ❌ Error: PowerShell Execution Policy
**Penyebab**: PowerShell memblokir script activation

**Solusi**:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

## 📊 Cek Data di Database

1. Buka **Browser for SQLite**
2. Buka file: `D:\RambuID\backend\rambuid.db`
3. Pilih tabel **users**
4. Lihat data user yang sudah terdaftar
5. Kolom yang ada:
   - `id`: ID unik user
   - `username`: Email/username yang digunakan
   - `password_hash`: Password yang sudah di-hash (tidak bisa dibaca)

---

## ✅ Checklist Sebelum Development

- [ ] Backend berjalan di http://localhost:8000
- [ ] Bisa akses http://localhost:8000/docs
- [ ] Frontend berjalan (browser/emulator)
- [ ] Test register berhasil
- [ ] Test login berhasil
- [ ] Data masuk ke database

---

## 🎯 Endpoint API yang Tersedia

- `GET /` - Health check sederhana
- `GET /health` - Health check dengan detail
- `POST /register` - Registrasi user baru
- `POST /login` - Login user
- `GET /rambu/` - Get semua data rambu

---

**Selamat! 🎉 Login dan Register sudah berfungsi dengan baik!**

