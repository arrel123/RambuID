import sqlite3

# Tentukan nama file database Anda
db_file = 'rambuid.db'

try:
    # Membuat koneksi ke database
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()

    # Perintah SQL untuk menghapus semua data di tabel 'users' di mana id BUKAN 1
    # '!=' berarti 'tidak sama dengan'
    query = "DELETE FROM users WHERE id != 1"
    
    # Menjalankan perintah
    cursor.execute(query)
    
    # Menyimpan perubahan (penting agar data benar-benar terhapus)
    conn.commit()
    
    print(f"Berhasil. Jumlah akun yang dihapus: {cursor.rowcount}")
    print("Hanya akun dengan ID 1 yang tersisa.")

except sqlite3.Error as e:
    print(f"Terjadi kesalahan pada database: {e}")

finally:
    # Selalu tutup koneksi setelah selesai
    if conn:
        conn.close()