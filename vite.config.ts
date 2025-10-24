import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      // Use the bundled version of ELK that doesn't need web workers
      'elkjs': 'elkjs/lib/elk.bundled.js',
    },
  },
  base: process.env.CF_PAGES ? '/' : '/graph-easy/',
  optimizeDeps: {
    exclude: ['elkjs'],
  },
})
