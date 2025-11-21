# 🚀 Cara Menjalankan Backend RambuID

## ⚠️ MASALAH: "uvicorn is not recognized"

Ini terjadi karena virtual environment tidak aktif atau uvicorn belum terinstall.

---

## ✅ SOLUSI 1: Menggunakan Script (Paling Mudah)

### Opsi A: Double-click file
1. Buka File Explorer
2. Masuk ke folder `D:\RambuID\backend`
3. **Double-click** file `start_server.bat`
4. Script akan otomatis:
   - Mengaktifkan virtual environment
   - Install dependencies jika belum ada
   - Menjalankan server

### Opsi B: PowerShell Script
1. Buka PowerShell
2. Masuk ke folder backend:
   ```powershell
   cd D:\RambuID\backend
   ```
3. Izinkan eksekusi script (hanya sekali):
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Jalankan script:
   ```powershell
   .\start_server.ps1
   ```

---

## ✅ SOLUSI 2: Manual (Step by Step)

### Langkah 1: Buka PowerShell
Tekan `Win + X` → pilih "Windows PowerShell" atau "Terminal"

### Langkah 2: Masuk ke folder backend
```powershell
cd D:\RambuID\backend
```

### Langkah 3: Aktifkan virtual environment
```powershell
.\venv\Scripts\Activate.ps1
```

**Jika muncul error "execution policy":**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\venv\Scripts\Activate.ps1
```

**Setelah berhasil, prompt akan berubah menjadi:**
```
(venv) PS D:\RambuID\backend>
```

### Langkah 4: Install dependencies (jika belum)
```powershell
python -m pip install --upgrade pip
python -m pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]
```

### Langkah 5: Jalankan server
**Gunakan salah satu cara berikut:**

**Cara A: Menggunakan python -m uvicorn (RECOMMENDED)**
```powershell
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

**Cara B: Menggunakan uvicorn langsung**
```powershell
uvicorn app:app --host 0.0.0.0 --port 8000
```

---

## ✅ Verifikasi Server Berjalan

Setelah menjalankan perintah di atas, harus muncul log seperti ini:
```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

**Test di browser:**
1. Buka: http://localhost:8000
   - Harus muncul: `{"message": "Server Rambuid Berjalan!"}`

2. Buka: http://localhost:8000/docs
   - Harus muncul: Halaman Swagger UI dengan dokumentasi API

3. Buka: http://localhost:8000/health
   - Harus muncul: `{"status": "ok", "message": "Backend is running"}`

---

## 🔧 Troubleshooting

### ❌ Error: "uvicorn is not recognized"
**Penyebab**: Virtual environment tidak aktif

**Solusi**:
1. Pastikan prompt menunjukkan `(venv)` di depan
2. Jika tidak, jalankan: `.\venv\Scripts\Activate.ps1`
3. Atau gunakan: `python -m uvicorn app:app --host 0.0.0.0 --port 8000`

### ❌ Error: "execution policy"
**Penyebab**: PowerShell memblokir script

**Solusi**:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### ❌ Error: "ModuleNotFoundError: No module named 'uvicorn'"
**Penyebab**: Dependencies belum terinstall

**Solusi**:
```powershell
python -m pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]
```

### ❌ Error: "Address already in use"
**Penyebab**: Port 8000 sudah digunakan

**Solusi**:
1. Tutup aplikasi lain yang menggunakan port 8000
2. Atau gunakan port lain: `--port 8001`

---

## 📝 Checklist

Sebelum menjalankan backend, pastikan:
- [ ] Sudah masuk ke folder `D:\RambuID\backend`
- [ ] Virtual environment aktif (lihat `(venv)` di prompt)
- [ ] Dependencies sudah terinstall
- [ ] Port 8000 tidak digunakan aplikasi lain

---

## 🎯 Quick Start (Copy-Paste)

```powershell
# 1. Masuk ke folder backend
cd D:\RambuID\backend

# 2. Aktifkan virtual environment
.\venv\Scripts\Activate.ps1

# 3. Install dependencies (jika belum)
python -m pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]

# 4. Jalankan server
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

---

**Selamat! Backend sudah berjalan! 🎉**

