import { NextResponse } from "next/server";
import { mockTasks } from "@/lib/mock/tasks";

export async function GET() {
  return NextResponse.json(mockTasks);
}
