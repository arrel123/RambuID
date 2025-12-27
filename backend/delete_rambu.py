from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Koneksi Database
DATABASE_URL = "sqlite:///./rambuid.db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def delete_bad_rambu():
    nama_target = "Tikungan Ganda Pertama Ke Kiri"  # Ganti dengan nama rambu yang ingin dihapus
    
    print(f"Mencoba menghapus: {nama_target}...")

    try:
        # 1. Cek dulu ID-nya berapa
        check_query = text("SELECT id FROM rambu WHERE nama = :nm")
        result = db.execute(check_query, {"nm": nama_target}).fetchone()
        
        if not result:
            print("❌ Data tidak ditemukan. Mungkin sudah dihapus sebelumnya.")
            return

        id_target = result[0]
        print(f"Deteksi ID Target: {id_target}")

        # 2. HAPUS RIWAYAT YANG TERKAIT DULU (Penting agar tidak error)
        # Hapus dari tabel jelajahi (jika ada fitur jelajah)
        db.execute(text("DELETE FROM jelajahi WHERE rambu_id = :rid"), {"rid": id_target})
        print("✅ Data terkait di tabel 'jelajahi' sudah diamankan.")

        # 3. HAPUS RAMBU DARI TABEL UTAMA
        db.execute(text("DELETE FROM rambu WHERE id = :rid"), {"rid": id_target})
        db.commit()
        
        print(f"✅ SUKSES! Rambu '{nama_target}' telah dihapus permanen dari database.")

    except Exception as e:
        print(f"❌ Gagal menghapus: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    delete_bad_rambu()