Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting RambuID Backend Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

# Check if virtual environment exists
if (-not (Test-Path "venv\Scripts\python.exe")) {
    Write-Host "ERROR: Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please create virtual environment first:" -ForegroundColor Yellow
    Write-Host "  python -m venv venv" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[1/4] Activating virtual environment..." -ForegroundColor Yellow
& "venv\Scripts\Activate.ps1"

Write-Host "[2/4] Checking dependencies..." -ForegroundColor Yellow
$checkDeps = & "venv\Scripts\python.exe" -c "import fastapi, uvicorn, sqlalchemy, passlib" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[3/4] Installing missing dependencies..." -ForegroundColor Yellow
    & "venv\Scripts\python.exe" -m pip install --upgrade pip
    & "venv\Scripts\python.exe" -m pip install fastapi==0.118.0 uvicorn==0.37.0 sqlalchemy passlib[bcrypt]
    Write-Host ""
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[3/4] All dependencies are installed." -ForegroundColor Green
    Write-Host ""
}

Write-Host "[4/4] Starting server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Server will run on http://localhost:8000" -ForegroundColor Green
Write-Host "  API Docs: http://localhost:8000/docs" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

& "venv\Scripts\python.exe" -m uvicorn app:app --host 0.0.0.0 --port 8000

