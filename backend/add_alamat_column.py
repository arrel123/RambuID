"""
Script untuk menambahkan kolom alamat ke tabel users yang sudah ada.
Jalankan script ini sekali untuk update database schema.
"""
import sqlite3
import os

# Path ke database
DB_PATH = os.path.join(os.path.dirname(__file__), "rambuid.db")

def add_alamat_column():
    """Menambahkan kolom alamat ke tabel users jika belum ada"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Cek apakah kolom alamat sudah ada
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'alamat' not in columns:
            print("Menambahkan kolom 'alamat' ke tabel users...")
            cursor.execute("ALTER TABLE users ADD COLUMN alamat TEXT")
            conn.commit()
            print("✅ Kolom 'alamat' berhasil ditambahkan!")
        else:
            print("ℹ️  Kolom 'alamat' sudah ada di tabel users.")
        
        conn.close()
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    add_alamat_column()


