import { defineConfig, Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// Injects analytics script at build time when VITE_SELINE_TOKEN is set.
// Forkers can deploy without analytics by simply not setting this env var.
function injectAnalytics(): Plugin {
  const token = process.env.VITE_SELINE_TOKEN
  return {
    name: 'inject-analytics',
    transformIndexHtml(html) {
      if (!token) return html
      const script = `<script src="https://cdn.seline.so/seline.js" data-token="${token}" async></script>`
      return html.replace('</head>', `${script}\n  </head>`)
    },
  }
}

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), injectAnalytics()],
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
