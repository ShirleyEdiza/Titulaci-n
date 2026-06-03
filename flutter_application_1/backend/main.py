from fastapi import FastAPI
from pydantic import BaseModel
from openai import OpenAI
import os
import random
import requests
import json

app = FastAPI()

# =========================
# OPENAI
# =========================

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

# =========================
# MODELO
# =========================

class Mensaje(BaseModel):
    mensaje: str
    historial_usuario: list[str] = []
    historial_asistente: list[str] = []

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
        respuesta = "¡Hola! ¿Cómo estás hoy?"

    elif "me llamo" in mensaje:
        respuesta = "Mucho gusto. ¿De dónde eres?"

    elif "bien" in mensaje:
        respuesta = "Me alegra escucharlo. ¿Qué estudias?"

    elif "from" in mensaje or "ecuador" in mensaje:
        respuesta = "Interesting. What do you study?"

    elif "study" in mensaje or "software" in mensaje:
        respuesta = "Excellent. Why do you like software engineering?"

    elif "basketball" in mensaje or "soccer" in mensaje:
        respuesta = "That sounds fun. How often do you play?"

    elif "food" in mensaje:
        respuesta = "Nice choice! Why do you like that food?"

    elif "bye" in mensaje or "goodbye" in mensaje:
        respuesta = "Goodbye! You did a great job today."

    elif "chao" in mensaje or "adiós" in mensaje:
        respuesta = "¡Hasta luego! Lo hiciste muy bien hoy."

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

    try:
        historial = ""

        for user_msg, assistant_msg in zip(
            data.historial_usuario,
            data.historial_asistente
        ):
            historial += f"Student: {user_msg}\n"
            historial += f"Assistant: {assistant_msg}\n"

        prompt = f"""
You are a friendly AI speaking tutor for beginner students.

You are a real native English tutor helping beginner A1/A2 students practice speaking.

VERY IMPORTANT RULES:
- If the student speaks English, respond ONLY in English.
- If the student speaks Spanish, respond ONLY in Spanish.
- NEVER mix English and Spanish in the same response.
- Speak naturally like a real person.
- Use fluent and natural English.
- Keep responses very short.
- Maximum 2 short sentences.
- Ask only ONE follow-up question.
- Use very common daily vocabulary.
- Be fast and direct.
- Do not explain too much.
- Do not use markdown.
- Do not use symbols or asterisks.
- If the student asks for translation in Spanish, translate naturally.
- If the student asks about days, months, food, hobbies, etc., answer naturally like a teacher.


Conversation history:
{historial}

Student:
{mensaje}
"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are a friendly AI speaking tutor for beginner A1/A2 students."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.4,
            max_tokens=60
        )

        texto = response.choices[0].message.content.strip()

        return {
            "respuesta": texto,
            "modo": "openai"
        }

    except Exception as e:
        print("OPENAI ERROR:", e)

        respuesta = respuesta_local(mensaje)

        return {
            "respuesta": respuesta,
            "modo": "local"
        }

# =========================
# ANALISIS GRAMATICAL
# =========================

@app.post("/analizar")
async def analizar(data: Mensaje):
    texto = data.mensaje.strip()

    try:
        prompt = f"""
You are a professional English grammar corrector for beginner A1/A2 students.

Your task is to correct the student's sentence.

IMPORTANT:
Return ONLY valid JSON.
Do not use markdown.
Do not use explanations outside JSON.

Correction rules:
- Correct grammar.
- Correct spelling.
- Correct capitalization.
- Correct punctuation.
- If speech-to-text recognized a strange word, infer the most probable word from context.
- Keep the student's original intention.
- If the sentence mixes Spanish and English, correct only the English intention.
- The corrected text must be natural and grammatically correct English.
- Do not leave the corrected text equal to the original if there are mistakes.
- Explain errors in simple Spanish.
- Only return these fields:
  texto_corregido
  errores_detectados
  puntuacion_gramatica
  nivel_detectado

Examples:
Original: please gun Speak in english
Corrected: Please, can you speak English?

Original: name Shirley
Corrected: My name is Shirley.

Original: my favorite food is atun
Corrected: My favorite food is tuna.

Student text:
{texto}

Return exactly this JSON format:

{{
  "texto_corregido": "",
  "errores_detectados": [
    ""
  ],
  "puntuacion_gramatica": 0,
  "nivel_detectado": "A1"
}}
"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You correct beginner English sentences and return only valid JSON."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.1,
            max_tokens=180
        )

        texto_respuesta = response.choices[0].message.content.strip()
        texto_respuesta = texto_respuesta.replace("```json", "")
        texto_respuesta = texto_respuesta.replace("```", "")
        texto_respuesta = texto_respuesta.strip()

        resultado = json.loads(texto_respuesta)

        return {
            "resultado": resultado
        }

    except Exception as e:
        print("ERROR ANALISIS:", e)

        return {
            "resultado": {
                "texto_corregido": "No se pudo generar una corrección.",
                "errores_detectados": [
                    "No se pudo analizar el texto correctamente."
                ],
                "puntuacion_gramatica": 0,
                "nivel_detectado": "A1"
            }
        }
# =========================
# ANALISIS DE PRONUNCIACION
# =========================

class PronunciacionRequest(BaseModel):
    texto_reconocido: str
    texto_referencia: str


@app.post("/pronunciacion")
async def pronunciacion(data: PronunciacionRequest):
    texto_reconocido = data.texto_reconocido.strip()
    texto_referencia = data.texto_referencia.strip()

    try:
        prompt = f"""
You are an English pronunciation evaluator for beginner A1/A2 students.

Analyze the student's recognized spoken sentence and compare it with the correct reference sentence.

Return ONLY valid JSON.
Do not use markdown.

Important:
- Detect words that the student should practice.
- Focus on English pronunciation.
- Give a simple pronunciation guide.
- Feedback must be in Spanish.
- Do not include many words, only the most important pronunciation problems.
- If the sentence is mostly correct, still suggest 1 or 2 useful words to practice.
- Use simple phonetic guidance, not complex IPA only.

Student recognized text:
{texto_reconocido}

Correct reference text:
{texto_referencia}

Return exactly this JSON:

{{
  "texto_reconocido": "",
  "texto_referencia": "",
  "puntuacion_pronunciacion": 0,
  "palabras_observadas": [
    {{
      "palabra": "",
      "pronunciacion_correcta": "",
      "explicacion": ""
    }}
  ]
}}
"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You evaluate beginner English pronunciation and return only JSON."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.2,
            max_tokens=250
        )

        texto_respuesta = response.choices[0].message.content.strip()
        texto_respuesta = texto_respuesta.replace("```json", "")
        texto_respuesta = texto_respuesta.replace("```", "")
        texto_respuesta = texto_respuesta.strip()

        resultado = json.loads(texto_respuesta)

        return {
            "resultado": resultado
        }

    except Exception as e:
        print("ERROR PRONUNCIACION:", e)

        return {
            "resultado": {
                "texto_reconocido": texto_reconocido,
                "texto_referencia": texto_referencia,
                "puntuacion_pronunciacion": 0,
                "palabras_observadas": []
            }
        }