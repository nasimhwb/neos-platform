"use client";

import { Bell, Moon, Sun, Search, User } from "lucide-react";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";

interface HeaderProps {
  title: string;
  subtitle?: string;
}

export function Header({ title, subtitle }: HeaderProps) {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [time, setTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    setMounted(true);
    const timer = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="flex items-center justify-between px-6 py-3 border-b border-border bg-card/50 backdrop-blur-sm flex-shrink-0">
      {/* Left: Title */}
      <div>
        <h1 className="text-lg font-semibold text-foreground">{title}</h1>
        {subtitle && <p className="text-xs text-muted-foreground">{subtitle}</p>}
      </div>

      {/* Right: Controls */}
      <div className="flex items-center gap-2">
        {/* Server Time */}
        <span className="text-xs text-muted-foreground font-mono hidden sm:block mr-2">{time}</span>

        {/* Search */}
        <button className="flex items-center gap-2 px-3 py-1.5 text-xs text-muted-foreground bg-muted/50 rounded-md border border-border hover:border-border/80 transition-colors">
          <Search className="w-3.5 h-3.5" />
          <span className="hidden md:block">Search...</span>
          <kbd className="hidden md:inline-flex items-center gap-1 px-1.5 py-0.5 text-[10px] font-mono bg-background border border-border rounded">
            ⌘K
          </kbd>
        </button>

        {/* Alerts */}
        <button className="relative p-2 rounded-md hover:bg-muted/50 transition-colors">
          <Bell className="w-4 h-4 text-muted-foreground" />
          <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 rounded-full bg-amber-500" />
        </button>

        {/* Theme toggle */}
        {mounted && (
          <button
            onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
            className="p-2 rounded-md hover:bg-muted/50 transition-colors"
          >
            {theme === "dark"
              ? <Sun className="w-4 h-4 text-muted-foreground" />
              : <Moon className="w-4 h-4 text-muted-foreground" />}
          </button>
        )}

        {/* User avatar */}
        <button className="flex items-center gap-2 pl-2 pr-3 py-1.5 rounded-md hover:bg-muted/50 transition-colors border border-transparent hover:border-border">
          <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center">
            <User className="w-3 h-3 text-primary-foreground" />
          </div>
          <span className="text-xs font-medium text-foreground hidden md:block">Admin</span>
        </button>
      </div>
    </header>
  );
}
