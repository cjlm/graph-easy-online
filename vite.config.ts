import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      // graph-easy-ts doesn't have proper exports, point to source directly
      'graph-easy-ts': path.resolve(__dirname, './node_modules/graph-easy-ts/src/index.ts'),
    },
  },
  base: process.env.CF_PAGES ? '/' : '/graph-easy/',
  worker: {
    format: 'es',
  },
})
