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
engine = create_engine(
    DATABASE_URL, 
    connect_args={
        "check_same_thread": False,
        "timeout": 20  # Timeout 20 detik untuk menunggu lock release
    },
    pool_pre_ping=True,  # Test koneksi sebelum digunakan
    pool_recycle=3600,   # Recycle connection setiap jam
)
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

class RegisterResponse(BaseModel):
    message: str
    username: str
    user_id: int

class LoginResponse(BaseModel):
    message: str
    username: str
    user_id: int

class UserResponse(BaseModel):
    id: int
    username: str
    
    class Config:
        from_attributes = True

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
        db.commit()  # Commit jika tidak ada exception
    except Exception:
        db.rollback()  # Rollback jika ada error
        raise
    finally:
        db.close()

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# --- 6. API ENDPOINTS ---

@app.get("/")
def read_root():
    return {"message": "Server Rambuid Berjalan!"}

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Backend is running"}

# === FITUR REGISTER ===
@app.post("/register", response_model=RegisterResponse, status_code=201)
def register_user(user: UserSchema, db: Session = Depends(get_db)) -> RegisterResponse:
    try:
        # 1. Cek apakah username sudah dipakai?
        cek_user = db.query(User).filter(User.username == user.username).first()
        if cek_user:
            raise HTTPException(status_code=400, detail="Username sudah terdaftar!")
        
        # 2. Enkripsi password
        hashed_password = hash_password(user.password)
        
        # 3. Simpan ke Database
        new_user = User(username=user.username, password_hash=hashed_password)
        db.add(new_user)
        db.flush()  # Flush untuk mendapatkan ID tanpa commit
        db.refresh(new_user)
        
        return RegisterResponse(
            message="Registrasi berhasil!",
            username=new_user.username,
            user_id=new_user.id,
        )
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error saat registrasi: {str(e)}")

# === FITUR LOGIN ===
@app.post("/login", response_model=LoginResponse)
def login_user(user: UserSchema, db: Session = Depends(get_db)) -> LoginResponse:
    # 1. Cari user berdasarkan username
    db_user = db.query(User).filter(User.username == user.username).first()
    
    # 2. Jika user tidak ada ATAU password salah
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=400, detail="Username atau Password salah!")
    
    # 3. Jika berhasil
    return LoginResponse(
        message="Login sukses!",
        user_id=db_user.id,
        username=db_user.username,
    )

# === FITUR DATA RAMBU ===
@app.get("/rambu/")
def get_all_rambu(db: Session = Depends(get_db)):
    return db.query(Rambu).all()

# === FITUR DATA PENGGUNA (ADMIN) ===
@app.get("/users/")
def get_all_users(db: Session = Depends(get_db)):
    """Endpoint untuk mendapatkan semua data pengguna (untuk admin)"""
    try:
        users = db.query(User).all()
        # Konversi ke format yang bisa di-serialize
        users_list = [
            {
                "id": user.id,
                "username": user.username
            }
            for user in users
        ]
        return users_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saat mengambil data pengguna: {str(e)}")

# === FITUR STATISTIK (ADMIN) ===
@app.get("/stats/")
def get_statistics(db: Session = Depends(get_db)):
    """Endpoint untuk mendapatkan statistik dashboard admin"""
    try:
        # Hitung total pengguna
        total_users = db.query(User).count()
        
        # Hitung total rambu
        total_rambu = db.query(Rambu).count()
        
        return {
            "total_users": total_users,
            "total_rambu": total_rambu
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saat mengambil statistik: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)