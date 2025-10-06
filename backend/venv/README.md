# Backend Documentation

## Overview
This is the backend component of the Flutter + Python application. It is built using Python and serves as the API for the Flutter frontend.

## Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd flutter-python-app/backend
   ```

2. **Create a virtual environment (optional but recommended):**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the application:**
   ```bash
   python app.py
   ```

## Usage
Once the server is running, you can access the API at `http://127.0.0.1:8000/`. The API will respond with a JSON object containing a message.

## Endpoints
- `GET /`: Returns a JSON object with a message.

## Notes
Make sure to have Python 3.x installed on your machine. Adjust the port in `app.py` if needed to avoid conflicts with other services.