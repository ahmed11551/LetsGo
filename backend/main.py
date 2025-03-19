from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Загружаем переменные окружения
load_dotenv()

app = FastAPI(
    title="LetsGo API",
    description="API для приложения поиска попутчиков и водителей",
    version="1.0.0"
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене заменить на конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Добро пожаловать в API LetsGo!"}

# Здесь будут импортироваться роуты
# from routes import auth, trips, users, payments, etc. 