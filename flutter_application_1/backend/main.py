from fastapi import FastAPI
from pydantic import BaseModel
from openai import OpenAI
from fastapi import UploadFile, File
import tempfile
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
- Answer in one short sentence.
- Maximum 10 words.
- Ask only one simple question.
- Do not give explanations.
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
            temperature=0.3,
            max_tokens=40
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


@app.post("/transcribir")
async def transcribir(audio: UploadFile = File(...)):
    try:
        suffix = os.path.splitext(audio.filename)[1] or ".m4a"

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp:
            temp.write(await audio.read())
            temp_path = temp.name

        with open(temp_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
    model="gpt-4o-mini-transcribe",
    file=audio_file,
    language="en",
    prompt=(
        "Transcribe exactly what the student says. "
        "The student is a Spanish-speaking beginner practicing English. "
        "Do not correct grammar. "
        "Do not add missing words. "
        "Do not change Spanish words into English. "
        "Keep mixed Spanish-English phrases as spoken. "
        "Examples: if the student says 'Hola my name Shirley', transcribe exactly 'Hola my name Shirley'. "
        "If the student says 'my name Shirley', do not add 'is'. "
        "If the student says 'I go to school', do not add 'a'. "
        "If the student says 'day', prefer 'day' in the context of feelings or routine."
    
    )
)

        os.remove(temp_path)

        return {
            "texto": transcription.text
        }

    except Exception as e:
        print("ERROR TRANSCRIPCION:", e)
        return {
            "texto": ""
        }
# =========================
# ANALISIS GRAMATICAL
# =========================

@app.post("/analizar")
async def analizar(data: Mensaje):
    texto = data.mensaje.strip()

    try:
        prompt = f"""
You are a professional English grammar evaluator for beginner A1/A2 students.

Analyze the student's spoken text. The text may come from speech-to-text, so it can contain recognition mistakes.

IMPORTANT:
Return ONLY valid JSON.
Do not use markdown.
Feedback must be in Spanish.

Correction rules:
- Focus on grammar, sentence structure, missing words, word order and vocabulary.
- Do NOT focus on small punctuation mistakes, such as extra periods, double spaces, or missing commas.
- Correct the sentence naturally in English.
- Keep the student's original intention.
- If speech-to-text recognized a strange word, infer the most probable word from context.
- If the context is about feelings or routine, prefer "day" instead of "daily", "dayli", "daddy" or "dad".
- If the student says "my day is god", correct it as "my day is good".
- If the student says "my name Shirley", detect that "is" is missing.
- Do not invent new ideas.
- Do not translate the corrected text into Spanish.
- Errors must be written in simple Spanish.
- Do not report punctuation errors unless they seriously affect understanding.
- The grammar score must be from 1 to 100.
- Use 0 only if the text is empty or impossible to understand.
- If there are grammar errors but the sentence is understandable, use a score between 50 and 80.
- If there are few errors, use a score between 75 and 90.
- If the sentence is correct, use a score between 90 and 100.

Student text:
{texto}

Return exactly this JSON format:

{{
  "texto_corregido": "",
  "errores_detectados": [],
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
            max_tokens=220
        )

        texto_respuesta = response.choices[0].message.content.strip()
        texto_respuesta = texto_respuesta.replace("```json", "")
        texto_respuesta = texto_respuesta.replace("```", "")
        texto_respuesta = texto_respuesta.strip()

        resultado = json.loads(texto_respuesta)

        if resultado.get("puntuacion_gramatica", 0) == 0 and texto.strip():
            resultado["puntuacion_gramatica"] = 60

        return {
            "resultado": resultado
        }

    except Exception as e:
        print("ERROR ANALISIS:", e)

        return {
            "resultado": {
                "texto_corregido": texto,
                "errores_detectados": [
                    "No se pudo analizar el texto correctamente."
                ],
                "puntuacion_gramatica": 60 if texto.strip() else 0,
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

The recognized text may contain speech-to-text mistakes. Do not evaluate incorrect recognized words blindly.
Infer the intended word when the context is clear.

IMPORTANT:
Return ONLY valid JSON.
Do not use markdown.
Feedback must be in Spanish.

Evaluation rules:
- Evaluate pronunciation, not grammar.
- Do not mark missing grammar words as pronunciation errors.
- If the recognized text contains "daily", "dayli", "daddy" or "dad" in the context "my day is good", treat the intended word as "day".
- If the student intended to say "day", the word to practice must be "day", not "daily" or "dayli".
- If the student says "god" in the context "my day is good", the word to practice must be "good".
- If the student says Spanish words like "hola", explain that the English phrase should be "Hello".
- If the student says "name" with poor pronunciation, suggest practicing "name".
- If the sentence is understandable, do not give 0.
- Pronunciation score must be from 1 to 100.
- Use 0 only if there is no recognizable speech.
- If pronunciation is understandable but imperfect, use 55 to 80.
- If pronunciation is clear, use 80 to 95.
- Include only the most important words to practice.
-If the student speaks in Spanish,
generate a corrected English sentence and provide its pronunciation guide.
-If the student uses Spanish words:
- Convert them to the most appropriate English equivalent.
- The word to practice must be the English word.
- Never use the Spanish word as the pronunciation target.

Examples:

Hola -> Hello
Buenos días -> Good morning
Mi nombre -> My name
Gracias -> Thank you
Adiós -> Goodbye

Student recognized text:
{texto_reconocido}

Correct reference text:
{texto_referencia}

Return exactly this JSON:

{{
  "texto_reconocido": "",
  "texto_referencia": "",
  "frase_recomendada": "",
  "pronunciacion_frase": "",
  "comentario_oral": "",
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
            temperature=0.1,
            max_tokens=300
        )

        texto_respuesta = response.choices[0].message.content.strip()
        texto_respuesta = texto_respuesta.replace("```json", "")
        texto_respuesta = texto_respuesta.replace("```", "")
        texto_respuesta = texto_respuesta.strip()

        resultado = json.loads(texto_respuesta)

        if resultado.get("puntuacion_pronunciacion", 0) == 0 and texto_reconocido.strip():
            resultado["puntuacion_pronunciacion"] = 60

        return {
            "resultado": resultado
        }

    except Exception as e:
        print("ERROR PRONUNCIACION:", e)

        return {
            "resultado": {
                "texto_reconocido": texto_reconocido,
                "texto_referencia": texto_referencia,
                "frase_recomendada": texto_referencia,
                "pronunciacion_frase": texto_referencia,
                "comentario_oral": "No se pudo analizar la pronunciación correctamente.",
                "puntuacion_pronunciacion": 60 if texto_reconocido.strip() else 0,
                "palabras_observadas": []
            }
        }