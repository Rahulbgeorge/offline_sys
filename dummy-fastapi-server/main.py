import logging
import random
import os
from fastapi import FastAPI, Request

# Create log directory if it doesn't exist
log_dir = "/root/server/logs"
os.makedirs(log_dir, exist_ok=True)

# Configure logger
logging.basicConfig(
    filename=f"{log_dir}/api.log",
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("dummy-fastapi")

app = FastAPI()

@app.middleware("http")
async def random_crash_middleware(request: Request, call_next):
    logger.info(f"API hit: {request.method} {request.url.path}")
    
    # 30% chance to randomly crash the request
    if random.random() < 0.3:
        logger.error(f"Random crash triggered on {request.url.path}!")
        raise Exception("Random dummy server crash sequence initiated!")
    
    response = await call_next(request)
    return response

@app.get("/")
def read_root():
    return {"message": "Welcome to the dummy server"}

@app.get("/hello")
def say_hello():
    return {"message": "hello world"}

@app.get("/bye")
def say_bye():
    return {"message": "bye bye world"}
