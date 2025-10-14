from fastapi import FastAPI
from pydantic import BaseModel
import os
from autogen import ConversableAgent
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
load_dotenv()

agente_nutricionista = FastAPI()

class Mensagem(BaseModel):
    mensagem: str

def criar_agent_nutricionista():
    agente_nutri = ConversableAgent(
        name='Agente1',
        system_message=(
            'Você vai responder sempre no idioma Português e será um nutricionista especializado em pessoas com diabetes e em criar um plano de alimentação para elas. '
            'Você vai responder sempre de forma clara e objetiva.'
            'Você vai responder sempre de forma profissional e com empatia.'
            'Caso o usuário solicite algo que não esteja relacionado à nutrição, você vai redirecionar a conversa para o tema de nutrição.'
            'E vai responder sempre no Idioma Português.'
        ),
        llm_config={
            "model": "openai/gpt-oss-120b",  # ou outro modelo disponível
            "api_key": os.getenv("GROQ_API_KEY"),
            "api_type": "groq",
            "temperature": 0.2
        },
    )
    return agente_nutri

def conversar_agent_nutricionista(agent, mensagem):
    resposta = agent.generate_reply(messages=[{"role": "user", "content": mensagem}])
    return resposta

@agente_nutricionista.post("/conversa")
def conversar(mensagem: Mensagem):
    agent = criar_agent_nutricionista()
    resposta = conversar_agent_nutricionista(agent, mensagem.mensagem)
    return {"resposta": resposta['content']}

@agente_nutricionista.get("/")
def root():
    return {"mensagem": "API do Agente Nutricionista está ativa!"}

agente_nutricionista.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ou especifique ["http://localhost:PORTA_DO_FLUTTER"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)