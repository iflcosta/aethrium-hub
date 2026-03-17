import { create } from 'zustand'

export type MessageType = 'message' | 'handoff' | 'urgent' | 'delivery' | 'typing'

export interface Message {
  id: string
  agentSlug: string | 'user'
  content: string
  timestamp: Date
  type: MessageType
}

export type CommandMode = 'dm' | 'task' | 'meeting'

interface CommandState {
  isOpen: boolean
  width: number
  mode: CommandMode
  selectedAgent: string | null
  selectedAgentsForMeeting: string[]
  threads: Record<string, Message[]>
  unreads: Record<string, boolean>
  activeExecutionId: string | null
  isStreaming: boolean

  // Actions
  toggle: () => void
  setIsOpen: (val: boolean) => void
  setWidth: (w: number) => void
  setMode: (mode: CommandMode) => void
  setSelectedAgent: (slug: string | null) => void
  toggleAgentForMeeting: (slug: string) => void
  addMessage: (agentSlug: string, msg: Message) => void
  updateMessage: (agentSlug: string, id: string, updates: Partial<Message>) => void
  clearThread: (agentSlug: string) => void
  setActiveExecutionId: (id: string | null) => void
  setIsStreaming: (val: boolean) => void
  getCurrentThread: () => Message[]
}

const STORAGE_KEY_WIDTH = 'command-center-width'

export const useCommandStore = create<CommandState>((set, get) => ({
  isOpen: false,
  width: typeof window !== 'undefined' ? Number(localStorage.getItem(STORAGE_KEY_WIDTH)) || 320 : 320,
  mode: 'dm',
  selectedAgent: 'carlos',
  selectedAgentsForMeeting: ['carlos'],
  threads: {},
  unreads: {},
  activeExecutionId: null,
  isStreaming: false,

  toggle: () => set((state) => ({ isOpen: !state.isOpen })),
  setIsOpen: (isOpen) => set({ isOpen }),
  setWidth: (width) => {
    const clampedWidth = Math.min(Math.max(width, 260), 600)
    localStorage.setItem(STORAGE_KEY_WIDTH, String(clampedWidth))
    set({ width: clampedWidth })
  },
  setMode: (mode) => set({ mode }),
  setSelectedAgent: (slug) => {
    set((state) => ({ 
      selectedAgent: slug,
      unreads: { ...state.unreads, [slug || '']: false } // Clear unread when selected
    }))
  },
  toggleAgentForMeeting: (slug) => set((state) => {
    if (slug === 'carlos') return state
    const current = state.selectedAgentsForMeeting
    if (current.includes(slug)) {
      return { selectedAgentsForMeeting: current.filter(s => s !== slug) }
    }
    return { selectedAgentsForMeeting: [...current, slug] }
  }),
  addMessage: (agentSlug, msg) => set((state) => {
    const thread = state.threads[agentSlug] || []
    const isCurrent = state.selectedAgent === agentSlug
    return {
      threads: { ...state.threads, [agentSlug]: [...thread, msg] },
      unreads: { 
        ...state.unreads, 
        [agentSlug]: isCurrent ? false : (msg.agentSlug !== 'user') 
      }
    }
  }),
  updateMessage: (agentSlug, id, updates) => set((state) => {
    const thread = state.threads[agentSlug] || []
    return {
      threads: {
        ...state.threads,
        [agentSlug]: thread.map(m => m.id === id ? { ...m, ...updates } : m)
      }
    }
  }),
  clearThread: (agentSlug) => set((state) => ({
    threads: { ...state.threads, [agentSlug]: [] }
  })),
  setActiveExecutionId: (activeExecutionId) => set({ activeExecutionId }),
  setIsStreaming: (isStreaming) => set({ isStreaming }),
  getCurrentThread: () => {
    const state = get()
    return state.threads[state.selectedAgent || ''] || []
  }
}))
