import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      // Use the bundled browser version of elkjs (doesn't need web-worker)
      'elkjs': path.resolve(__dirname, './node_modules/elkjs/lib/elk.bundled.js'),
    },
  },
  base: process.env.CF_PAGES ? '/' : '/graph-easy/',
  worker: {
    format: 'es',
  },
})
