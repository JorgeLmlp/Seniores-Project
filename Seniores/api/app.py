from flask import Flask
from extensions import app
from routes import *




if __name__ == "__main__":
    app.run(debug=True)
    