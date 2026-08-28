from extensions import app
import os


if __name__ == "__main__":
    # DEBUG vem do .env para evitar deixar o depurador ligado em producao.
    debug_mode = os.getenv("DEBUG", "0").lower() == "1"
    # 0.0.0.0 permite que outros dispositivos da rede acessem a API.
    app.run(debug=debug_mode, host="0.0.0.0", port=5001)
