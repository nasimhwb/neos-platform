class LocalCache {
  private cache = new Map<string, { data: any; timestamp: number }>();

  get<T>(key: string, ttlMs: number): T | null {
    const entry = this.cache.get(key);
    if (entry && Date.now() - entry.timestamp < ttlMs) {
      return entry.data as T;
    }
    return null;
  }

  set<T>(key: string, data: T): void {
    this.cache.set(key, { data, timestamp: Date.now() });
  }

  clear(): void {
    this.cache.clear();
  }
}

export const localCache = new LocalCache();
