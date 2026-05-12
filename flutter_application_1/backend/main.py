from fastapi import FastAPI
from pydantic import BaseModel
from google import genai
import os
import random

app = FastAPI()

# =========================
# GEMINI
# =========================

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

# =========================
# MODELO
# =========================

class Mensaje(BaseModel):
    mensaje: str

# =========================
# MEMORIA LOCAL
# =========================

estado = {
    "paso": 0,
    "ultima_pregunta": ""
}

preguntas = [
    "How are you today?",
    "What is your name?",
    "Where are you from?",
    "What do you study?",
    "Why do you like that career?",
    "What are your hobbies?",
    "What is your favorite food?",
    "Why do you want to learn English?",
    "Great job! Keep practicing your English."
]

# =========================
# RESPUESTA LOCAL
# =========================

def respuesta_local(mensaje_original):

    mensaje = mensaje_original.lower().strip()

    if "hello" in mensaje or "hi" in mensaje:
        respuesta = "Hello! How are you today?"

    elif "my name is" in mensaje:
        respuesta = "Nice to meet you! Where are you from?"

    elif "hola" in mensaje:
        respuesta = "Hello! Please continue speaking in English."

    elif "from" in mensaje or "ecuador" in mensaje:
        respuesta = "Interesting. What do you study?"

    elif "study" in mensaje or "software" in mensaje:
        respuesta = "Excellent. Why do you like software engineering?"

    elif "basketball" in mensaje or "soccer" in mensaje:
        respuesta = "That sounds fun. How often do you play?"

    elif "food" in mensaje:
        respuesta = "Nice choice! Why do you like that food?"

    elif "bye" in mensaje:
        respuesta = "Goodbye! You did a great job today."

    else:

        estado["paso"] += 1

        if estado["paso"] >= len(preguntas):
            estado["paso"] = len(preguntas) - 1

        respuesta = random.choice([
            f"Good answer. {preguntas[estado['paso']]}",
            f"Very nice. {preguntas[estado['paso']]}",
            f"Interesting. {preguntas[estado['paso']]}"
        ])

    estado["ultima_pregunta"] = respuesta

    return respuesta

# =========================
# ROOT
# =========================

@app.get("/")
def read_root():
    return {
        "message": "Servidor IA funcionando 🚀"
    }

# =========================
# CHAT
# =========================

@app.post("/chat")
async def chat(data: Mensaje):

    mensaje = data.mensaje

    # =========================
    # INTENTA GEMINI
    # =========================

    try:

        prompt = f"""
        You are an English speaking tutor for beginner students.

        Rules:
        - Always answer in English.
        - If the student speaks Spanish, understand it and answer in English.
        - Keep answers under 25 words.
        - Ask one short follow-up question.
        - Be friendly and conversational.

        Student:
        {mensaje}
        """

        response = client.models.generate_content(
            model="gemini-1.5-flash-8b",
            contents=prompt
        )

        texto = response.text.strip()

        return {
            "respuesta": texto,
            "modo": "gemini"
        }

    # =========================
    # SI GEMINI FALLA
    # =========================

    except Exception as e:

        print("GEMINI ERROR:", e)

        respuesta = respuesta_local(mensaje)

        return {
            "respuesta": respuesta,
            "modo": "local"
        }