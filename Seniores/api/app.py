from flask import Flask
from extensions import create_app
from routes import *

app = create_app()


if __name__ == "__main__":
    app.run(debug=True)
    