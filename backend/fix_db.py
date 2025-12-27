from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Koneksi ke Database Anda
DATABASE_URL = "sqlite:///./rambuid.db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def update_rambu():
    print("Mulai update database...")
    
    # List Perbaikan Data (HANYA YANG PENTING)
    updates = [
        # 1. PERBAIKAN TIKUNGAN GANDA (ZIGZAG)
        {
            "nama": "Tikungan Ganda Pertama Ke Kanan",
            "deskripsi": "Peringatan tikungan tajam ganda (zigzag), tikungan pertama mengarah ke kanan. Kurangi kecepatan.",
            "kategori": "Peringatan"
        },
        {
            "nama": "Tikungan Ganda Pertama Ke Kiri",
            "deskripsi": "Peringatan tikungan tajam ganda (zigzag), tikungan pertama mengarah ke kiri. Kurangi kecepatan.",
            "kategori": "Peringatan"
        },
        
        # 2. PERBAIKAN BANYAK TIKUNGAN (MELIUK)
        {
            "nama": "Banyak Tikungan Pertama Kanan",
            "deskripsi": "Peringatan jalan berkelok-kelok (meliuk) sepanjang beberapa kilometer, diawali ke kanan.",
            "kategori": "Peringatan"
        },
        {
            "nama": "Banyak Tikungan Pertama Kiri",
            "deskripsi": "Peringatan jalan berkelok-kelok (meliuk) sepanjang beberapa kilometer, diawali ke kiri.",
            "kategori": "Peringatan"
        },

        # 3. PERBAIKAN PERSIMPANGAN 4 (Agar User Tahu Bedanya)
        {
            "nama": "Persimpangan 4",
            "deskripsi": "Peringatan adanya persimpangan empat (perempatan) di depan. Waspada kendaraan dari kiri dan kanan.",
            "kategori": "Peringatan"
        }
    ]

    try:
        for item in updates:
            # SQL Update Query
            query = text("""
                UPDATE rambu 
                SET deskripsi = :desc, kategori = :kat 
                WHERE nama = :nm
            """)
            db.execute(query, {"desc": item["deskripsi"], "kat": item["kategori"], "nm": item["nama"]})
            print(f"✅ Berhasil update: {item['nama']}")
        
        db.commit()
        print("\nDATA PENTING BERHASIL DIPERBAIKI!")
        
    except Exception as e:
        print(f"Gagal update: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    update_rambu()