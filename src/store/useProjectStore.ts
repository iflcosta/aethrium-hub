import { create } from 'zustand'

export interface ActiveProject {
  slug: string
  displayName: string
  gameType: string
  division: string
  engine: string
  language: string
  isActive: boolean
}

interface ProjectState {
  activeProject: ActiveProject | null
  projects: ActiveProject[]
  isLoading: boolean

  setActiveProject: (project: ActiveProject) => void
  setProjects: (projects: ActiveProject[]) => void
  setIsLoading: (val: boolean) => void
}

const STORAGE_KEY = 'aethrium-active-project'

function loadPersistedProject(): ActiveProject | null {
  if (typeof window === 'undefined') return null
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export const useProjectStore = create<ProjectState>((set) => ({
  activeProject: loadPersistedProject(),
  projects: [],
  isLoading: false,

  setActiveProject: (project) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(project))
    }
    set({ activeProject: project })
  },

  setProjects: (projects) => set({ projects }),
  setIsLoading: (isLoading) => set({ isLoading }),
}))
