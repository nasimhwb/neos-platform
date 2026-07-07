import { useState, useEffect, useRef } from "react";

export interface UseApiDataResult<T> {
  data: T;
  loading: boolean;
  error: string | null;
  source: "live" | "mock" | "cached";
  refresh: () => Promise<void>;
}

export function useApiData<T>(
  endpoint: string,
  defaultData: T,
  intervalMs = 5000
): UseApiDataResult<T> {
  const [data, setData] = useState<T>(defaultData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [source, setSource] = useState<"live" | "mock" | "cached">("mock");

  const latestEndpoint = useRef(endpoint);
  latestEndpoint.current = endpoint;

  const fetchData = async (showLoading = false) => {
    if (showLoading) setLoading(true);
    try {
      const res = await fetch(latestEndpoint.current);
      if (!res.ok) {
        throw new Error(`HTTP Error: ${res.status} ${res.statusText}`);
      }
      const payload = await res.json();
      setData(payload.data);
      setSource(payload.source || "live");
      setError(null);
    } catch (err: any) {
      console.error(`API fetch error on ${latestEndpoint.current}:`, err);
      setError(err.message || "Failed to fetch telemetry data");
    } finally {
      if (showLoading) setLoading(false);
    }
  };

  useEffect(() => {
    // Initial load
    fetchData(true);

    // Setup polling interval if specified
    let timer: NodeJS.Timeout | null = null;
    if (intervalMs > 0) {
      timer = setInterval(() => {
        fetchData(false);
      }, intervalMs);
    }

    // Future WebSocket implementation slot:
    // If we transition to real-time WebSockets later, we can initialize it here:
    // const wsUrl = endpoint.replace(/^http/, 'ws');
    // const ws = new WebSocket(wsUrl);
    // ws.onmessage = (event) => {
    //   const payload = JSON.parse(event.data);
    //   setData(payload.data);
    //   setSource('live');
    // };
    // return () => ws.close();

    return () => {
      if (timer) clearInterval(timer);
    };
  }, [endpoint, intervalMs]);

  return {
    data,
    loading,
    error,
    source,
    refresh: () => fetchData(true),
  };
}
