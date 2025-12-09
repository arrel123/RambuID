import requests

# URL API (sesuaikan jika port berbeda)
url = 'http://localhost:8000/deteksi-rambu/'

# Ganti dengan nama file gambar yang mau dites
file_gambar = {'file': open('test_parkir.jpg', 'rb')}

try:
    print("Mengirim gambar ke AI...")
    response = requests.post(url, files=file_gambar)
    
    # Tampilkan hasil
    print("\n=== HASIL DETEKSI AI ===")
    print(response.json())
    
except Exception as e:
    print(f"Error: {e}")