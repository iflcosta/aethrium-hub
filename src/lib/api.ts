console.log('BACKEND_URL:', process.env.NEXT_PUBLIC_BACKEND_URL)
export const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8001'

export const backendApi = {
  runAgent: async (slug: string, body: { task_id: string, prompt: string, context: object }) => {
    const url = `${BACKEND_URL}/agents/${slug}/run`
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      })
      if (!response.ok) {
        const errorText = await response.text()
        console.error(`Backend error (${response.status}):`, errorText)
        throw new Error(`Agent run failed: ${response.statusText}`)
      }
      return await response.json()
    } catch (err) {
      console.error('Fetch error details:', err)
      console.error('URL attempted:', url)
      throw err
    }
  },

  streamExecution: (
    executionId: string,
    onChunk: (chunk: any) => void,
    onDone: (delivery: string, handoff?: { to: string; execution_id: string; task_id: string }) => void
  ) => {
    const es = new EventSource(`${BACKEND_URL}/stream/${executionId}`)
    es.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data)
        if (data.type === 'done') {
          onDone(data.final_delivery, data.handoff ?? undefined)
          es.close()
        } else {
          onChunk(data)
        }
      } catch (err) {
        console.error("Error parsing stream chunk", err)
      }
    }
    es.onerror = () => es.close()
    return es
  },

  startMeeting: (body: { topic: string, agent_slugs: string[], context: object }) =>
    fetch(`${BACKEND_URL}/agents/meeting/start`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(r => r.json()),

  sendMeetingMessage: (body: { task_id: string, message: string }) =>
    fetch(`${BACKEND_URL}/agents/meeting/message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(r => r.json()),
  createTask: (body: { 
    title: string, 
    description: string, 
    owner_slug: string, 
    priority: string, 
    context: object 
  }) =>
    fetch(`${BACKEND_URL}/tasks/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(r => r.json()),

  indexProject: (project_slug: string, project_path: string) =>
    fetch(`${BACKEND_URL}/projects/index`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ project_slug, project_path })
    }).then(r => r.json()),

  getProjectStatus: (project_slug: string) =>
    fetch(`${BACKEND_URL}/projects/index/${project_slug}/status`)
      .then(r => r.json()),

  queryRAG: (query: string, project_slug: string) =>
    fetch(`${BACKEND_URL}/projects/query`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, project_slug, top_k: 5 })
    }).then(r => r.json()),

  deleteProjectIndex: (project_slug: string) =>
    fetch(`${BACKEND_URL}/projects/${project_slug}/index`, {
      method: 'DELETE'
    }).then(r => r.json()),

  getAgents: () =>
    fetch(`${BACKEND_URL}/agents/`)
      .then(r => r.json()),

  updateAgentModel: (slug: string, model: string) =>
    fetch(`${BACKEND_URL}/agents/${slug}/model`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model })
    }).then(r => r.json()),
}
