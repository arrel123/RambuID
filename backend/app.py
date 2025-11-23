import os
import shutil
import uuid
from typing import List, Optional

import uvicorn
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from passlib.context import CryptContext
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, Text, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker

# --- KONFIGURASI PATH UNTUK GAMBAR ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
IMAGES_DIR = os.path.join(STATIC_DIR, "images")
RAMBU_IMAGES_DIR = os.path.join(IMAGES_DIR, "rambu")
UPLOADS_DIR = os.path.join(IMAGES_DIR, "uploads")

# Buat folder jika belum ada
os.makedirs(STATIC_DIR, exist_ok=True)
os.makedirs(IMAGES_DIR, exist_ok=True)
os.makedirs(RAMBU_IMAGES_DIR, exist_ok=True)
os.makedirs(UPLOADS_DIR, exist_ok=True)

# --- KONFIGURASI DATABASE ---
DATABASE_URL = "sqlite:///./rambuid.db"
engine = create_engine(
    DATABASE_URL, 
    connect_args={
        "check_same_thread": False,
        "timeout": 20
    },
    pool_pre_ping=True,
    pool_recycle=3600,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- KONFIGURASI KEAMANAN ---
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# --- MODEL DATABASE ---
class Rambu(Base):
    __tablename__ = "rambu"
    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String, index=True)
    gambar_url = Column(String)
    deskripsi = Column(Text, nullable=True)
    kategori = Column(String, nullable=False)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password_hash = Column(String)
    alamat = Column(String, nullable=True)

# --- SCHEMA DATA ---
class RambuCreate(BaseModel):
    nama: str
    deskripsi: Optional[str] = None

class RambuResponse(BaseModel):
    id: int
    nama: str
    gambar_url: Optional[str]
    deskripsi: Optional[str]
    kategori: str
    
    class Config:
        from_attributes = True

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

# --- SETUP APLIKASI ---
app = FastAPI(title="RambuID API", version="1.0.0")

# Mount static files directory (gunakan path absolut agar aman)
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

# --- FUNGSI BANTU ---
def get_db():
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def save_uploaded_file(file: UploadFile, destination_dir: str) -> str:
    """Menyimpan file upload dan mengembalikan path relatif"""
    # Generate unique filename
    file_extension = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    
    # Destination path
    file_path = os.path.join(destination_dir, unique_filename)
    
    # Save file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Return relative path untuk URL (dengan leading slash)
    relative_path = f"/static/images/rambu/{unique_filename}"
    return relative_path

# --- API ENDPOINTS ---

@app.get("/")
def read_root():
    return {"message": "Server Rambuid Berjalan!"}

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Backend is running"}

# === AUTHENTICATION ===
@app.post("/register", response_model=RegisterResponse, status_code=201)
def register_user(user: UserSchema, db: Session = Depends(get_db)):
    try:
        cek_user = db.query(User).filter(User.username == user.username).first()
        if cek_user:
            raise HTTPException(status_code=400, detail="Username sudah terdaftar!")
        
        hashed_password = hash_password(user.password)
        new_user = User(username=user.username, password_hash=hashed_password)
        db.add(new_user)
        db.flush()
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

@app.post("/login", response_model=LoginResponse)
def login_user(user: UserSchema, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.username == user.username).first()
    
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=400, detail="Username atau Password salah!")
    
    return LoginResponse(
        message="Login sukses!",
        user_id=db_user.id,
        username=db_user.username,
    )

# === CRUD RAMBU DENGAN GAMBAR ===
@app.get("/rambu/", response_model=List[RambuResponse])
def get_all_rambu(db: Session = Depends(get_db)):
    """Mendapatkan semua data rambu"""
    rambu_list = db.query(Rambu).all()
    
    # Pastikan path dimulai dengan /static
    for rambu in rambu_list:
        if rambu.gambar_url and not rambu.gambar_url.startswith('http'):
            # Pastikan path dimulai dengan /
            if not rambu.gambar_url.startswith('/'):
                rambu.gambar_url = f"/{rambu.gambar_url}"
    
    return rambu_list

@app.post("/rambu/", response_model=RambuResponse, status_code=201)
def create_rambu(
    nama: str = Form(...),
    deskripsi: Optional[str] = Form(None),
    kategori: str = Form(...),
    gambar: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Membuat data rambu baru dengan gambar"""
    try:
        # Validasi kategori
        valid_kategori = ['larangan', 'peringatan', 'petunjuk', 'perintah']
        if kategori not in valid_kategori:
            raise HTTPException(
                status_code=400,
                detail=f"Kategori tidak valid. Pilih salah satu: {', '.join(valid_kategori)}"
            )
        
        # Validasi file type
        allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
        file_extension = os.path.splitext(gambar.filename)[1].lower()
        
        if file_extension not in allowed_extensions:
            raise HTTPException(
                status_code=400, 
                detail="Format file tidak didukung. Gunakan JPG, PNG, atau GIF"
            )
        
        # Save gambar
        gambar_path = save_uploaded_file(gambar, RAMBU_IMAGES_DIR)
        
        # Create rambu record
        new_rambu = Rambu(
            nama=nama,
            deskripsi=deskripsi,
            kategori=kategori,
            gambar_url=gambar_path
        )
        
        db.add(new_rambu)
        db.flush()
        db.refresh(new_rambu)
        
        # Pastikan path dimulai dengan /
        if new_rambu.gambar_url and not new_rambu.gambar_url.startswith('/'):
            new_rambu.gambar_url = f"/{new_rambu.gambar_url}"
        
        return new_rambu
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error membuat rambu: {str(e)}")

@app.put("/rambu/{rambu_id}", response_model=RambuResponse)
def update_rambu(
    rambu_id: int,
    nama: Optional[str] = Form(None),
    deskripsi: Optional[str] = Form(None),
    kategori: Optional[str] = Form(None),
    gambar: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """Update data rambu (dengan atau tanpa gambar baru)"""
    try:
        rambu = db.query(Rambu).filter(Rambu.id == rambu_id).first()
        if not rambu:
            raise HTTPException(status_code=404, detail="Rambu tidak ditemukan")
        
        # Update fields jika provided
        if nama is not None:
            rambu.nama = nama
        if deskripsi is not None:
            rambu.deskripsi = deskripsi
        if kategori is not None:
            # Validasi kategori
            valid_kategori = ['larangan', 'peringatan', 'petunjuk', 'perintah']
            if kategori not in valid_kategori:
                raise HTTPException(
                    status_code=400,
                    detail=f"Kategori tidak valid. Pilih salah satu: {', '.join(valid_kategori)}"
                )
            rambu.kategori = kategori
        
        # Handle gambar baru jika diupload
        if gambar:
            # Validasi file type
            allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
            file_extension = os.path.splitext(gambar.filename)[1].lower()
            
            if file_extension not in allowed_extensions:
                raise HTTPException(
                    status_code=400, 
                    detail="Format file tidak didukung"
                )
            
            # Hapus gambar lama jika ada
            if rambu.gambar_url:
                old_image_path = os.path.join(BASE_DIR, rambu.gambar_url)
                if os.path.exists(old_image_path):
                    os.remove(old_image_path)
            
            # Save gambar baru
            gambar_path = save_uploaded_file(gambar, RAMBU_IMAGES_DIR)
            rambu.gambar_url = gambar_path
        
        db.flush()
        db.refresh(rambu)
        
        # Pastikan path dimulai dengan /
        if rambu.gambar_url and not rambu.gambar_url.startswith('http'):
            if not rambu.gambar_url.startswith('/'):
                rambu.gambar_url = f"/{rambu.gambar_url}"
        
        return rambu
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error update rambu: {str(e)}")

@app.delete("/rambu/{rambu_id}")
def delete_rambu(rambu_id: int, db: Session = Depends(get_db)):
    """Hapus data rambu dan gambarnya"""
    try:
        rambu = db.query(Rambu).filter(Rambu.id == rambu_id).first()
        if not rambu:
            raise HTTPException(status_code=404, detail="Rambu tidak ditemukan")
        
        # Hapus file gambar jika ada
        if rambu.gambar_url:
            image_path = os.path.join(BASE_DIR, rambu.gambar_url)
            if os.path.exists(image_path):
                os.remove(image_path)
        
        # Hapus dari database
        db.delete(rambu)
        db.flush()
        
        return {"message": "Rambu berhasil dihapus"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error hapus rambu: {str(e)}")

# === ADMIN FEATURES ===
@app.get("/users/")
def get_all_users(db: Session = Depends(get_db)):
    try:
        users = db.query(User).all()
        users_list = [
            {
                "id": user.id,
                "username": user.username,
                "alamat": user.alamat if user.alamat else None
            }
            for user in users
        ]
        return users_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saat mengambil data pengguna: {str(e)}")

@app.get("/stats/")
def get_statistics(db: Session = Depends(get_db)):
    try:
        total_users = db.query(User).count()
        total_rambu = db.query(Rambu).count()
        
        return {
            "total_users": total_users,
            "total_rambu": total_rambu
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saat mengambil statistik: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)