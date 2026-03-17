import { create } from "zustand";
import { Agent } from "@prisma/client";

interface AgentState {
  agents: Agent[];
  isLoading: boolean;
  error: string | null;
  setAgents: (agents: Agent[]) => void;
  setLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  fetchAgents: () => Promise<void>;
}

export const useAgentStore = create<AgentState>((set) => ({
  agents: [],
  isLoading: false,
  error: null,
  setAgents: (agents) => set({ agents }),
  setLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),
  fetchAgents: async () => {
    set({ isLoading: true, error: null });
    try {
      const response = await fetch("/api/agents");
      if (!response.ok) {
        throw new Error("Failed to fetch agents");
      }
      const data = await response.json();
      set({ agents: data, isLoading: false });
    } catch (error) {
      set({ error: (error as Error).message, isLoading: false });
    }
  },
}));
