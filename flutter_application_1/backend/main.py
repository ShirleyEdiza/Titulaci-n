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
You are a professional English grammar corrector for beginner A1/A2 students.

Your task is to correct the student's English sentence and explain the errors in Spanish.

IMPORTANT:
Return ONLY valid JSON.
Do not use markdown.
Do not use explanations outside JSON.

Correction rules:
- Correct grammar.
- Correct spelling.
- Correct capitalization.
- Correct punctuation.
- The corrected text must be natural and grammatically correct English.
- Keep the student's original intention.
- If speech-to-text recognized a strange word, infer the most probable word from context.
- If the context is about how the student feels, prefer "day" instead of "dad".
- If the student mentions the name Shirley, correct "Shirly" to "Shirley".
- Do not invent new ideas.
- Do not translate the corrected text into Spanish.
- The field "texto_corregido" must be in English.
- The field "errores_detectados" must be written ONLY in Spanish.
- Use simple Spanish explanations for high school students.
- Do not write errors in English.
- Do not report punctuation errors unless they affect understanding.
- Do not report double periods or extra spaces as important errors.
- The original text must not be modified.
- Only "texto_corregido" should contain the corrected version.
- "errores_detectados" must be written in Spanish.
- Focus on grammar, missing verbs, wrong words, and sentence structure.

Examples:
Original: Hello my name Shirley
Corrected: Hello, my name is Shirley.
Errors:
- Falta el verbo "is" después de "name".
- Falta una coma después de "Hello".

Original: I think my dad is good
Corrected: I think my day is good.
Errors:
- La palabra "dad" no corresponde al contexto; se corrigió por "day".

Original: I like play basketball
Corrected: I like playing basketball.
Errors:
- Después de "like" se debe usar el verbo en gerundio: "playing".

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
You are an English pronunciation evaluator for Spanish-speaking beginner A1/A2 students.

Evaluate ORAL PRACTICE only.

Return ONLY valid JSON.
Do not use markdown.

VERY IMPORTANT:
- Do NOT evaluate grammar.
- Do NOT mark missing words as pronunciation errors.
- If "is" is missing, ignore it for pronunciation.
- If "a" is missing or extra, ignore it for pronunciation.
- If the student says Spanish words like "Hola", "mi", "nombre", explain that the phrase should be said in English.
- If the student says "Hola my name Shirley", oral feedback must mention:
  1. "Hola" should be "Hello"
  2. "my" should sound like "mai"
  3. "name" should sound like "neim"
- If the student says "name" with Spanish pronunciation, mark "name".
- If the student says "my" like Spanish "mi", mark "my".
- If the student says a full sentence in Spanish, give the full English sentence and its pronunciation.
- Do not say everything is correct if the sentence contains Spanish words or common Spanish pronunciation problems.
- Feedback must be in Spanish.
- Use simple pronunciation guides for Spanish speakers.

Student recognized text:
{texto_reconocido}

Correct English reference:
{texto_referencia}

Return exactly this JSON:

{{
  "texto_reconocido": "{texto_reconocido}",
  "texto_referencia": "{texto_referencia}",
  "frase_recomendada": "",
  "pronunciacion_frase": "",
  "puntuacion_pronunciacion": 0,
  "comentario_oral": "",
  "palabras_observadas": [
    {{
      "palabra": "",
      "pronunciacion_correcta": "",
      "explicacion": ""
    }}
  ]
}}

Example:
Student recognized text: Hola my name Shirley
Correct English reference: Hello, my name is Shirley.

Output:
{{
  "texto_reconocido": "Hola my name Shirley",
  "texto_referencia": "Hello, my name is Shirley.",
  "frase_recomendada": "Hello, my name is Shirley.",
  "pronunciacion_frase": "Jelou, mai neim is shér-li.",
  "puntuacion_pronunciacion": 65,
  "comentario_oral": "La idea se entiende, pero mezclaste español con inglés y debes practicar la pronunciación de algunas palabras.",
  "palabras_observadas": [
    {{
      "palabra": "Hello",
      "pronunciacion_correcta": "jelou",
      "explicacion": "En inglés no se debe decir 'Hola', sino 'Hello'."
    }},
    {{
      "palabra": "my",
      "pronunciacion_correcta": "mai",
      "explicacion": "La palabra 'my' se pronuncia 'mai', no como 'mi' en español."
    }},
    {{
      "palabra": "name",
      "pronunciacion_correcta": "neim",
      "explicacion": "La palabra 'name' se pronuncia 'neim', no como se lee en español."
    }}
  ]
}}
"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You evaluate only pronunciation, not grammar. Return only valid JSON."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.1,
            max_tokens=500
        )

        texto_respuesta = response.choices[0].message.content.strip()
        texto_respuesta = texto_respuesta.replace("```json", "")
        texto_respuesta = texto_respuesta.replace("```", "")
        texto_respuesta = texto_respuesta.strip()

        resultado = json.loads(texto_respuesta)

        return {"resultado": resultado}

    except Exception as e:
        print("ERROR PRONUNCIACION:", e)

        return {
            "resultado": {
                "texto_reconocido": texto_reconocido,
                "texto_referencia": texto_referencia,
                "frase_recomendada": texto_referencia,
                "pronunciacion_frase": "",
                "puntuacion_pronunciacion": 0,
                "comentario_oral": "No se pudo analizar la pronunciación.",
                "palabras_observadas": []
            }
        }