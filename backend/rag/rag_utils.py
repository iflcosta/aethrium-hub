import os
import json
from langchain_groq import ChatGroq
from langchain_core.messages import SystemMessage, HumanMessage

async def extract_search_queries(prompt: str, history: list, agent_slug: str) -> list[str]:
    """
    Usa um modelo rápido para extrair termos de busca otimizados para o RAG,
    considerando o prompt atual e o histórico recente.
    """
    llm = ChatGroq(
        model="llama-3.1-8b-instant",
        temperature=0.1,
        api_key=os.getenv("GROQ_API_KEY")
    )

    history_str = ""
    for h in history[-3:]: # Pega as últimas 3 interações
        role = "User" if h.get("role") == "user" else "Assistant"
        history_str += f"{role}: {h.get('content', '')[:200]}\n"

    system_prompt = f"""
    Sua tarefa é extrair termos de busca técnicos e específicos para um sistema RAG de desenvolvimento de OTServ.
    O agente atual é: {agent_slug}.
    
    Analise o Histórico e o Prompt e retorne uma lista JSON de até 3 strings de busca curtas e objetivas.
    Exemplo: ["função doPlayerAddItem TFS 1.5", "script de bueiro map design", "configurações de rate exp"]
    
    Responda APENAS o JSON.
    """

    user_content = f"Histórico Recente:\n{history_str}\n\nPrompt Atual: {prompt}"
    
    try:
        response = await llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_content)
        ])
        
        # Tenta extrair o JSON da resposta
        import re
        match = re.search(r"(\[.*\])", response.content, re.DOTALL)
        if match:
            queries = json.loads(match.group(1))
            return queries
    except Exception as e:
        print(f"[RAG_UTILS] Failed to extract queries: {e}")
    
    return [prompt[:100]] # Fallback para o próprio prompt
