import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/sidebar";
import { CommandCenter } from "@/components/CommandCenter";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Aethrium Hub — Game Studio",
  description: "AI-powered game development studio & publisher",
  icons: {
    icon: "/favicon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} antialiased bg-[#0a0a0a] text-[#e5e5e5]`}>
        <Sidebar />
        <main className="md:ml-60 min-h-screen pt-14 md:pt-0">
          <div className="p-4 md:p-6 max-w-[1400px]">
            {children}
          </div>
        </main>
        <CommandCenter />
      </body>
    </html>
  );
}
