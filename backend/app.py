import pathlib
from pathlib import Path
# Fix untuk Windows Path jika diperlukan
pathlib.PosixPath = pathlib.WindowsPath

import os
import shutil
import uuid
import io 
from typing import List, Optional

import uvicorn
import torch # Library Utama AI (PyTorch)
from PIL import Image # Library pengolah gambar
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from passlib.context import CryptContext

# --- GABUNGAN IMPORTS (MERGED) ---
from pydantic import BaseModel, EmailStr
from sqlalchemy import Column, Integer, String, Text, Float, ForeignKey, create_engine, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker, relationship

# --- KONFIGURASI PATH UNTUK GAMBAR ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
IMAGES_DIR = os.path.join(STATIC_DIR, "images")
RAMBU_IMAGES_DIR = os.path.join(IMAGES_DIR, "rambu")
PROFILE_IMAGES_DIR = os.path.join(IMAGES_DIR, "profiles")
UPLOADS_DIR = os.path.join(IMAGES_DIR, "uploads")

# Buat folder jika belum ada
os.makedirs(STATIC_DIR, exist_ok=True)
os.makedirs(IMAGES_DIR, exist_ok=True)
os.makedirs(RAMBU_IMAGES_DIR, exist_ok=True)
os.makedirs(PROFILE_IMAGES_DIR, exist_ok=True)
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
    nama_lengkap = Column(String, nullable=True)
    profile_image = Column(String, nullable=True)

class Jelajahi(Base):
    __tablename__ = "jelajahi"
    id = Column(Integer, primary_key=True, index=True)
    rambu_id = Column(Integer, ForeignKey("rambu.id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    
    rambu = relationship("Rambu")

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
    nama_lengkap: Optional[str] = None

class RegisterResponse(BaseModel):
    message: str
    username: str
    user_id: int

class LoginResponse(BaseModel):
    message: str
    username: str
    user_id: int

class UserProfileResponse(BaseModel):
    id: int
    username: str
    nama_lengkap: Optional[str]
    alamat: Optional[str]
    profile_image: Optional[str]
    
    class Config:
        from_attributes = True

class UpdateProfileRequest(BaseModel):
    nama_lengkap: Optional[str] = None
    username: Optional[str] = None
    alamat: Optional[str] = None
    password: Optional[str] = None

# --- GABUNGAN SCHEMA (JELAJAHI milik Si M & AI milik Kamu) ---

# 1. Schema Maps (Dari Si M)
class JelajahiCreate(BaseModel):
    rambu_id: int
    latitude: float
    longitude: float

class JelajahiResponse(BaseModel):
    id: int
    rambu_id: int
    latitude: float
    longitude: float
    
    class Config:
        from_attributes = True

class JelajahiWithRambuResponse(BaseModel):
    id: int
    rambu_id: int
    latitude: float
    longitude: float
    nama: str
    gambar_url: Optional[str]
    deskripsi: Optional[str]
    kategori: str
    
    class Config:
        from_attributes = True

# 2. Schema AI (Dari Kamu)
class AIResponse(BaseModel):
    status: str
    terdeteksi: bool
    nama_rambu: Optional[str] = None
    confidence: Optional[float] = None
    deskripsi: Optional[str] = None
    kategori: Optional[str] = None
    pesan: str

# --- SETUP APLIKASI ---
app = FastAPI(title="RambuID API", version="1.0.0")

# Mount static files directory
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Buat semua tabel
Base.metadata.create_all(bind=engine)

# --- LOAD MODEL AI (YOLOv5) ---
# Global variable untuk menyimpan model
ai_model = None

@app.on_event("startup")
def load_ai_model():
    global ai_model
    try:
        # Path ke file best.pt (Pastikan file ini ada di sebelah app.py)
        model_path = os.path.join(BASE_DIR, "best.pt")
        
        if os.path.exists(model_path):
            print(f"Memuat model AI dari: {model_path}")
            # Load model custom YOLOv5
            ai_model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path, force_reload=True)
            
            # --- KONFIGURASI GLOBAL AI ---
            ai_model.conf = 0.10  
            ai_model.iou = 0.45   # IOU Threshold standar
            # -----------------------------
            
            print(f"Model AI berhasil dimuat! (Confidence Threshold: {ai_model.conf})")
        else:
            print("PERINGATAN: File 'best.pt' tidak ditemukan. Fitur AI tidak akan berfungsi.")
    except Exception as e:
        print(f"ERROR memuat model AI: {str(e)}")

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

def save_uploaded_file(file: UploadFile, destination_dir: str, prefix: str = "") -> str:
    """Menyimpan file upload dan mengembalikan path relatif"""
    file_extension = os.path.splitext(file.filename)[1]
    unique_filename = f"{prefix}{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(destination_dir, unique_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    folder_name = os.path.basename(destination_dir)
    return f"/static/images/{folder_name}/{unique_filename}"

# --- API ENDPOINTS ---

@app.get("/")
def read_root():
    return {"message": "Server Rambuid Berjalan dengan Integrasi AI & Maps!"}

@app.get("/health")
def health_check():
    ai_status = "active" if ai_model is not None else "inactive"
    return {"status": "ok", "ai_model": ai_status}

# === AI DETECTION ENDPOINT (DENGAN KAMUS MANUAL DARI DATA.YAML) ===
@app.post("/deteksi-rambu/", response_model=AIResponse)
async def detect_sign_ai(
    file: UploadFile = File(...), 
    db: Session = Depends(get_db)
):
    """
    Menerima gambar, melakukan deteksi objek (YOLOv5), 
    dan mencocokkan hasil dengan database Rambu.
    """
    if ai_model is None:
        raise HTTPException(status_code=503, detail="Model AI belum siap/tidak ditemukan di server.")

    try:
        # 1. Baca file gambar & KONVERSI KE RGB (FIX UNTUK PNG)
        image_data = await file.read()
        # .convert("RGB") sangat penting untuk mengatasi file PNG Transparan (RGBA)
        img = Image.open(io.BytesIO(image_data)).convert("RGB")

        # 2. Lakukan Prediksi (Menggunakan confidence global 0.10)
        results = ai_model(img)
        
        # --- DEBUG: MONITORING TERMINAL ---
        print("\n" + "="*30)
        print(f"--- DEBUG: Deteksi '{file.filename}' ---")
        # Mencetak hasil mentah (koordinat, confidence, class, name) ke terminal
        print(results.pandas().xyxy[0]) 
        print("="*30 + "\n")
        # ---------------------------------------------

        # 3. Ambil data hasil (Pandas DataFrame)
        df_results = results.pandas().xyxy[0]

        if df_results.empty:
            return {
                "status": "sukses",
                "terdeteksi": False,
                "pesan": "Tidak ada rambu yang dikenali dalam gambar ini."
            }

        # 4. Ambil hasil dengan confidence tertinggi
        top_prediction = df_results.iloc[0]
        class_index = int(top_prediction['class']) # Ambil Angka Kelas (0-19)
        confidence = float(top_prediction['confidence'])

        # --- KAMUS PENERJEMAH (SESUAI DATA.YAML RAMBUV6) ---
        names_dictionary = {
            0: 'Belok Kanan',
            1: 'Belok Kiri',
            2: 'Dilarang Belok Kanan',
            3: 'Dilarang Belok Kiri',
            4: 'Dilarang Berhenti',
            5: 'Dilarang Parkir',
            6: 'Dilarang Putar Balik',
            7: 'Hati-hati',
            8: 'Jalan Berkelok',
            9: 'Kecepatan Maksimal 100 km-jam',
            10: 'Kecepatan Maksimal 80 km-jam',
            11: 'Kecepatan Minimal 60 km-jam',
            12: 'Lampu Hijau',
            13: 'Lampu Kuning',
            14: 'Lampu Merah',
            15: 'Polisi Tidur',
            16: 'Putar Balik',
            17: 'Satu Arah',
            18: 'Tanjakan Tajam',
            19: 'Turunan Curam'
        }
        
        # Ambil nama dari kamus berdasarkan ID. 
        detected_name = names_dictionary.get(class_index, f"Rambu Tidak Dikenal (ID: {class_index})")
        # -----------------------------------------------------------

        # 5. Cari info detail di Database berdasarkan nama yang sudah diterjemahkan
        search_keyword = detected_name

        # Menggunakan ILIKE untuk case-insensitive search
        rambu_info = db.query(Rambu).filter(Rambu.nama.ilike(f"%{search_keyword}%")).first()

        deskripsi_db = "Deskripsi belum tersedia di database."
        kategori_db = "Tidak Diketahui"

        if rambu_info:
            deskripsi_db = rambu_info.deskripsi
            kategori_db = rambu_info.kategori
        else:
            # Pesan agar admin tahu nama apa yang harus diinput
            deskripsi_db = f"Data belum ada. Silakan input rambu dengan nama: '{detected_name}' di Admin."
        
        return {
            "status": "sukses",
            "terdeteksi": True,
            "nama_rambu": detected_name, 
            "confidence": confidence,
            "deskripsi": deskripsi_db,
            "kategori": kategori_db,
            "pesan": f"Berhasil mendeteksi: {detected_name}"
        }

    except Exception as e:
        print(f"Error AI: {e}")
        raise HTTPException(status_code=500, detail="Terjadi kesalahan saat memproses gambar.")


# === AUTHENTICATION ===
@app.post("/register", response_model=RegisterResponse, status_code=201)
def register_user(user: UserSchema, db: Session = Depends(get_db)):
    try:
        cek_user = db.query(User).filter(User.username == user.username).first()
        if cek_user:
            raise HTTPException(status_code=400, detail="Username sudah terdaftar!")
        
        hashed_password = hash_password(user.password)
        new_user = User(
            username=user.username, 
            password_hash=hashed_password,
            nama_lengkap=user.nama_lengkap
        )
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

# === USER PROFILE ENDPOINTS ===
@app.get("/users/{user_id}/profile", response_model=UserProfileResponse)
def get_user_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    if user.profile_image and not user.profile_image.startswith('http'):
        if not user.profile_image.startswith('/'):
            user.profile_image = f"/{user.profile_image}"
    
    return user

@app.put("/users/{user_id}/profile", response_model=UserProfileResponse)
def update_user_profile(
    user_id: int,
    nama_lengkap: Optional[str] = Form(None),
    username: Optional[str] = Form(None),
    alamat: Optional[str] = Form(None),
    password: Optional[str] = Form(None),
    profile_image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User tidak ditemukan")
        
        if nama_lengkap is not None:
            user.nama_lengkap = nama_lengkap
        
        if username is not None and username != user.username:
            existing_user = db.query(User).filter(User.username == username).first()
            if existing_user:
                raise HTTPException(status_code=400, detail="Username sudah digunakan")
            user.username = username
        
        if alamat is not None:
            user.alamat = alamat
        
        if password is not None and password.strip():
            if len(password) < 6:
                raise HTTPException(status_code=400, detail="Password minimal 6 karakter")
            user.password_hash = hash_password(password)
        
        if profile_image:
            allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
            file_extension = os.path.splitext(profile_image.filename)[1].lower()
            
            if file_extension not in allowed_extensions:
                raise HTTPException(status_code=400, detail="Format file tidak didukung.")
            
            if user.profile_image:
                old_image_path = os.path.join(BASE_DIR, user.profile_image.lstrip('/'))
                if os.path.exists(old_image_path):
                    try: os.remove(old_image_path)
                    except: pass
            
            image_path = save_uploaded_file(profile_image, PROFILE_IMAGES_DIR, prefix="profile_")
            user.profile_image = image_path
        
        db.flush()
        db.refresh(user)
        
        if user.profile_image and not user.profile_image.startswith('http'):
            if not user.profile_image.startswith('/'):
                user.profile_image = f"/{user.profile_image}"
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error update profil: {str(e)}")

@app.delete("/users/{user_id}/profile-image")
def delete_profile_image(user_id: int, db: Session = Depends(get_db)):
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User tidak ditemukan")
        
        if not user.profile_image:
            raise HTTPException(status_code=400, detail="User tidak memiliki foto profil")
        
        image_path = os.path.join(BASE_DIR, user.profile_image.lstrip('/'))
        if os.path.exists(image_path):
            os.remove(image_path)
        
        user.profile_image = None
        db.flush()
        
        return {"message": "Foto profil berhasil dihapus"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error hapus foto profil: {str(e)}")

# === CRUD RAMBU ===
@app.get("/rambu/", response_model=List[RambuResponse])
def get_all_rambu(db: Session = Depends(get_db)):
    rambu_list = db.query(Rambu).all()
    for rambu in rambu_list:
        if rambu.gambar_url and not rambu.gambar_url.startswith('http'):
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
    try:
        valid_kategori = ['larangan', 'peringatan', 'petunjuk', 'perintah']
        if kategori not in valid_kategori:
            raise HTTPException(status_code=400, detail=f"Kategori tidak valid.")
        
        allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
        file_extension = os.path.splitext(gambar.filename)[1].lower()
        if file_extension not in allowed_extensions:
            raise HTTPException(status_code=400, detail="Format file tidak didukung.")
        
        gambar_path = save_uploaded_file(gambar, RAMBU_IMAGES_DIR)
        
        new_rambu = Rambu(
            nama=nama,
            deskripsi=deskripsi,
            kategori=kategori,
            gambar_url=gambar_path
        )
        
        db.add(new_rambu)
        db.flush()
        db.refresh(new_rambu)
        
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
    try:
        rambu = db.query(Rambu).filter(Rambu.id == rambu_id).first()
        if not rambu:
            raise HTTPException(status_code=404, detail="Rambu tidak ditemukan")
        
        if nama is not None:
            rambu.nama = nama
        if deskripsi is not None:
            rambu.deskripsi = deskripsi
        if kategori is not None:
            valid_kategori = ['larangan', 'peringatan', 'petunjuk', 'perintah']
            if kategori not in valid_kategori:
                raise HTTPException(status_code=400, detail=f"Kategori tidak valid.")
            rambu.kategori = kategori
        
        if gambar:
            allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
            file_extension = os.path.splitext(gambar.filename)[1].lower()
            if file_extension not in allowed_extensions:
                raise HTTPException(status_code=400, detail="Format file tidak didukung")
            
            if rambu.gambar_url:
                old_image_path = os.path.join(BASE_DIR, rambu.gambar_url.lstrip('/'))
                if os.path.exists(old_image_path):
                    os.remove(old_image_path)
            
            gambar_path = save_uploaded_file(gambar, RAMBU_IMAGES_DIR)
            rambu.gambar_url = gambar_path
        
        db.flush()
        db.refresh(rambu)
        
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
    try:
        rambu = db.query(Rambu).filter(Rambu.id == rambu_id).first()
        if not rambu:
            raise HTTPException(status_code=404, detail="Rambu tidak ditemukan")
        
        if rambu.gambar_url:
            image_path = os.path.join(BASE_DIR, rambu.gambar_url.lstrip('/'))
            if os.path.exists(image_path):
                os.remove(image_path)
        
        db.delete(rambu)
        db.flush()
        
        return {"message": "Rambu berhasil dihapus"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error hapus rambu: {str(e)}")

# === JELAJAHI ENDPOINTS (FITUR DARI SI M) ===
@app.get("/jelajahi/", response_model=List[JelajahiWithRambuResponse])
def get_all_jelajahi_with_rambu(db: Session = Depends(get_db)):
    """Mendapatkan semua data jelajahi dengan informasi rambu"""
    try:
        results = db.query(
            Jelajahi.id,
            Jelajahi.rambu_id,
            Jelajahi.latitude,
            Jelajahi.longitude,
            Rambu.nama,
            Rambu.gambar_url,
            Rambu.deskripsi,
            Rambu.kategori
        ).join(
            Rambu, Jelajahi.rambu_id == Rambu.id
        ).all()
        
        data = []
        for r in results:
            gambar_url = r.gambar_url
            if gambar_url and not gambar_url.startswith('http'):
                if not gambar_url.startswith('/'):
                    gambar_url = f"/{gambar_url}"
            
            data.append({
                "id": r.id,
                "rambu_id": r.rambu_id,
                "latitude": float(r.latitude),
                "longitude": float(r.longitude),
                "nama": r.nama,
                "gambar_url": gambar_url,
                "deskripsi": r.deskripsi,
                "kategori": r.kategori
            })
        
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@app.post("/jelajahi/", response_model=JelajahiResponse, status_code=201)
def create_jelajahi(jelajahi: JelajahiCreate, db: Session = Depends(get_db)):
    try:
        rambu = db.query(Rambu).filter(Rambu.id == jelajahi.rambu_id).first()
        if not rambu:
            raise HTTPException(status_code=404, detail="Rambu tidak ditemukan")
        
        if not (-90 <= jelajahi.latitude <= 90) or not (-180 <= jelajahi.longitude <= 180):
            raise HTTPException(status_code=400, detail="Latitude/Longitude tidak valid")
        
        new_jelajahi = Jelajahi(
            rambu_id=jelajahi.rambu_id,
            latitude=jelajahi.latitude,
            longitude=jelajahi.longitude
        )
        
        db.add(new_jelajahi)
        db.flush()
        db.refresh(new_jelajahi)
        
        return new_jelajahi
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@app.put("/jelajahi/{jelajahi_id}", response_model=JelajahiResponse)
def update_jelajahi(
    jelajahi_id: int,
    jelajahi_data: JelajahiCreate,
    db: Session = Depends(get_db)
):
    try:
        jelajahi = db.query(Jelajahi).filter(Jelajahi.id == jelajahi_id).first()
        if not jelajahi:
            raise HTTPException(status_code=404, detail="Data tidak ditemukan")
        
        rambu = db.query(Rambu).filter(Rambu.id == jelajahi_data.rambu_id).first()
        if not rambu:
            raise HTTPException(status_code=404, detail="Rambu tidak ditemukan")
        
        if not (-90 <= jelajahi_data.latitude <= 90) or not (-180 <= jelajahi_data.longitude <= 180):
            raise HTTPException(status_code=400, detail="Latitude/Longitude tidak valid")
        
        jelajahi.rambu_id = jelajahi_data.rambu_id
        jelajahi.latitude = jelajahi_data.latitude
        jelajahi.longitude = jelajahi_data.longitude
        
        db.flush()
        db.refresh(jelajahi)
        
        return jelajahi
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@app.delete("/jelajahi/{jelajahi_id}")
def delete_jelajahi(jelajahi_id: int, db: Session = Depends(get_db)):
    try:
        jelajahi = db.query(Jelajahi).filter(Jelajahi.id == jelajahi_id).first()
        if not jelajahi:
            raise HTTPException(status_code=404, detail="Data tidak ditemukan")
        
        db.delete(jelajahi)
        db.flush()
        
        return {"message": "Lokasi berhasil dihapus"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@app.get("/jelajahi/{jelajahi_id}", response_model=JelajahiWithRambuResponse)
def get_jelajahi_by_id(jelajahi_id: int, db: Session = Depends(get_db)):
    try:
        result = db.query(
            Jelajahi.id,
            Jelajahi.rambu_id,
            Jelajahi.latitude,
            Jelajahi.longitude,
            Rambu.nama,
            Rambu.gambar_url,
            Rambu.deskripsi,
            Rambu.kategori
        ).join(
            Rambu, Jelajahi.rambu_id == Rambu.id
        ).filter(
            Jelajahi.id == jelajahi_id
        ).first()
        
        if not result:
            raise HTTPException(status_code=404, detail="Data tidak ditemukan")
        
        gambar_url = result.gambar_url
        if gambar_url and not gambar_url.startswith('http'):
            if not gambar_url.startswith('/'):
                gambar_url = f"/{gambar_url}"
        
        return {
            "id": result.id,
            "rambu_id": result.rambu_id,
            "latitude": float(result.latitude),
            "longitude": float(result.longitude),
            "nama": result.nama,
            "gambar_url": gambar_url,
            "deskripsi": result.deskripsi,
            "kategori": result.kategori
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

# === ADMIN FEATURES ===
@app.get("/users/")
def get_all_users(db: Session = Depends(get_db)):
    try:
        users = db.query(User).all()
        users_list = [
            {
                "id": user.id,
                "username": user.username,
                "nama_lengkap": user.nama_lengkap if user.nama_lengkap else None,
                "alamat": user.alamat if user.alamat else None,
                "profile_image": user.profile_image if user.profile_image else None
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
        total_jelajahi = db.query(Jelajahi).count()
        
        return {
            "total_users": total_users,
            "total_rambu": total_rambu,
            "total_jelajahi": total_jelajahi
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error saat mengambil statistik: {str(e)}")

@app.post("/jelajahi/from-map")
async def create_jelajahi_from_map(
    rambu_nama: str = Form(...),
    latitude: str = Form(...),
    longitude: str = Form(...),
    kategori: str = Form(...),
    deskripsi: Optional[str] = Form(None),
    gambar: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    try:
        try:
            lat_float = float(latitude)
            lng_float = float(longitude)
        except ValueError:
            raise HTTPException(status_code=400, detail="Latitude/Longitude format tidak valid")
        
        if not (-90 <= lat_float <= 90) or not (-180 <= lng_float <= 180):
            raise HTTPException(status_code=400, detail="Latitude/Longitude tidak valid")
        
        gambar_path = save_uploaded_file(gambar, RAMBU_IMAGES_DIR)
        
        new_rambu = Rambu(
            nama=rambu_nama,
            deskripsi=deskripsi,
            kategori=kategori,
            gambar_url=gambar_path
        )
        db.add(new_rambu)
        db.flush()
        db.refresh(new_rambu)
        
        new_jelajahi = Jelajahi(
            rambu_id=new_rambu.id,
            latitude=lat_float,
            longitude=lng_float
        )
        db.add(new_jelajahi)
        db.flush()
        db.refresh(new_jelajahi)
        
        return {
            "message": "Rambu dan lokasi berhasil ditambahkan",
            "rambu_id": new_rambu.id,
            "jelajahi_id": new_jelajahi.id
        }
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)