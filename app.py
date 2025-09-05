from flask import Flask, request, jsonify, render_template
from hyperon import *
import os

app = Flask(__name__)

# Initialize MeTTa and load script
metta = MeTTa()
re = metta.run('!(import! &self flight)')
print(re)
# API to add new flight data
@app.route('/update-flight-data', methods=['POST'])
def update_flight_data():
    data = request.json
    start = data['start']
    end = data['end']
    airline = data['airline']
    duration = data['duration']
    cost = data['cost']
    layovers = data.get('layovers', 0)
    
    # Add to MeTTa
    atom_str = f"(flight-route {start} {end} {airline} {duration} {cost} {layovers})"
    result = metta.run(f"!(add-atom &self {atom_str})")
    print(result)
    return jsonify({'status': 'success'})

# API to get optimized route
@app.route('/get-optimized-route', methods=['POST'])
def get_optimized_route():
    data = request.json
    start = data['start']
    end = data['end']
    criteria = data['criteria']  # 'Cost' or 'Duration'
    
    # Query MeTTa
    result = metta.run(f"!(getOptimizedRoute {start} {end} {criteria})")
    print(result)
    # Parse result (assuming single result for simplicity)
    for r in result[0]:
        path = str(r.get_children()[0])
        return jsonify({'path': path})
    else:
        return jsonify({'error': 'No path found'})

@app.route("/")
def home():
    return render_template("index.html")

if __name__ == "__main__":
    app.run(port=5001, debug=True)