# Flask app -- Ditto will assume this interface
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/users', methods=['GET'])
def get_users():
    return jsonify([{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}])

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    return jsonify({'id': user_id, 'name': 'Alice'})

@app.post('/users')
def create_user():
    data = request.get_json()
    return jsonify({'id': 3, **data}), 201

@app.delete('/users/<int:user_id>')
def delete_user(user_id):
    return '', 204

if __name__ == '__main__':
    app.run(port=5000)
