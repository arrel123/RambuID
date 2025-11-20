import uvicorn
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from passlib.context import CryptContext # Untuk keamanan password

# --- 1. KONFIGURASI DATABASE ---
DATABASE_URL = "sqlite:///./rambuid.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- 2. KONFIGURASI KEAMANAN (HASHING) ---
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# --- 3. DEFINISI TABEL (MODEL DATABASE) ---
# Tabel untuk Rambu
class Rambu(Base):
    __tablename__ = "rambu"
    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String, index=True)
    gambar_url = Column(String)
    deskripsi = Column(Text, nullable=True)

# Tabel untuk User (Login/Register)
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True) # Username gak boleh kembar
    password_hash = Column(String) # Kita simpan versi ter-enkripsi, bukan teks asli

# --- 4. SKEMA DATA (VALIDASI INPUT DARI FLUTTER) ---
class UserSchema(BaseModel):
    username: str
    password: str

# --- 5. SETUP APLIKASI ---
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine) # Buat file .db dan tabel baru

# Fungsi bantuan untuk mengambil koneksi DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 6. API ENDPOINTS ---

@app.get("/")
def read_root():
    return {"message": "Server Rambuid Berjalan!"}

# === FITUR REGISTER ===
@app.post("/register")
def register_user(user: UserSchema, db: Session = Depends(get_db)):
    # 1. Cek apakah username sudah dipakai?
    cek_user = db.query(User).filter(User.username == user.username).first()
    if cek_user:
        raise HTTPException(status_code=400, detail="Username sudah terdaftar!")
    
    # 2. Enkripsi password
    hashed_password = pwd_context.hash(user.password)
    
    # 3. Simpan ke Database
    new_user = User(username=user.username, password_hash=hashed_password)
    db.add(new_user)
    db.commit()
    
    return {"message": "Registrasi berhasil!", "username": user.username}

# === FITUR LOGIN ===
@app.post("/login")
def login_user(user: UserSchema, db: Session = Depends(get_db)):
    # 1. Cari user berdasarkan username
    db_user = db.query(User).filter(User.username == user.username).first()
    
    # 2. Jika user tidak ada ATAU password salah
    if not db_user or not pwd_context.verify(user.password, db_user.password_hash):
        raise HTTPException(status_code=400, detail="Username atau Password salah!")
    
    # 3. Jika berhasil
    return {"message": "Login sukses!", "user_id": db_user.id, "username": db_user.username}

# === FITUR DATA RAMBU ===
@app.get("/rambu/")
def get_all_rambu(db: Session = Depends(get_db)):
    return db.query(Rambu).all()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)