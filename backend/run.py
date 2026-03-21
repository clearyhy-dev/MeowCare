"""Cloud Run / production: start uvicorn with PORT from environment."""
import logging
import os

if __name__ == "__main__":
    import uvicorn
    from app.main import app

    port = int(os.environ.get("PORT", "8080"))
    logging.basicConfig(level=logging.INFO)
    logging.info("Listening on 0.0.0.0:%s", port)
    uvicorn.run(app, host="0.0.0.0", port=port)

