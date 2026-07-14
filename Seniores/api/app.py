from extensions import app
import os


if __name__ == "__main__":
    debug_mode = os.getenv("DEBUG", "0").lower() == "1"
    app.run(debug=debug_mode, host="0.0.0.0", port=5000)