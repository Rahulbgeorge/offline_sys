from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Welcome to the dummy server"}

@app.get("/hello")
def say_hello():
    return {"message": "hello world"}

@app.get("/bye")
def say_bye():
    return {"message": "bye bye world"}
