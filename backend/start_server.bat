@echo off
echo ========================================
echo   Starting RambuID Backend Server
echo ========================================
echo.

cd /d %~dp0

echo [1/4] Checking virtual environment...
if not exist "venv\Scripts\python.exe" (
    echo ERROR: Virtual environment not found!
    echo Please create virtual environment first:
    echo   python -m venv venv
    pause
    exit /b 1
)

echo [2/4] Activating virtual environment...
call venv\Scripts\activate.bat

echo [3/4] Checking and installing dependencies...
venv\Scripts\python.exe -c "import fastapi, uvicorn, sqlalchemy, passlib" 2>nul
if errorlevel 1 (
    echo Installing missing dependencies...
    venv\Scripts\python.exe -m pip install --upgrade pip
    venv\Scripts\python.exe -m pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]
    echo.
    echo Dependencies installed successfully!
    echo.
) else (
    echo All dependencies are installed.
    echo.
)

echo [4/4] Starting server...
echo.
echo ========================================
echo   Server will run on http://localhost:8000
echo   API Docs: http://localhost:8000/docs
echo   Press Ctrl+C to stop the server
echo ========================================
echo.

venv\Scripts\python.exe -m uvicorn app:app --host 0.0.0.0 --port 8000

pause

