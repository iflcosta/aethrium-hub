import os
import json
import re
from langchain_groq import ChatGroq
from langchain_core.messages import SystemMessage, HumanMessage

async def lint_cpp_engine(code: str, context: dict) -> dict:
    """
    Simula uma verificação de sintaxe e padrões C++ específicos do TFS Engine.
    Útil quando não há um compilador real no ambiente.
    """
    llm = ChatGroq(
        model="llama-3.1-8b-instant",
        temperature=0.1,
        api_key=os.getenv("GROQ_API_KEY")
    )
    
    tfs_version = context.get("tfs_version", "Desconhecida")
    
    system_prompt = f"""
    Você é um validador de código C++ especializado na engine TFS (The Forgotten Server).
    A versão alvo é: {tfs_version}.
    
    Analise o código C++ fornecido em busca de:
    1. Erros de sintaxe óbvios.
    2. Padrões de API incorretos para a versão {tfs_version} (ex: usar IOLoginData em versões muito antigas).
    3. Memory leaks comuns (new sem delete ou falta de smart pointers).
    4. Falta de registros em Lua (se for uma nova função).
    
    Responda em formato JSON:
    {{
        "status": "pass" | "fail",
        "warnings": ["string"],
        "errors": ["string"],
        "suggestions": ["string"]
    }}
    
    Seja técnico e direto. Responda APENAS o JSON.
    """

    try:
        response = await llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=f"Código para validar:\n\n{code}")
        ])
        
        match = re.search(r"(\{.*\})", response.content, re.DOTALL)
        if match:
            return json.loads(match.group(1))
    except Exception as e:
        print(f"[VIKTOR_TOOLS] Lint failed: {e}")
    
    return {"status": "error", "message": "Falha na validação remota"}
