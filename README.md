# Optimal Flight Route Finder

A web application for finding the optimal flight route between cities based on cost or duration, powered by [Flask](https://flask.palletsprojects.com/) and [Hyperon MeTTa](https://github.com/trueagi-io/hyperon-experimental).

## Features

- **Add new flight routes** with airline, duration, cost, and layovers.
- **Find the optimal route** between two cities based on cost or duration.
- **Modern Bootstrap UI** for easy interaction.
- **Powered by MeTTa**: All route logic and optimization is handled by the MeTTa engine.

## Project Structure

```
path_finder/
├── app.py                # Flask backend
├── flight.metta          # MeTTa script with flight data and route logic
├── requirements.txt      # Python dependencies
├── templates/
│   └── index.html        # Main UI (Bootstrap)
└── static/
    └── style.css         # Custom styles (optional)
```

## Getting Started

### 1. Clone the repository

```sh
git clone https://github.com/abrham17/metta_path_finder
cd path_finder
```

### 2. Set up a virtual environment

```sh
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

```sh
pip install -r requirements.txt
```

### 4. Run the app

```sh
python app.py
```
or (recommended for development):
```sh
export FLASK_APP=app.py
export FLASK_DEBUG=1
flask run --port=5001
```

Visit [http://127.0.0.1:5001/](http://127.0.0.1:5001/) in your browser.

## Usage

- **Find Route:**  
  Enter the start and end cities, select optimization criteria (Cost or Duration), and click "Find Route" to see the optimal path.

- **Add Flight:**  
  Fill in the flight details and click "Add Flight" to add a new route to the system.

## How It Works

- The backend uses Hyperon MeTTa to store and process flight data.
- When you add a flight, it is stored as a MeTTa atom.
- When you search for a route, MeTTa runs a Dijkstra-like algorithm (defined in `flight.metta`) to find the optimal path based on your criteria.

## Requirements

- Python 3.8+
- [Flask](https://flask.palletsprojects.com/)
- [Hyperon](https://github.com/trueagi-io/hyperon-experimental)

## Troubleshooting

- **Port already in use:**  
  If you see `Address already in use`, kill the process using the port:
  ```sh
  sudo lsof -i :5001
  kill <PID>
  ```

- **404 Not Found:**  
  Make sure you are visiting the correct URL and that the Flask app is running.

- **MeTTa errors:**  
  Ensure `flight.metta` is present in the project directory.

