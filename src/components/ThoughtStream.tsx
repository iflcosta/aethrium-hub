"use client";

import { useEffect, useRef, useState } from "react";
import { backendApi } from "@/lib/api";

interface ThoughtStreamProps {
  executionId: string | null;
  agentSlug: string;
}

export function ThoughtStream({ executionId, agentSlug }: ThoughtStreamProps) {
  const contentRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  
  const [isStreaming, setIsStreaming] = useState(false);
  const [isDone, setIsDone] = useState(false);
  const [isUrgent, setIsUrgent] = useState(false);
  const [metadata, setMetadata] = useState<{ ts?: string; tokens?: number } | null>(null);
  const [flashColor, setFlashColor] = useState<"green" | "red" | null>(null);

  const [autoScroll, setAutoScroll] = useState(true);

  // Handle scroll detection
  const handleScroll = () => {
    if (!scrollRef.current) return;
    const { scrollTop, scrollHeight, clientHeight } = scrollRef.current;
    
    // If we are within 20px of the bottom, keep auto-scrolling
    const isAtBottom = scrollHeight - scrollTop - clientHeight < 20;
    setAutoScroll(isAtBottom);
  };

  useEffect(() => {
    if (!executionId) {
      if (contentRef.current) contentRef.current.textContent = "";
      setIsStreaming(false);
      setIsDone(false);
      return;
    }

    if (contentRef.current) contentRef.current.textContent = "";
    setIsStreaming(true);
    setIsDone(false);
    setIsUrgent(false);
    setMetadata(null);
    setFlashColor(null);

    const es = backendApi.streamExecution(
      executionId,
      (chunk) => {
        // chunk: { seq, delta, agent, ts }
        if (contentRef.current) {
          contentRef.current.textContent += chunk.delta || "";
        }
        
        // Check for urgent
        if (!isUrgent && chunk.delta && chunk.delta.includes("URGENTE")) {
          setIsUrgent(true);
          setFlashColor("red");
        }

        if (scrollRef.current && autoScroll) {
          scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }

        if (chunk.ts && !metadata) {
          setMetadata({ ts: new Date(chunk.ts).toLocaleTimeString() });
        }
      },
      (delivery) => {
        // Done
        setIsStreaming(false);
        setIsDone(true);
        setFlashColor("green");
        
        setTimeout(() => setFlashColor(null), 1000);
      }
    );

    return () => {
      es.close();
    };
  }, [executionId]);

  let borderColor = "border-[#222222]";
  if (flashColor === "green") borderColor = "border-[#1D9E75] shadow-[0_0_10px_rgba(29,158,117,0.3)]";
  if (flashColor === "red" || isUrgent) borderColor = "border-[#ef4444] shadow-[0_0_10px_rgba(239,68,68,0.3)]";

  return (
    <div className={`relative flex flex-col h-full bg-[#0a0a0a] rounded border transition-all duration-300 ${borderColor}`}>
      {/* Header Badges */}
      <div className="absolute top-2 right-2 flex items-center gap-2 pointer-events-none">
        {isUrgent && (
          <span className="bg-[#ef4444]/20 text-[#ef4444] border border-[#ef4444]/50 px-2 py-0.5 rounded text-[10px] font-bold tracking-wider animate-pulse">
            URGENTE
          </span>
        )}
        {isDone && metadata?.ts && (
          <span className="text-[#888780] text-[10px] font-mono bg-[#111111] border border-[#222222] px-1.5 py-0.5 rounded">
            {metadata.ts}
          </span>
        )}
      </div>

      <div 
        ref={scrollRef}
        onScroll={handleScroll}
        className="flex-1 overflow-y-auto p-3 thought-stream"
      >
        {!executionId && (
          <span className="text-[#888780]/40 text-[11px]">No active execution...</span>
        )}
        
        <div className="text-[11px] leading-5 text-[#ececf1] whitespace-pre-wrap font-mono">
          <span ref={contentRef}></span>
          {isStreaming && (
            <span className="inline-block w-2 h-3 ml-1 align-middle bg-[#a1a1aa] animate-pulse" />
          )}
        </div>
      </div>
    </div>
  );
}
