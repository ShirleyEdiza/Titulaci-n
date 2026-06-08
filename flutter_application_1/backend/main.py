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
        "This is an A1/A2 English speaking practice. "
        "Common phrases include: Hello, my name is Shirley, "
        "I think my day is good, I like basketball, "
        "my favorite food is tuna, I am from Ecuador. "
        "Prefer 'day' over 'dad' when the context is about feelings or daily routine. "
        "Prefer 'Shirley' as a proper name."
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
You are an English pronunciation evaluator for beginner A1/A2 students.

Your task is to evaluate ORAL PRACTICE, not grammar.

Return ONLY valid JSON.
Do not use markdown.
Do not write explanations outside JSON.

VERY IMPORTANT RULES:
- Do NOT evaluate grammar.
- Do NOT mark missing words as pronunciation errors.
- Do NOT mark "is", "am", "are", "the", "a" as pronunciation problems if they are missing.
- If a word is missing, ignore it in oral feedback because that belongs to written grammar feedback.
- Only evaluate words or phrases that the student actually said.
- If the student said a sentence in Spanish, translate the complete idea into simple English and give the complete English pronunciation guide.
- If the student mixed Spanish and English, identify the Spanish parts and provide the correct English phrase.
- If the recognized text contains "mi name", understand it as the student tried to say "my name".
- If the recognized text contains "name" but the student may have pronounced it like Spanish "name", mark "name" as a word to practice.
- If the recognized text contains "my" but it may sound like Spanish "mi", mark "my" as a word to practice.
- If the recognized text contains "day" or the context says "I think my day is good", do not confuse it with "dad".
- If the recognized text contains "dad" but the context is about routine or feelings, suggest "day".
- Focus on useful pronunciation practice, not on minor punctuation or grammar.
- Feedback must be in Spanish.
- Pronunciation guide must be simple for Spanish-speaking students.
- Use pronunciation guides like: my = "mai", name = "neim", day = "dei", Shirley = "shér-li".
- Maximum 4 observed items.
- If pronunciation seems acceptable, return an empty list in "palabras_observadas" and a positive comment.

Student recognized text:
{texto_reconocido}

Correct grammar/reference text:
{texto_referencia}

Return exactly this JSON:

{{
  "texto_reconocido": "",
  "texto_referencia": "",
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

Examples:

Example 1:
Student recognized text: My name Shirley
Correct grammar/reference text: My name is Shirley
Expected idea:
- Do not mark "is" as pronunciation error.
- This is a grammar omission, not pronunciation.
- If useful, practice the full phrase.

Output:
{{
  "texto_reconocido": "My name Shirley",
  "texto_referencia": "My name is Shirley",
  "frase_recomendada": "My name is Shirley.",
  "pronunciacion_frase": "Mai neim is shér-li.",
  "puntuacion_pronunciacion": 80,
  "comentario_oral": "La pronunciación general es comprensible. Practica la frase completa para decirla con mayor naturalidad.",
  "palabras_observadas": [
    {{
      "palabra": "name",
      "pronunciacion_correcta": "neim",
      "explicacion": "La palabra 'name' no se pronuncia como se lee en español; se pronuncia 'neim'."
    }}
  ]
}}

Example 2:
Student recognized text: Mi nombre es Shirley
Correct grammar/reference text: My name is Shirley
Expected idea:
- Student used Spanish.
- Provide English sentence and pronunciation.

Output:
{{
  "texto_reconocido": "Mi nombre es Shirley",
  "texto_referencia": "My name is Shirley",
  "frase_recomendada": "My name is Shirley.",
  "pronunciacion_frase": "Mai neim is shér-li.",
  "puntuacion_pronunciacion": 55,
  "comentario_oral": "La idea fue expresada en español. Para practicar speaking, intenta decir la frase completa en inglés.",
  "palabras_observadas": [
    {{
      "palabra": "My name is Shirley",
      "pronunciacion_correcta": "Mai neim is shér-li",
      "explicacion": "Practica la oración completa en inglés para responder correctamente."
    }}
  ]
}}

Example 3:
Student recognized text: I think my dad is good
Correct grammar/reference text: I think my day is good
Expected idea:
- In this context, correct probable word is day.
- Practice day.

Output:
{{
  "texto_reconocido": "I think my dad is good",
  "texto_referencia": "I think my day is good",
  "frase_recomendada": "I think my day is good.",
  "pronunciacion_frase": "Ai think mai dei is gud.",
  "puntuacion_pronunciacion": 70,
  "comentario_oral": "La frase se entiende, pero la palabra 'day' debe pronunciarse claramente.",
  "palabras_observadas": [
    {{
      "palabra": "day",
      "pronunciacion_correcta": "dei",
      "explicacion": "La palabra 'day' se pronuncia 'dei'. Evita que suene como 'dad'."
    }}
  ]
}}
"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You evaluate oral English pronunciation for Spanish-speaking "
                        "A1/A2 students. You must not evaluate grammar. Return only valid JSON."
                    )
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.1,
            max_tokens=450
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
                "frase_recomendada": texto_referencia,
                "pronunciacion_frase": "",
                "puntuacion_pronunciacion": 0,
                "comentario_oral": "No se pudo analizar la pronunciación.",
                "palabras_observadas": []
            }
        }