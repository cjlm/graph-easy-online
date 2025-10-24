import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      // Polyfill 'web-worker' with browser's native Worker
      'web-worker': path.resolve(__dirname, './src/polyfills/web-worker.ts'),
    },
  },
  base: process.env.CF_PAGES ? '/' : '/graph-easy/',
  worker: {
    format: 'es',
  },
})
