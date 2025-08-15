from flask import Flask, jsonify
app = Flask(__name__)

@app.get("/")
def root():
    return jsonify(ok=True, msg="hello from flask 😎")

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
