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

# --- GABUNGAN IMPORTS ---
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, Text, Float, ForeignKey, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker, relationship

# --- KONFIGURASI PATH ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
IMAGES_DIR = os.path.join(STATIC_DIR, "images")
RAMBU_IMAGES_DIR = os.path.join(IMAGES_DIR, "rambu")
PROFILE_IMAGES_DIR = os.path.join(IMAGES_DIR, "profiles")
UPLOADS_DIR = os.path.join(IMAGES_DIR, "uploads")

os.makedirs(STATIC_DIR, exist_ok=True)
os.makedirs(IMAGES_DIR, exist_ok=True)
os.makedirs(RAMBU_IMAGES_DIR, exist_ok=True)
os.makedirs(PROFILE_IMAGES_DIR, exist_ok=True)
os.makedirs(UPLOADS_DIR, exist_ok=True)

# --- KONFIGURASI DATABASE ---
DATABASE_URL = "sqlite:///./rambuid.db"
engine = create_engine(
    DATABASE_URL, 
    connect_args={"check_same_thread": False, "timeout": 20},
    pool_pre_ping=True,
    pool_recycle=3600,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

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

# --- SCHEMA ---
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

class AIResponse(BaseModel):
    status: str
    terdeteksi: bool
    nama_rambu: Optional[str] = None
    confidence: Optional[float] = None
    deskripsi: Optional[str] = None
    kategori: Optional[str] = None
    pesan: str

# --- SETUP APP ---
app = FastAPI(title="RambuID API", version="1.0.0")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
Base.metadata.create_all(bind=engine)

# --- LOAD AI ---
ai_model = None
@app.on_event("startup")
def load_ai_model():
    global ai_model
    try:
        model_path = os.path.join(BASE_DIR, "best.pt")
        if os.path.exists(model_path):
            print(f"Memuat model AI dari: {model_path}")
            ai_model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path, force_reload=True)
            ai_model.conf = 0.45 # Threshold confidence
            ai_model.iou = 0.45
            print("Model AI Siap!")
        else:
            print("WARNING: best.pt tidak ditemukan.")
    except Exception as e:
        print(f"Error load AI: {e}")

# --- HELPERS ---
def get_db():
    db = SessionLocal()
    try: yield db; db.commit()
    except: db.rollback(); raise
    finally: db.close()

def hash_password(p: str): return pwd_context.hash(p)
def verify_password(p: str, h: str): return pwd_context.verify(p, h)

def save_uploaded_file(file: UploadFile, dest: str, prefix: str = "") -> str:
    ext = os.path.splitext(file.filename)[1]
    name = f"{prefix}{uuid.uuid4()}{ext}"
    path = os.path.join(dest, name)
    with open(path, "wb") as b: shutil.copyfileobj(file.file, b)
    return f"/static/images/{os.path.basename(dest)}/{name}"

# --- ENDPOINTS ---

@app.get("/")
def read_root(): return {"message": "Server Rambuid Ready"}

@app.post("/deteksi-rambu/", response_model=AIResponse)
async def detect_sign_ai(file: UploadFile = File(...), db: Session = Depends(get_db)):
    if ai_model is None: raise HTTPException(503, "AI belum siap")
    try:
        img_data = await file.read()
        img = Image.open(io.BytesIO(img_data)).convert("RGB")
        
        # Prediksi
        results = ai_model(img)
        df = results.pandas().xyxy[0]

        # --- DEBUGGING LENGKAP DI TERMINAL ---
        print("\n" + "="*30)
        print(f"--- DEBUG: MATA AI MELIHAT ---")
        if df.empty:
            print(">> Tidak melihat apapun.")
        else:
            for index, row in df.iterrows():
                print(f"Kandidat {index+1}: ID {int(row['class'])} ({row['name']}) - Yakin: {row['confidence']:.2f}")
        print("="*30 + "\n")
        # -------------------------------------

        if df.empty:
            return {"status": "sukses", "terdeteksi": False, "pesan": "Tidak ada rambu"}

        # Ambil yang confidence-nya paling tinggi
        top = df.iloc[0]
        cls_idx = int(top['class'])
        conf = float(top['confidence'])

        names_dictionary = {
            0: 'Balai Pertolongan Pertama',
            1: 'Banyak Anak-Anak',
            2: 'Tikungan Ganda Pertama Ke Kanan',
            3: 'Banyak Tikungan Pertama Kanan',
            4: 'Berhenti',
            5: 'Dilarang Belok Kanan',
            6: 'Dilarang Belok Kiri',
            7: 'Dilarang Berhenti',
            8: 'Dilarang Masuk',
            10: 'Dilarang Parkir',
            11: 'Dilarang Putar Balik',
            12: 'Gereja',
            13: 'Hati-Hati',
            14: 'Ikuti Bundaran',
            15: 'Jalur Sepeda',
            16: 'Kecepatan Maks. 40 km', 
            17: 'Kecepatan Maks. 40 km',
            19: 'Lampu Lalu Lintas',
            21: 'Masjid',
            22: 'Pemberhentian Bus',
            23: 'Penyebrangan Pejalan Kaki',
            24: 'Peringatan Perlintasan Kereta Api',
            25: 'Perintah Jalur Penyebrangan',
            26: 'Persimpangan 3 Sisi Kiri',
            27: 'Persimpangan 3 Prioritas Kanan',
            28: 'Persimpangan 3 Prioritas',
            29: 'Persimpangan 3 Sisi Kiri',
            30: 'Persimpangan 4',
            31: 'Pilih Salah Satu Jalur',
            32: 'Polisi Tidur',
            33: 'Pom Bensin',
            34: 'Putar Balik',
            35: 'Rumah Sakit',
            36: 'Tempat Parkir'
        }

        # Jika AI mendeteksi ID yang sudah dihapus (9 atau 20), dia akan masuk ke "Unknown"
        detected_name = names_dictionary.get(cls_idx, f"Unknown (ID: {cls_idx})")

        # Cari di DB dengan NAMA PERSIS (==)
        info = db.query(Rambu).filter(Rambu.nama == detected_name).first()

        desc = "Deskripsi belum ada."
        kat = "Tidak Diketahui"
        is_detected = True

        if info:
            desc = info.deskripsi
            kat = info.kategori
        else:
            # Fallback pencarian mirip
            info_fuzzy = db.query(Rambu).filter(Rambu.nama.ilike(f"%{detected_name}%")).first()
            if info_fuzzy:
                desc = info_fuzzy.deskripsi
                kat = info_fuzzy.kategori
                detected_name = info_fuzzy.nama
            else:
                # Jika benar-benar tidak ada di kamus (misal ID 9 atau 20 terdeteksi)
                is_detected = False
                desc = f"Rambu terdeteksi (ID {cls_idx}) namun dinonaktifkan."

        return {
            "status": "sukses",
            "terdeteksi": is_detected,
            "nama_rambu": detected_name if is_detected else "Tidak Terdaftar",
            "confidence": conf,
            "deskripsi": desc,
            "kategori": kat,
            "pesan": f"Deteksi: {detected_name}"
        }
    except Exception as e:
        print(f"Error AI: {e}")
        raise HTTPException(500, "Gagal memproses gambar")

# === AUTH & USER ===
@app.post("/register", response_model=RegisterResponse)
def reg(user: UserSchema, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username==user.username).first():
        raise HTTPException(400, "Username ada")
    new_user = User(username=user.username, password_hash=hash_password(user.password), nama_lengkap=user.nama_lengkap)
    db.add(new_user); db.commit(); db.refresh(new_user)
    return {"message": "Daftar sukses", "username": new_user.username, "user_id": new_user.id}

@app.post("/login", response_model=LoginResponse)
def login(user: UserSchema, db: Session = Depends(get_db)):
    u = db.query(User).filter(User.username==user.username).first()
    if not u or not verify_password(user.password, u.password_hash):
        raise HTTPException(400, "Login gagal")
    return {"message": "Login sukses", "user_id": u.id, "username": u.username}

@app.get("/users/{uid}/profile", response_model=UserProfileResponse)
def get_prof(uid: int, db: Session = Depends(get_db)):
    u = db.query(User).filter(User.id==uid).first()
    if not u: raise HTTPException(404, "User 404")
    if u.profile_image and not u.profile_image.startswith(('http','/')): u.profile_image = f"/{u.profile_image}"
    return u

@app.put("/users/{uid}/profile", response_model=UserProfileResponse)
def upd_prof(uid: int, nama_lengkap: Optional[str]=Form(None), username: Optional[str]=Form(None), alamat: Optional[str]=Form(None), password: Optional[str]=Form(None), profile_image: Optional[UploadFile]=File(None), db: Session=Depends(get_db)):
    u = db.query(User).filter(User.id==uid).first()
    if not u: raise HTTPException(404, "User 404")
    if nama_lengkap: u.nama_lengkap = nama_lengkap
    if username and username != u.username:
        if db.query(User).filter(User.username==username).first(): raise HTTPException(400, "Username terpakai")
        u.username = username
    if alamat: u.alamat = alamat
    if password and len(password)>=6: u.password_hash = hash_password(password)
    if profile_image:
        u.profile_image = save_uploaded_file(profile_image, PROFILE_IMAGES_DIR, "prof_")
    db.commit(); db.refresh(u)
    if u.profile_image and not u.profile_image.startswith(('http','/')): u.profile_image = f"/{u.profile_image}"
    return u

@app.delete("/users/{uid}/profile-image")
def del_prof_img(uid: int, db: Session=Depends(get_db)):
    u = db.query(User).filter(User.id==uid).first()
    if not u: raise HTTPException(404)
    u.profile_image = None
    db.commit()
    return {"message": "Foto dihapus"}

# === RAMBU & JELAJAHI ===
@app.get("/rambu/", response_model=List[RambuResponse])
def all_rambu(db: Session=Depends(get_db)):
    res = db.query(Rambu).all()
    for r in res:
        if r.gambar_url and not r.gambar_url.startswith(('http','/')): r.gambar_url = f"/{r.gambar_url}"
    return res

@app.get("/jelajahi/", response_model=List[JelajahiWithRambuResponse])
def all_jelajahi(db: Session=Depends(get_db)):
    res = db.query(Jelajahi.id, Jelajahi.rambu_id, Jelajahi.latitude, Jelajahi.longitude, Rambu.nama, Rambu.gambar_url, Rambu.deskripsi, Rambu.kategori).join(Rambu).all()
    out = []
    for r in res:
        url = r.gambar_url
        if url and not url.startswith(('http','/')): url = f"/{url}"
        out.append({"id":r.id, "rambu_id":r.rambu_id, "latitude":r.latitude, "longitude":r.longitude, "nama":r.nama, "gambar_url":url, "deskripsi":r.deskripsi, "kategori":r.kategori})
    return out

@app.post("/jelajahi/", response_model=JelajahiResponse)
def add_loc(d: JelajahiCreate, db: Session=Depends(get_db)):
    new_loc = Jelajahi(rambu_id=d.rambu_id, latitude=d.latitude, longitude=d.longitude)
    db.add(new_loc); db.commit(); db.refresh(new_loc)
    return new_loc

# Endpoint Admin/Stats
@app.get("/users/")
def all_users(db: Session=Depends(get_db)): return db.query(User).all()

@app.get("/stats/")
def stats(db: Session=Depends(get_db)):
    return {"total_users": db.query(User).count(), "total_rambu": db.query(Rambu).count(), "total_jelajahi": db.query(Jelajahi).count()}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)