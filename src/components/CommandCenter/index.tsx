'use client'

import React, { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Send,
  ChevronRight,
  ChevronLeft,
  ShieldAlert,
  MessageSquare,
  X
} from 'lucide-react'
import { useCommandStore, CommandMode, Message } from '@/store/useCommandStore'
import { backendApi } from '@/lib/api'
import { mockAgents } from "@/lib/mock/agents"
import { AgentAvatar } from "@/components/agent-avatar"
import { cn } from '@/lib/utils'
import ReactMarkdown from 'react-markdown'

// Removed BoldText and replaced with ReactMarkdown

const MessageContent = ({ content }: { content: string }) => {
  const isDelivery = content.includes('[ENTREGA]') || content.includes('[ENTREGA FINAL]')

  return (
    <div className={cn(
      "markdown-content space-y-2",
      isDelivery && "border-l-2 border-purple-500/50 pl-3 py-1 bg-purple-500/5 rounded-r"
    )}>
      <ReactMarkdown
        components={{
          h3: ({ node, ...props }) => <h3 className="text-sm font-bold text-white mt-4 mb-2 first:mt-0" {...props} />,
          strong: ({ node, ...props }) => <strong className="font-bold text-white" {...props} />,
          p: ({ node, ...props }) => <p className="mb-2 last:mb-0 leading-relaxed" {...props} />,
          ul: ({ node, ...props }) => <ul className="list-disc ml-4 mb-3 space-y-1" {...props} />,
          li: ({ node, ...props }) => <li className="text-[11px]" {...props} />,
          code: ({ node, ...props }) => (
            <code className="bg-[#000] px-1.5 py-0.5 rounded text-[10px] font-mono text-purple-300 border border-white/10" {...props} />
          ),
          pre: ({ node, ...props }) => (
            <pre className="bg-[#000] p-3 rounded-lg border border-white/5 my-3 overflow-x-auto text-[11px] font-mono" {...props} />
          )
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  )
}

export const CommandCenter = () => {
  const { 
    isOpen, 
    width, 
    mode, 
    selectedAgent, 
    selectedAgentsForMeeting,
    unreads,
    threads,
    isStreaming,
    toggle,
    setIsOpen,
    setWidth,
    setMode,
    setSelectedAgent,
    toggleAgentForMeeting,
    addMessage,
    updateMessage,
    setActiveExecutionId,
    setIsStreaming,
    getCurrentThread
  } = useCommandStore()

  const [input, setInput] = useState('')
  const [taskTitle, setTaskTitle] = useState('')
  const [taskDescription, setTaskDescription] = useState('')
  const [taskPriority, setTaskPriority] = useState<'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'>('MEDIUM')
  const [meetingTopic, setMeetingTopic] = useState('')
  const scrollRef = useRef<HTMLDivElement>(null)
  const carouselRef = useRef<HTMLDivElement>(null)
  const isResizing = useRef(false)

  // Keyboard Shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key === 'k') {
        e.preventDefault()
        toggle()
      }
      if (e.key === 'Escape' && isOpen) {
        setIsOpen(false)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [toggle, isOpen, setIsOpen])

  // Auto-scroll
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [threads, selectedAgent, isStreaming])

  // Resizing logic
  const handleMouseDown = (e: React.MouseEvent) => {
    isResizing.current = true
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
    e.preventDefault()
  }

  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (!isResizing.current) return
    const newWidth = window.innerWidth - e.clientX
    setWidth(newWidth)
  }, [setWidth])

  const handleMouseUp = useCallback(() => {
    isResizing.current = false
    document.removeEventListener('mousemove', handleMouseMove)
    document.removeEventListener('mouseup', handleMouseUp)
  }, [])

  const handleSend = async () => {
    console.log('Sending message - Input:', input, 'SelectedAgent:', selectedAgent)
    
    if (!input.trim()) return
    if (!selectedAgent) {
      console.warn('No agent selected! Aborting send.')
      return
    }
    if (isStreaming) return

    const userMsg: Message = {
      id: crypto.randomUUID(),
      agentSlug: 'user',
      content: input,
      timestamp: new Date(),
      type: 'message'
    }

    addMessage(selectedAgent, userMsg)
    const prompt = input
    setInput('')
    setIsStreaming(true)

    console.log('Calling backendApi.runAgent with slug:', selectedAgent)
    try {
      const taskId = `chat-${crypto.randomUUID()}`
      console.log('Generated taskId:', taskId)
      
      // Prepare history for memory (Part 8)
      const currentThread = threads[selectedAgent] || []
      const history = currentThread.slice(-10).map(m => ({
        role: m.agentSlug === 'user' ? 'user' : 'assistant',
        content: m.content
      }))

      const { execution_id } = await backendApi.runAgent(selectedAgent, {
        task_id: taskId,
        prompt: prompt,
        context: {
          history: history,
          project_slug: "baiak-thunder-86",
        }
      })

      setActiveExecutionId(execution_id)

      const gentId = "agent-" + Math.random().toString(36)
      addMessage(selectedAgent, {
        id: gentId,
        agentSlug: selectedAgent,
        content: '',
        timestamp: new Date(),
        type: 'message'
      })

      let fullResponse = ''
      console.log(`[DEBUG] Starting stream for ${execution_id}`)
      backendApi.streamExecution(
        execution_id,
        (chunk) => {
          console.log(`[DEBUG] Received chunk for ${execution_id}:`, chunk)
          fullResponse += chunk.delta || ''
          updateMessage(selectedAgent, gentId, { content: fullResponse })
        },
        (delivery, handoff) => {
          console.log(`[DEBUG] Stream done for ${execution_id}`, handoff ? `→ handoff to ${handoff.to}` : '')
          setIsStreaming(false)
          setActiveExecutionId(null)

          if (delivery) {
            addMessage(selectedAgent, {
              id: "delivery-" + Math.random().toString(36),
              agentSlug: selectedAgent,
              content: delivery,
              timestamp: new Date(),
              type: 'delivery'
            })
          }

          // Auto-follow handoff (e.g. Rafael → Sophia)
          if (handoff) {
            const fromAgent = selectedAgent
            const toAgent = handoff.to

            // Handoff notice in current thread
            addMessage(fromAgent, {
              id: "handoff-" + Math.random().toString(36),
              agentSlug: fromAgent,
              content: `↪ Handoff automático para **${toAgent}** para QA`,
              timestamp: new Date(),
              type: 'handoff'
            })

            // Switch to target agent and start streaming
            setSelectedAgent(toAgent)
            setIsStreaming(true)
            const sophiaId = "agent-" + Math.random().toString(36)
            addMessage(toAgent, {
              id: sophiaId,
              agentSlug: toAgent,
              content: '',
              timestamp: new Date(),
              type: 'message'
            })

            let sophiaResponse = ''
            backendApi.streamExecution(
              handoff.execution_id,
              (chunk) => {
                sophiaResponse += chunk.delta || ''
                updateMessage(toAgent, sophiaId, { content: sophiaResponse })
              },
              (sophiaDelivery) => {
                setIsStreaming(false)
                if (sophiaDelivery) {
                  addMessage(toAgent, {
                    id: "delivery-" + Math.random().toString(36),
                    agentSlug: toAgent,
                    content: sophiaDelivery,
                    timestamp: new Date(),
                    type: 'delivery'
                  })
                }
              }
            )
          }
        }
      )
    } catch (err) {
      console.error(err)
      setIsStreaming(false)
    }
  }

  const handleCreateTask = async () => {
    if (!taskTitle.trim() || !selectedAgent) return
    
    try {
      await backendApi.createTask({
        title: taskTitle,
        description: taskDescription,
        owner_slug: selectedAgent,
        priority: taskPriority,
        context: {}
      })

      const taskMsg: Message = {
        id: crypto.randomUUID(),
        agentSlug: 'user',
        content: `/task ${taskTitle} [${taskPriority}]\n${taskDescription}`,
        timestamp: new Date(),
        type: 'message'
      }
      addMessage(selectedAgent, taskMsg)
      setTaskTitle('')
      setTaskDescription('')
      setMode('dm')
    } catch (err) {
      console.error('Failed to create task:', err)
    }
  }

  const handleStartMeeting = async () => {
    if (!meetingTopic.trim()) return
    try {
      await backendApi.startMeeting({
          topic: meetingTopic,
          agent_slugs: selectedAgentsForMeeting,
          context: {}
      })
      setMeetingTopic('')
      setMode('dm')
      setSelectedAgent('carlos')
      addMessage('carlos', {
        id: Math.random().toString(36),
        agentSlug: 'user',
        content: `Reunião iniciada: ${meetingTopic}`,
        timestamp: new Date(),
        type: 'message'
      })
    } catch (err) {
      console.error(err)
    }
  }

  const thread = getCurrentThread()

  return (
    <AnimatePresence>
      <div 
        key="cc-trigger"
        onClick={toggle}
        className="fixed right-0 top-1/2 -translate-y-1/2 w-6 h-20 bg-[#1a1a1a] border-l border-[#222] border-y rounded-l-md cursor-pointer z-[45] flex flex-col items-center justify-center hover:bg-[#222] transition-colors group"
      >
        <MessageSquare size={14} className="text-[#555] group-hover:text-purple-400" />
        <span className="text-[9px] font-mono text-[#555] group-hover:text-purple-400 rotate-90 mt-2">CC</span>
      </div>

      {isOpen && (
        <motion.div
          key="cc-panel"
          initial={{ x: '100%' }}
          animate={{ x: 0 }}
          exit={{ x: '100%' }}
          transition={{ type: 'spring', damping: 25, stiffness: 200 }}
          style={{ width: `${width}px` }}
          className="fixed right-0 top-0 h-screen bg-[#111111] border-l border-[#222222] z-50 flex flex-col shadow-2xl"
        >
          {/* Resize Handle */}
          <div 
            onMouseDown={handleMouseDown}
            className="absolute left-[-4px] top-0 w-2 h-full cursor-col-resize hover:bg-purple-500/20 z-10"
          />

          {/* Header */}
          <div className="h-12 border-b border-[#222] flex items-center justify-between px-4 shrink-0">
            <span className="text-[10px] font-mono text-[#555] tracking-widest uppercase">Command Center</span>
            <div className="flex bg-[#0a0a0a] rounded-full p-0.5 border border-[#222]">
              {(['dm', 'task', 'meeting'] as CommandMode[]).map((m) => (
                <button
                  key={m}
                  onClick={() => setMode(m)}
                  className={cn(
                    "px-2.5 py-1 rounded-full text-[10px] uppercase font-bold transition-all",
                    mode === m ? "bg-[#1a1a1a] text-purple-400" : "text-[#444] hover:text-[#777]"
                  )}
                >
                  {m === 'meeting' ? 'reunião' : m}
                </button>
              ))}
            </div>
            <button onClick={toggle} className="text-[#444] hover:text-[#fff]">
              <X size={16} />
            </button>
          </div>

          {/* Mode-Specific Area */}
          <div className="shrink-0 border-b border-[#222] bg-[#0d0d0d]">
            {mode === 'dm' && (
              <div className="p-2 relative group">
                <div className="relative flex items-center">
                  <button 
                    onClick={() => {
                      if (carouselRef.current) carouselRef.current.scrollBy({ left: -120, behavior: 'smooth' })
                    }}
                    className="absolute left-0 z-10 p-1.5 bg-[#111]/90 rounded-full border border-[#333] text-[#777] hover:text-white opacity-40 group-hover:opacity-100 transition-opacity flex items-center justify-center shadow-lg"
                  >
                    <ChevronLeft size={14} />
                  </button>
                  
                  <div 
                    ref={carouselRef}
                    className="flex overflow-x-auto gap-2 pb-2 scrollbar-none no-scrollbar scroll-smooth snap-x"
                  >
                    {mockAgents.map(a => (
                      <button
                        key={a.slug}
                        onClick={() => setSelectedAgent(a.slug)}
                        className={cn(
                          "relative flex flex-col items-center shrink-0 p-2 rounded-lg border border-transparent transition-all snap-start",
                          selectedAgent === a.slug ? "bg-[#1a1a1a] border-[#222]" : "hover:bg-[#1a1a1a]/50"
                        )}
                      >
                        <div className="relative">
                          <AgentAvatar 
                            name={a.displayName} 
                            color={a.color}
                            size="sm" 
                            isOnline={a.isOnline}
                            className={selectedAgent === a.slug ? `ring-1 ring-offset-2 ring-offset-[#1a1a1a] ring-purple-500` : ''} 
                          />
                          {unreads[a.slug] && (
                            <div className="absolute -top-0.5 -right-0.5 w-2 h-2 bg-white rounded-full border border-[#111]" />
                          )}
                        </div>
                        <span className="text-[10px] mt-1 text-[#555]">{a.displayName}</span>
                      </button>
                    ))}
                  </div>

                  <button 
                    onClick={() => {
                      if (carouselRef.current) carouselRef.current.scrollBy({ left: 120, behavior: 'smooth' })
                    }}
                    className="absolute right-0 z-10 p-1.5 bg-[#111]/90 rounded-full border border-[#333] text-[#777] hover:text-white opacity-40 group-hover:opacity-100 transition-opacity flex items-center justify-center shadow-lg"
                  >
                    <ChevronRight size={14} />
                  </button>
                </div>
                {selectedAgent && (
                  <div className="px-2 pb-2 text-[11px] text-[#444]">
                    Conversando com <span className="text-purple-400">{mockAgents.find(a => a.slug === selectedAgent)?.displayName}</span>
                  </div>
                )}
              </div>
            )}

            {mode === 'task' && (
              <div className="p-4 space-y-3">
                <input 
                  placeholder="Título da Task..."
                  value={taskTitle}
                  onChange={e => setTaskTitle(e.target.value)}
                  className="w-full bg-[#0a0a0a] border border-[#222] rounded px-3 py-1.5 text-xs text-[#eee] focus:outline-none focus:border-purple-500"
                />
                <div className="space-y-1">
                  <label className="text-[10px] text-[#444] uppercase font-bold ml-1">Descrição</label>
                  <textarea 
                    placeholder="Descreva brevemente o que precisa ser feito..."
                    value={taskDescription}
                    onChange={e => setTaskDescription(e.target.value)}
                    rows={3}
                    className="w-full bg-[#0a0a0a] border border-[#222] rounded px-3 py-1.5 text-xs text-[#eee] focus:outline-none focus:border-purple-500 resize-none"
                  />
                </div>
                <div className="flex gap-2">
                  <select 
                    value={selectedAgent || ''} 
                    onChange={e => setSelectedAgent(e.target.value)}
                    className="flex-1 bg-[#0a0a0a] border border-[#222] rounded px-2 py-1.5 text-xs text-[#777]"
                  >
                    <option value="">Atribuir a...</option>
                    {mockAgents.map(a => <option key={a.slug} value={a.slug}>{a.displayName}</option>)}
                  </select>
                  {(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as const).map(p => (
                    <button
                      key={p}
                      onClick={() => setTaskPriority(p)}
                      className={cn(
                        "px-2 py-1 rounded text-[9px] font-bold border",
                        taskPriority === p ? "border-amber-500/50 bg-amber-500/10 text-amber-500" : "border-[#222] text-[#444]"
                      )}
                    >
                      {p[0]}
                    </button>
                  ))}
                </div>
                <button 
                  onClick={handleCreateTask}
                  className="w-full bg-purple-600 hover:bg-purple-700 text-white rounded py-1.5 text-xs font-bold transition-colors"
                >
                  Criar Task →
                </button>
              </div>
            )}

            {mode === 'meeting' && (
              <div className="p-4 space-y-3">
                <input 
                  placeholder="Tema da reunião..."
                  value={meetingTopic}
                  onChange={e => setMeetingTopic(e.target.value)}
                  className="w-full bg-[#0a0a0a] border border-[#222] rounded px-3 py-1.5 text-xs text-[#eee] focus:outline-none focus:border-purple-500"
                />
                <div className="grid grid-cols-2 gap-2 text-[11px] text-[#555]">
                  {mockAgents.map(a => (
                    <label key={a.slug} className="flex items-center gap-2 cursor-pointer">
                      <input 
                        type="checkbox" 
                        checked={selectedAgentsForMeeting.includes(a.slug)}
                        disabled={a.slug === 'carlos'}
                        onChange={() => toggleAgentForMeeting(a.slug)}
                        className="rounded border-[#222] bg-[#0a0a0a] text-purple-600"
                      />
                      <span className={selectedAgentsForMeeting.includes(a.slug) ? "text-purple-400" : ""}>{a.displayName}</span>
                    </label>
                  ))}
                </div>
                <button 
                   onClick={handleStartMeeting}
                   className="w-full bg-teal-600 hover:bg-teal-700 text-white rounded py-1.5 text-xs font-bold transition-colors"
                >
                  Iniciar Reunião →
                </button>
              </div>
            )}
          </div>

          {/* Thread Area */}
          <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4 no-scrollbar">
            {thread.map((msg, idx) => {
              const isUser = msg.agentSlug === 'user'
              const agent = mockAgents.find(a => a.slug === msg.agentSlug)
              const msgKey = msg.id || `msg-${idx}`

              if (msg.type === 'handoff') {
                return (
                  <div key={msgKey} className="bg-amber-500/10 border-y border-amber-500/20 py-1.5 px-4 -mx-4 text-[11px] text-amber-500 text-center font-mono italic">
                    {msg.content}
                  </div>
                )
              }

              if (msg.type === 'urgent') {
                return (
                  <div key={msgKey} className="bg-red-500/10 border-y border-red-500/20 py-2 px-4 -mx-4 flex items-center gap-2 text-[11px] text-red-500 font-bold uppercase tracking-tight">
                    <ShieldAlert size={14} /> ⚠ URGENTE: {msg.content}
                  </div>
                )
              }

              if (msg.type === 'delivery') {
                return (
                   <div key={msgKey} className="space-y-3 py-2">
                     <div className="flex items-center gap-4">
                       <div className="flex-1 h-px bg-gradient-to-r from-transparent via-purple-500/30 to-transparent" />
                       <span className="text-[9px] uppercase font-bold text-purple-400 tracking-[0.3em] whitespace-nowrap">Entrega Final</span>
                       <div className="flex-1 h-px bg-gradient-to-r from-transparent via-purple-500/30 to-transparent" />
                     </div>
                     <div className="border-l-2 border-purple-500 bg-purple-500/5 p-4 rounded-r-lg text-[12px] leading-relaxed text-[#bbb] shadow-inner shadow-purple-500/5">
                       <MessageContent content={msg.content} />
                     </div>
                   </div>
                )
              }

              return (
                <div key={msgKey} className={cn("flex flex-col", isUser ? "items-end" : "items-start")}>
                  <div className="flex items-center gap-2 mb-1">
                    {!isUser && (
                      <div className={cn("w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold text-black")} style={{ backgroundColor: agent?.color ? agent.color : '#888' }}>
                        {agent?.displayName[0]}
                      </div>
                    )}
                    <span className="text-[10px] font-bold text-[#555] uppercase">{isUser ? 'VOCÊ' : agent?.displayName}</span>
                    <span className="text-[9px] text-[#333]">{new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                  </div>
                  <div 
                    className={cn(
                      "max-w-[90%] px-3 py-2 rounded-lg text-xs leading-relaxed transition-all",
                      isUser 
                        ? "bg-purple-600 text-white rounded-tr-none" 
                        : "bg-[#1a1a1a] text-[#aaa] rounded-tl-none border border-[#222] hover:border-[#333]"
                    )}
                    style={!isUser ? { borderLeft: `3px solid ${agent?.color || '#333'}` } : {}}
                  >
                    <MessageContent content={msg.content} />
                  </div>
                </div>
              )
            })}
            
            {isStreaming && (
              <div className="text-[10px] text-[#444] italic flex items-center gap-2">
                {mockAgents.find(a => a.slug === selectedAgent)?.displayName} está processando
                <span className="flex gap-0.5">
                  <span className="animate-bounce">●</span>
                  <span className="animate-bounce delay-75">●</span>
                  <span className="animate-bounce delay-150">●</span>
                </span>
              </div>
            )}
          </div>

          {/* Input Area */}
          <div className="p-4 border-t border-[#222] bg-[#0d0d0d]">
            <div className="relative">
              <input
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && !e.shiftKey && handleSend()}
                placeholder="Enviar mensagem... (ou /slash commands)"
                className="w-full bg-[#0a0a0a] border border-[#222] rounded-lg pl-3 pr-10 py-2.5 text-[13px] font-mono text-[#eee] focus:outline-none focus:border-purple-500 transition-colors"
                disabled={!selectedAgent || isStreaming}
              />
              <button 
                onClick={handleSend}
                disabled={!input.trim() || isStreaming || !selectedAgent}
                className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 bg-purple-600 rounded text-white hover:bg-purple-700 disabled:bg-[#1a1a1a] disabled:text-[#444] transition-colors"
              >
                <Send size={14} />
              </button>
            </div>
            <div className="mt-2 text-[9px] font-mono text-[#444] flex gap-3 uppercase">
              <span>/dm</span>
              <span>/task</span>
              <span>/meeting</span>
              <span>/clear</span>
              <span>/urgent</span>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
