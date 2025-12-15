import sqlite3
import shutil
import os

# Konfigurasi File
DB_FILE = 'rambuid.db'
BACKUP_FILE = 'rambuid.db.backup'

def fix_database_ids():
    # 1. Cek apakah database ada
    if not os.path.exists(DB_FILE):
        print(f"❌ File {DB_FILE} tidak ditemukan!")
        return

    # 2. Buat Backup dulu (PENTING!)
    print(f"📦 Membuat backup ke {BACKUP_FILE}...")
    shutil.copy(DB_FILE, BACKUP_FILE)
    print("✅ Backup selesai.")

    # 3. Koneksi ke Database
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    try:
        # --- LANGKAH 1: AMBIL DATA LAMA ---
        print("🔍 Membaca data lama...")
        
        # Ambil data Rambu (Urutkan berdasarkan ID lama agar urutan tetap sama)
        cursor.execute("SELECT id, nama, gambar_url, deskripsi, kategori FROM rambu ORDER BY id ASC")
        old_rambu_data = cursor.fetchall()
        
        # Ambil data Jelajahi
        cursor.execute("SELECT id, rambu_id, latitude, longitude FROM jelajahi ORDER BY id ASC")
        old_jelajahi_data = cursor.fetchall()

        if not old_rambu_data:
            print("⚠️ Data rambu kosong. Tidak ada yang perlu diperbaiki.")
            conn.close()
            return

        # --- LANGKAH 2: BUAT MAPPING ID BARU ---
        # Kita akan memetakan ID LAMA -> ID BARU (1, 2, 3, ...)
        rambu_mapping = {} # Key: Old_ID, Value: New_ID
        new_rambu_list = []

        print("🔄 Menyusun ulang ID Rambu...")
        for index, row in enumerate(old_rambu_data):
            old_id = row[0]
            new_id = index + 1 # ID baru dimulai dari 1
            
            rambu_mapping[old_id] = new_id
            
            # Simpan data dengan ID baru
            # Format: (new_id, nama, gambar, deskripsi, kategori)
            new_rambu_list.append((new_id, row[1], row[2], row[3], row[4]))

        # --- LANGKAH 3: UPDATE DATA JELAJAHI DENGAN ID BARU ---
        new_jelajahi_list = []
        print("🔄 Menyusun ulang ID Jelajahi & Foreign Key...")
        
        for index, row in enumerate(old_jelajahi_data):
            old_jelajahi_id = row[0]
            old_rambu_ref = row[1]
            lat = row[2]
            lng = row[3]
            
            new_jelajahi_id = index + 1 # ID Jelajahi juga kita urutkan dari 1
            
            # Cari ID Rambu yang baru berdasarkan mapping
            if old_rambu_ref in rambu_mapping:
                new_rambu_ref = rambu_mapping[old_rambu_ref]
                new_jelajahi_list.append((new_jelajahi_id, new_rambu_ref, lat, lng))
            else:
                print(f"⚠️ Peringatan: Data Jelajahi ID {old_jelajahi_id} merujuk ke Rambu ID {old_rambu_ref} yang tidak ditemukan. Data ini akan dihapus.")

        # --- LANGKAH 4: EKSEKUSI DI DATABASE (HAPUS & ISI ULANG) ---
        print("⚡ Menulis ulang database...")
        
        # Matikan Foreign Key Check sementara biar tidak error saat hapus
        cursor.execute("PRAGMA foreign_keys = OFF;")
        
        # Kosongkan tabel
        cursor.execute("DELETE FROM jelajahi")
        cursor.execute("DELETE FROM rambu")
        
        # --- PERBAIKAN DI SINI: Try-Except untuk sqlite_sequence ---
        try:
            cursor.execute("DELETE FROM sqlite_sequence WHERE name='rambu'")
            cursor.execute("DELETE FROM sqlite_sequence WHERE name='jelajahi'")
        except sqlite3.OperationalError:
            # Error ini terjadi jika tabel sqlite_sequence belum ada (karena belum pakai autoincrement)
            # Kita abaikan saja karena tidak berbahaya.
            print("ℹ️ Info: Tabel sequence tidak ditemukan (Aman, dilewati).")
        # -----------------------------------------------------------

        # Masukkan Data Rambu Baru
        cursor.executemany("INSERT INTO rambu (id, nama, gambar_url, deskripsi, kategori) VALUES (?, ?, ?, ?, ?)", new_rambu_list)
        
        # Masukkan Data Jelajahi Baru
        cursor.executemany("INSERT INTO jelajahi (id, rambu_id, latitude, longitude) VALUES (?, ?, ?, ?)", new_jelajahi_list)

        # Nyalakan Foreign Key Check lagi
        cursor.execute("PRAGMA foreign_keys = ON;")
        
        conn.commit()
        print(f"✅ Selesai! Berhasil merapikan {len(new_rambu_list)} Rambu dan {len(new_jelajahi_list)} Titik Lokasi.")
        print("🚀 ID sekarang berurutan dari 1, 2, 3, dst.")

    except Exception as e:
        print(f"❌ Terjadi Error: {e}")
        conn.rollback()
        print("gagal melakukan perubahan. Database dikembalikan ke kondisi backup.")
        shutil.copy(BACKUP_FILE, DB_FILE) # Restore backup jika gagal

    finally:
        conn.close()

if __name__ == "__main__":
    fix_database_ids()