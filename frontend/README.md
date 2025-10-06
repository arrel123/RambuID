# Flutter + Python App

This project is a demonstration of a Flutter frontend interacting with a Python backend. It showcases how to set up a simple application that fetches data from a backend API.

## Project Structure

```
flutter-python-app
├── backend
│   ├── app.py
│   ├── requirements.txt
│   └── README.md
├── frontend
│   ├── lib
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── README.md
└── README.md
```

## Frontend

The frontend is built using Flutter and is located in the `frontend` directory. It consists of the following:

- **lib/main.dart**: The main entry point of the Flutter application. It sets up the MaterialApp and defines the HomePage widget, which fetches data from the backend.
- **pubspec.yaml**: The configuration file for the Flutter project, specifying dependencies and other metadata.

### Setup Instructions

1. Ensure you have Flutter installed on your machine.
2. Navigate to the `frontend` directory.
3. Run `flutter pub get` to install the necessary dependencies.
4. Use `flutter run` to start the application.

## Backend

The backend is built using Python and is located in the `backend` directory. It consists of the following:

- **app.py**: The main entry point for the Python backend application. It sets up the web server and defines the API endpoints.
- **requirements.txt**: Lists the Python dependencies required for the backend application.

### Setup Instructions

1. Ensure you have Python installed on your machine.
2. Navigate to the `backend` directory.
3. Run `pip install -r requirements.txt` to install the necessary packages.
4. Use `python app.py` to start the backend server.

## Usage

Once both the frontend and backend are running, the Flutter application will fetch data from the Python backend and display it on the screen.