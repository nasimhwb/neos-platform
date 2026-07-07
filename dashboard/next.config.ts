import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  experimental: {
    // Required for server actions in production
  },
};

export default nextConfig;
