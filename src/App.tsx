import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Select } from '@/components/ui/select'

import { Settings, ChevronDown, ChevronUp, ChevronRight, Moon, Sun, Code, Eye, Check, Copy, ZoomIn, ZoomOut, Minimize2, Zap, HelpCircle, Share2, Download, X } from 'lucide-react'
import * as Viz from '@viz-js/viz'

import './App.css'
import { graphConversionService } from './services/graphConversionService'

// Example graphs
const EXAMPLES = [
  {
    name: 'Simple Flow',
    graph: `[ Berlin ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Dresden ]`
  },
  {
    name: 'Complex Graph',
    graph: `[ Bonn ] -> [ Berlin ] { label: via train; }
[ Bonn ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Berlin ]
[ Berlin ] -> [ Dresden ]
[ Dresden ] -> [ Frankfurt ]`
  },
  {
    name: 'With Styling',
    graph: `graph { flow: south; }

[ Start ] { fill: lightgreen; }
[ Process ] { fill: lightyellow; }
[ End ] { fill: lightblue; }

[ Start ] -> [ Process ] -> [ End ]`
  },
  {
    name: 'Link Styles',
    graph: `[ Bonn ] <-> [ Berlin ]           # bidirectional
[ Berlin ] ==> [ Rostock ]         # double
[ Hamburg ] ..> [ Altona ]         # dotted
[ Dresden ] - > [ Bautzen ]        # dashed
[ Leipzig ] ~~> [ Kirchhain ]      # wave
[ Hof ] .-> [ Chemnitz ]           # dot-dash
[ Magdeburg ] <=> [ Ulm ]          # bidirectional, double
[ Magdeburg ] -- [ Ulm ]           # arrow-less edge`
  },
  {
    name: 'Network Topology',
    graph: `graph { flow: south; }

[ Internet ] { fill: lightblue; }
[ Firewall ] { fill: orange; }
[ Router ] { fill: lightyellow; }
[ Switch ] { fill: lightgreen; }
[ Server 1 ] { fill: lightcoral; }
[ Server 2 ] { fill: lightcoral; }
[ Workstation A ] { fill: lightgray; }
[ Workstation B ] { fill: lightgray; }
[ Workstation C ] { fill: lightgray; }

[ Internet ] ==> [ Firewall ] { label: WAN; }
[ Firewall ] ==> [ Router ] { label: DMZ; }
[ Router ] ==> [ Switch ] { label: LAN; }
[ Switch ] -> [ Server 1 ] { label: 192.168.1.10; }
[ Switch ] -> [ Server 2 ] { label: 192.168.1.11; }
[ Switch ] -> [ Workstation A ] { label: 192.168.1.20; }
[ Switch ] -> [ Workstation B ] { label: 192.168.1.21; }
[ Switch ] -> [ Workstation C ] { label: 192.168.1.22; }
[ Server 1 ] <-> [ Server 2 ] { label: sync; }`
  },
  {
    name: 'Seven Bridges of Königsberg',
    graph: `# The famous Seven Bridges problem solved by Euler
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

# Two bridges connecting North Bank to Kneiphof
[ North Bank ] -- { label: Bridge 1; } [ Island Kneiphof ]
[ North Bank ] -- { label: Bridge 2; } [ Island Kneiphof ]

# Two bridges connecting South Bank to Kneiphof
[ South Bank ] -- { label: Bridge 3; } [ Island Kneiphof ]
[ South Bank ] -- { label: Bridge 4; } [ Island Kneiphof ]

# One bridge connecting North to South via Lomse
[ North Bank ] -- { label: Bridge 5; } [ Island Lomse ]
[ Island Lomse ] -- { label: Bridge 6; } [ South Bank ]

# One bridge connecting Lomse to Kneiphof
[ Island Lomse ] -- { label: Bridge 7; } [ Island Kneiphof ]`
  },
  {
    name: 'Project Task Flow',
    graph: `graph { flow: south; }

[ Project Start ] { fill: lightgreen; }
[ Requirements Gathering ] { fill: lightyellow; }
[ Design Phase ] { fill: lightyellow; }
[ Development ] { fill: lightblue; }
[ Code Review ] { fill: lightblue; }
[ Testing ] { fill: orange; }
[ Bug Fixes ] { fill: orange; }
[ Staging Deployment ] { fill: lightcoral; }
[ QA Approval ] { fill: lightcoral; }
[ Production Deployment ] { fill: lightgreen; }
[ Project Complete ] { fill: lightgreen; }

[ Project Start ] -> [ Requirements Gathering ]
[ Requirements Gathering ] -> [ Design Phase ]
[ Design Phase ] -> [ Development ]
[ Development ] -> [ Code Review ]
[ Code Review ] -> [ Testing ]
[ Code Review ] ..> [ Development ] { label: needs changes; }
[ Testing ] -> [ QA Approval ]
[ Testing ] ..> [ Bug Fixes ] { label: bugs found; }
[ Bug Fixes ] --> [ Testing ]
[ QA Approval ] -> [ Staging Deployment ]
[ Staging Deployment ] ..> [ Bug Fixes ] { label: issues found; }
[ Staging Deployment ] -> [ Production Deployment ]
[ Production Deployment ] -> [ Project Complete ]`
  },
  {
    name: 'Network Graph',
    graph: `[ aa ] -> [ab]
[ aa ] -> [ac]
[ ab ] -> [ad]
[ ac ] -> [ad]
[ ad ] -> [ae]
[ ad ] -> [af]
[ ag ] -> [ah]
[ ag ] -> [ai]
[ ah ] -> [aj]
[ ai ] -> [aj]
[ aj ] -> [ak]
[ ak ] -> [al]
[ ak ] -> [am]
[ al ] -> [an]
[ am ] -> [an]
[ ao ] -> [ap]
[ ao ] -> [aq]
[ ap ] -> [ar]
[ aq ] -> [ar]
[ ar ] -> [as]
[ as ] -> [at]
[ at ] -> [au]
[ av ] -> [aw]
[ aw ] -> [ax]`
  },
  {
    name: 'Parallel Processes (Graphviz)',
    graph: `digraph {
    subgraph cluster_0 {
        a0 -> a1 -> a2 -> a3;
        label = "process #1";
    }

    subgraph cluster_1 {
        b0 -> b1 -> b2 -> b3;
        label = "process #2";
    }

    start -> a0;
    start -> b0;
    a1 -> b3;
    b2 -> a3;
    a3 -> a0;
    a3 -> end;
    b3 -> end;
}`
  }
]

// Utility functions for URL state serialization
const getStateFromURL = (): { input?: string; format?: OutputFormat } => {
  const params = new URLSearchParams(window.location.search)
  const input = params.get('input')
  const format = params.get('format') as OutputFormat | null

  return {
    input: input || undefined,
    format: format && ['ascii', 'boxart', 'html', 'svg', 'graphviz', 'graphml', 'vcg', 'txt'].includes(format)
      ? format
      : undefined,
  }
}

const updateURL = (input: string, format: OutputFormat) => {
  const params = new URLSearchParams()
  if (input.trim()) {
    params.set('input', input)
  }
  params.set('format', format)

  const newURL = `${window.location.pathname}?${params.toString()}`
  window.history.replaceState({}, '', newURL)
}

// Declare global Perl types
declare global {
  interface Window {
    Perl: {
      state: string
      eval: (code: string) => string
      addStateChangeListener: (callback: (from: string, to: string) => void) => void
    }
    FS: {
      mkdir: (path: string) => void
      writeFile: (path: string, content: string) => void
      readFile: (path: string, options: { encoding: string }) => string
    }
  }
}

type LoadingState = 'initializing' | 'loading-modules' | 'ready' | 'error'

export type OutputFormat = 'ascii' | 'boxart' | 'html' | 'svg' | 'graphviz' | 'graphml' | 'vcg' | 'txt'

const COMMON_FORMATS: { value: OutputFormat; label: string; description: string; disabled?: boolean }[] = [
  { value: 'ascii', label: 'ASCII Art', description: 'Uses +, -, <, | to render boxes' },
  { value: 'boxart', label: 'Box Art', description: 'Unicode box drawing characters' },
]

const ADVANCED_FORMATS: { value: OutputFormat; label: string; description: string; disabled?: boolean }[] = [
  { value: 'html', label: 'HTML', description: 'HTML table output' },
  { value: 'svg', label: 'SVG', description: 'Scalable Vector Graphics' },
  { value: 'graphviz', label: 'Graphviz', description: 'Graphviz DOT format' },
  { value: 'graphml', label: 'GraphML', description: 'GraphML XML format' },
  { value: 'vcg', label: 'VCG/GDL', description: 'VCG Graph Description Language' },
  { value: 'txt', label: 'Text', description: 'Normalized text representation' },
]

const OUTPUT_FORMATS = [...COMMON_FORMATS, ...ADVANCED_FORMATS]

function App() {
  // Initialize state from URL or defaults
  const urlState = getStateFromURL()
  const [input, setInput] = useState(urlState.input || EXAMPLES[0].graph)
  const [output, setOutput] = useState('')
  const [error, setError] = useState('')
  const [loadingState, setLoadingState] = useState<LoadingState>('initializing')
  const [paneWidth, setPaneWidth] = useState(400)
  const [paneHeight, setPaneHeight] = useState(300)
  const [isDragging, setIsDragging] = useState<'width' | 'height' | 'both' | null>(null)
  const [outputFormat, setOutputFormat] = useState<OutputFormat>(urlState.format || 'ascii')
  const [formatPanelOpen, setFormatPanelOpen] = useState(false)
  const [advancedFormatsOpen, setAdvancedFormatsOpen] = useState(false)
  const [isDarkMode, setIsDarkMode] = useState(false)
  const [copied, setCopied] = useState(false)
  const [renderedGraphviz, setRenderedGraphviz] = useState<SVGSVGElement | null>(null)
  const [mobileView, setMobileView] = useState<'editor' | 'results'>('editor')
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768)
  const [zoom, setZoom] = useState(1)
  const [panX, setPanX] = useState(0)
  const [panY, setPanY] = useState(0)
  const [isConverting, setIsConverting] = useState(false)
  const conversionRequestIdRef = useRef(0)
  const conversionPromiseRef = useRef<Promise<void> | null>(null)
  const [isPanning, setIsPanning] = useState(false)
  const [panStartX, setPanStartX] = useState(0)
  const [panStartY, setPanStartY] = useState(0)
  const [conversionTime, setConversionTime] = useState<number>(0)
  const [perlReady, setPerlReady] = useState(false)
  const [inputPaneCollapsed, setInputPaneCollapsed] = useState(false)
  const [selectedExample, setSelectedExample] = useState<string>(EXAMPLES[0].name)
  const [helpOpen, setHelpOpen] = useState(false)
  const [shareCopied, setShareCopied] = useState(false)

  const modulesLoadedRef = useRef(false)
  const vizInstanceRef = useRef<any>(null)
  const outputContainerRef = useRef<HTMLDivElement>(null)
  const outputContentRef = useRef<HTMLDivElement>(null)
  const urlUpdateTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const helpPanelRef = useRef<HTMLDivElement>(null)

  // Initialize app
  useEffect(() => {
    setLoadingState('ready')
  }, [])

  // Auto-convert first example when Perl is ready
  useEffect(() => {
    if (perlReady) {
      setTimeout(() => convertGraph(EXAMPLES[0].graph), 100)
    }
  }, [perlReady])

  // Initialize Perl modules in background (slow, non-blocking)
  // Note: WebPerl is loaded in index.html, not dynamically
  useEffect(() => {
    const initPerl = async () => {
      // Wait for Perl to be ready
      const checkPerl = setInterval(() => {
        if (typeof window.Perl !== 'undefined') {
          clearInterval(checkPerl)
          setupPerlListener()
        }
      }, 100)

      const setupPerlListener = () => {
        if (window.Perl.state === 'Ready' && !modulesLoadedRef.current) {
          loadModules()
        }

        window.Perl.addStateChangeListener((_from, to) => {
          if (to === 'Ready' && !modulesLoadedRef.current) {
            loadModules()
          }
        })

        // Fallback check after 2 seconds
        setTimeout(() => {
          if (!modulesLoadedRef.current &&
              (window.Perl.state === 'Ready' ||
               window.Perl.state === 'Running' ||
               window.Perl.state === 'Ended')) {
            loadModules()
          }
        }, 2000)
      }

      const loadModules = async () => {
        if (modulesLoadedRef.current) return

        try {
          console.log('Loading Perl modules in background...')

          const moduleFiles = [
            'lib/Graph/Easy/Base.pm',
            'lib/Graph/Easy/Attributes.pm',
            'lib/Graph/Easy/Node.pm',
            'lib/Graph/Easy/Node/Anon.pm',
            'lib/Graph/Easy/Node/Cell.pm',
            'lib/Graph/Easy/Node/Empty.pm',
            'lib/Graph/Easy/Edge.pm',
            'lib/Graph/Easy/Edge/Cell.pm',
            'lib/Graph/Easy/Group.pm',
            'lib/Graph/Easy/Group/Anon.pm',
            'lib/Graph/Easy/Group/Cell.pm',
            'lib/Graph/Easy/Layout.pm',
            'lib/Graph/Easy/Layout/Chain.pm',
            'lib/Graph/Easy/Layout/Force.pm',
            'lib/Graph/Easy/Layout/Grid.pm',
            'lib/Graph/Easy/Layout/Path.pm',
            'lib/Graph/Easy/Layout/Repair.pm',
            'lib/Graph/Easy/Layout/Scout.pm',
            'lib/Graph/Easy/Parser.pm',
            'lib/Graph/Easy/Parser/Graphviz.pm',
            'lib/Graph/Easy/Parser/VCG.pm',
            'lib/Graph/Easy/As_ascii.pm',
            'lib/Graph/Easy/As_graphml.pm',
            'lib/Graph/Easy/As_graphviz.pm',
            'lib/Graph/Easy/As_svg.pm',
            'lib/Graph/Easy/As_txt.pm',
            'lib/Graph/Easy/As_vcg.pm',
            'lib/Graph/Easy.pm'
          ]

          // Create directory structure
          const mkdirSafe = (path: string) => {
            try {
              window.FS.mkdir(path)
            } catch (e: any) {
              // errno 17 is EEXIST - ignore it
              if (e.errno !== 17) throw e
            }
          }

          mkdirSafe('/lib')
          mkdirSafe('/lib/Graph')
          mkdirSafe('/lib/Graph/Easy')
          mkdirSafe('/lib/Graph/Easy/Edge')
          mkdirSafe('/lib/Graph/Easy/Group')
          mkdirSafe('/lib/Graph/Easy/Layout')
          mkdirSafe('/lib/Graph/Easy/Node')
          mkdirSafe('/lib/Graph/Easy/Parser')

          // Load all modules in parallel for speed
          const modulePromises = moduleFiles.map(async (file) => {
            // Use correct base path depending on environment
            const basePath = import.meta.env.BASE_URL || '/'
            const response = await fetch(`${basePath}${file}`)
            if (!response.ok) {
              throw new Error(`Failed to load ${file}`)
            }
            const content = await response.text()
            return { file, content }
          })

          const modules = await Promise.all(modulePromises)

          // Write all modules to virtual filesystem
          for (const { file, content } of modules) {
            window.FS.writeFile(`/${file}`, content)
          }

          modulesLoadedRef.current = true
          setPerlReady(true)
          console.log('✅ Perl modules loaded')
        } catch (err: any) {
          console.error('❌ Failed to load Perl modules:', err)
          // Don't block the app - WASM/TS still work
        }
      }
    }

    // WebPerl and initialization script are loaded in index.html
    initPerl()
  }, [])

  // Initialize Viz.js for Graphviz rendering
  useEffect(() => {
    Viz.instance().then(viz => {
      vizInstanceRef.current = viz
    }).catch(err => {
      console.error('Failed to initialize Viz.js:', err)
    })
  }, [])

  // Initialize dark mode from localStorage or system preference
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
      setIsDarkMode(true)
    }
  }, [])

  // Update document class and localStorage when dark mode changes
  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    } else {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    }
  }, [isDarkMode])

  // Update URL when input or output format changes (debounced)
  useEffect(() => {
    if (urlUpdateTimeoutRef.current) {
      clearTimeout(urlUpdateTimeoutRef.current)
    }
    urlUpdateTimeoutRef.current = setTimeout(() => {
      updateURL(input, outputFormat)
    }, 1000) // 1 second debounce to reduce browser history clutter

    return () => {
      if (urlUpdateTimeoutRef.current) {
        clearTimeout(urlUpdateTimeoutRef.current)
      }
    }
  }, [input, outputFormat])
  
  // Handle window resize to update isMobile state
  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768)
    }

    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  // Auto-convert when input changes (debounced)
  useEffect(() => {
    if (loadingState !== 'ready' || !input.trim()) return

    // Don't auto-convert until modules are loaded
    if (!perlReady) return

    const timeoutId = setTimeout(() => {
      setIsConverting(true)
      convertGraph()
    }, 500) // 500ms debounce

    return () => clearTimeout(timeoutId)
  }, [input, loadingState, perlReady])

  // Auto-convert when output format changes
  useEffect(() => {
    if (loadingState === 'ready' && input.trim() && output) {
      // Only re-convert if we already have output
      // (don't convert on initial mount)

      // Don't auto-convert until modules are loaded
      if (!perlReady) return

      setIsConverting(true)
      convertGraph()
    }
  }, [outputFormat, perlReady])

  // Render Graphviz DOT output when format is 'graphviz'
  useEffect(() => {
    if (outputFormat === 'graphviz' && output && vizInstanceRef.current) {
      try {
        const svgElement = vizInstanceRef.current.renderSVGElement(output)
        setRenderedGraphviz(svgElement)
        setError('')
        setIsConverting(false)
      } catch (err: any) {
        console.error('Graphviz rendering error:', err)
        setError(`Graphviz rendering error: ${err.message}`)
        setRenderedGraphviz(null)
        setIsConverting(false)
      }
    } else {
      setRenderedGraphviz(null)
    }
  }, [output, outputFormat])

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Cmd/Ctrl + A to select only output (when not in input textarea)
      if ((e.metaKey || e.ctrlKey) && e.key === 'a') {
        const activeElement = document.activeElement
        const isInTextarea = activeElement?.tagName === 'TEXTAREA' || activeElement?.tagName === 'INPUT'

        if (!isInTextarea && outputContentRef.current) {
          e.preventDefault()
          const selection = window.getSelection()
          const range = document.createRange()
          range.selectNodeContents(outputContentRef.current)
          selection?.removeAllRanges()
          selection?.addRange(range)
        }
      }
      // Cmd/Ctrl + Enter to force re-render
      if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
        e.preventDefault()
        if (loadingState === 'ready' && input.trim()) {
          setIsConverting(true)
          convertGraph()
        }
      }
      // Escape to close help panel
      if (e.key === 'Escape' && helpOpen) {
        e.preventDefault()
        setHelpOpen(false)
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [helpOpen, loadingState, input])

  // Close help panel on outside click
  useEffect(() => {
    if (!helpOpen) return

    const handleClickOutside = (e: MouseEvent) => {
      if (helpPanelRef.current && !helpPanelRef.current.contains(e.target as Node)) {
        setHelpOpen(false)
      }
    }

    // Delay to prevent immediate close on the click that opened it
    setTimeout(() => {
      document.addEventListener('click', handleClickOutside)
    }, 0)

    return () => document.removeEventListener('click', handleClickOutside)
  }, [helpOpen])

  const convertGraph = async (graphInput?: string) => {
    const textToConvert = graphInput || input

    if (!textToConvert.trim()) {
      setOutput('')
      setError('Please enter some graph notation.')
      return
    }

    if (loadingState !== 'ready') {
      // Silently return - loading state is already indicated in the UI
      return
    }

    // Increment request ID and capture it for this conversion
    // This allows us to ignore stale results from earlier requests
    conversionRequestIdRef.current += 1
    const thisRequestId = conversionRequestIdRef.current

    console.log(`[Conversion ${thisRequestId}] Starting...`)

    // Wait for any previous conversion to complete to prevent Perl interpreter corruption
    if (conversionPromiseRef.current) {
      console.log(`[Conversion ${thisRequestId}] Waiting for previous conversion...`)
      try {
        await conversionPromiseRef.current
      } catch (e) {
        // Ignore errors from previous conversion
      }
    }

    // Check if we've been superseded while waiting
    if (thisRequestId !== conversionRequestIdRef.current) {
      console.log(`[Conversion ${thisRequestId}] Superseded while waiting (current: ${conversionRequestIdRef.current})`)
      return
    }

    // Create promise for this conversion
    const conversionPromise = (async () => {
      try {
        setError('')

        // Use the conversion service
        const result = await graphConversionService.convert(
          textToConvert,
          outputFormat
        )

        // Check if this request is still the latest one
        if (thisRequestId !== conversionRequestIdRef.current) {
          console.log(`[Conversion ${thisRequestId}] Ignoring stale result (current: ${conversionRequestIdRef.current})`)
          return
        }

        console.log(`[Conversion ${thisRequestId}] Applying result`)

        // Update performance metrics
        setConversionTime(result.timeMs)

        if (result.error) {
          setError(result.error)
        }

        if (result.output) {
          setOutput(result.output)
          setError(result.error || '')
          // For non-graphviz formats, conversion is complete immediately
          // For graphviz, the rendering effect will set isConverting to false
          if (outputFormat !== 'graphviz') {
            setIsConverting(false)
          }
        } else {
          setError('No output generated')
          setIsConverting(false)
        }
      } catch (err: any) {
        // Only show error if this is still the latest request
        if (thisRequestId === conversionRequestIdRef.current) {
          setError(`Conversion error: ${err.message || String(err)}`)
          setIsConverting(false)
        }
        // Keep previous output visible
      }
    })()

    conversionPromiseRef.current = conversionPromise
    await conversionPromise
  }

  const handleExampleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const exampleName = e.target.value
    if (exampleName === '') {
      // User selected the blank "Custom" option
      setSelectedExample('')
      return
    }
    const example = EXAMPLES.find(ex => ex.name === exampleName)
    if (example) {
      setSelectedExample(exampleName)
      setInput(example.graph)
      // Let the auto-convert useEffect handle the conversion to avoid race conditions
      // Fit to view after a short delay to ensure conversion completes
      setTimeout(() => handleFitToView(), 700)
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newValue = e.target.value
    setInput(newValue)
    // Clear the example selection when user manually edits
    const matchingExample = EXAMPLES.find(ex => ex.graph === newValue)
    if (matchingExample) {
      setSelectedExample(matchingExample.name)
    } else {
      setSelectedExample('')
    }
  }

  const handleCopyOutput = async () => {
    if (!output) return

    try {
      await navigator.clipboard.writeText(output)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  const handleShare = async () => {
    try {
      // Force URL update immediately
      updateURL(input, outputFormat)
      await navigator.clipboard.writeText(window.location.href)
      setShareCopied(true)
      setTimeout(() => setShareCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy URL:', err)
    }
  }

  const handleDownload = () => {
    if (!output) return

    const extensions: Record<OutputFormat, string> = {
      ascii: 'txt',
      boxart: 'txt',
      html: 'html',
      svg: 'svg',
      graphviz: 'dot',
      graphml: 'graphml',
      vcg: 'vcg',
      txt: 'txt'
    }

    const mimeTypes: Record<OutputFormat, string> = {
      ascii: 'text/plain',
      boxart: 'text/plain',
      html: 'text/html',
      svg: 'image/svg+xml',
      graphviz: 'text/plain',
      graphml: 'application/xml',
      vcg: 'text/plain',
      txt: 'text/plain'
    }

    const blob = new Blob([output], { type: mimeTypes[outputFormat] })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `graph.${extensions[outputFormat]}`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  const handleZoomIn = () => {
    setZoom(prevZoom => Math.min(prevZoom * 1.2, 5))
  }

  const handleZoomOut = () => {
    setZoom(prevZoom => Math.max(prevZoom / 1.2, 0.1))
  }

  const handleFitToView = () => {
    const container = outputContainerRef.current
    const content = outputContentRef.current
    if (!container || !content) return

    // Reset scroll position first
    container.scrollTop = 0
    container.scrollLeft = 0

    // Get container dimensions (viewport)
    const containerRect = container.getBoundingClientRect()
    const containerWidth = containerRect.width - 64 // Account for padding
    const containerHeight = containerRect.height - 64

    // Get content dimensions
    const contentWidth = content.scrollWidth
    const contentHeight = content.scrollHeight

    if (contentWidth === 0 || contentHeight === 0) return

    // Calculate scale to fit content in viewport
    const scaleX = containerWidth / contentWidth
    const scaleY = containerHeight / contentHeight
    const newZoom = Math.min(scaleX, scaleY, 1) // Don't zoom in beyond 100%

    // Reset pan to center (flexbox centering handles the actual centering)
    setZoom(newZoom)
    setPanX(0)
    setPanY(0)
  }

  // Handle resize dragging
  useEffect(() => {
    if (!isDragging) return

    const handleMouseMove = (e: MouseEvent) => {
      e.preventDefault() // Prevent text selection during drag
      if (isDragging === 'width' || isDragging === 'both') {
        // Account for the 32px (8 * 4) left offset of the pane
        const width = e.clientX - 32
        setPaneWidth(Math.max(300, Math.min(window.innerWidth - 64, width)))
      }
      if (isDragging === 'height' || isDragging === 'both') {
        // Account for the 32px top offset of the pane
        const height = e.clientY - 32
        setPaneHeight(Math.max(200, Math.min(window.innerHeight - 64, height)))
      }
    }

    const handleMouseUp = () => {
      setIsDragging(null)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)

    return () => {
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }
  }, [isDragging])

  // Handle panning with Ctrl/Cmd + click and drag
  useEffect(() => {
    const container = outputContainerRef.current
    if (!container) return

    const handleMouseDown = (e: MouseEvent) => {
      // Only pan with Ctrl/Cmd key
      if (!(e.ctrlKey || e.metaKey)) return

      e.preventDefault()
      setIsPanning(true)
      setPanStartX(e.clientX - panX)
      setPanStartY(e.clientY - panY)
      container.style.cursor = 'grabbing'
    }

    const handleMouseMove = (e: MouseEvent) => {
      if (!isPanning) return

      e.preventDefault()
      const newPanX = e.clientX - panStartX
      const newPanY = e.clientY - panStartY
      setPanX(newPanX)
      setPanY(newPanY)
    }

    const handleMouseUp = () => {
      if (isPanning) {
        setIsPanning(false)
        container.style.cursor = ''
      }
    }

    container.addEventListener('mousedown', handleMouseDown)
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)

    return () => {
      container.removeEventListener('mousedown', handleMouseDown)
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }
  }, [isPanning, panStartX, panStartY, panX, panY])

  // Handle zoom with Shift + scroll (desktop) or pinch (mobile)
  useEffect(() => {
    const container = outputContainerRef.current
    if (!container) return

    const handleWheel = (e: WheelEvent) => {
      // Only zoom with Shift + wheel
      if (!e.shiftKey) return

      e.preventDefault()

      // deltaY is positive when scrolling down (zoom out), negative when scrolling up (zoom in)
      if (e.deltaY < 0) {
        handleZoomIn()
      } else {
        handleZoomOut()
      }
    }

    // Pinch-to-zoom for touch devices
    let lastTouchDistance = 0

    const handleTouchStart = (e: TouchEvent) => {
      if (e.touches.length === 2) {
        const dx = e.touches[0].clientX - e.touches[1].clientX
        const dy = e.touches[0].clientY - e.touches[1].clientY
        lastTouchDistance = Math.sqrt(dx * dx + dy * dy)
      }
    }

    const handleTouchMove = (e: TouchEvent) => {
      if (e.touches.length === 2) {
        e.preventDefault()
        const dx = e.touches[0].clientX - e.touches[1].clientX
        const dy = e.touches[0].clientY - e.touches[1].clientY
        const distance = Math.sqrt(dx * dx + dy * dy)

        if (lastTouchDistance > 0) {
          const scale = distance / lastTouchDistance
          if (scale > 1.02) {
            setZoom(prev => Math.min(prev * 1.05, 5))
          } else if (scale < 0.98) {
            setZoom(prev => Math.max(prev / 1.05, 0.1))
          }
        }
        lastTouchDistance = distance
      }
    }

    const handleTouchEnd = () => {
      lastTouchDistance = 0
    }

    container.addEventListener('wheel', handleWheel, { passive: false })
    container.addEventListener('touchstart', handleTouchStart, { passive: true })
    container.addEventListener('touchmove', handleTouchMove, { passive: false })
    container.addEventListener('touchend', handleTouchEnd, { passive: true })

    return () => {
      container.removeEventListener('wheel', handleWheel)
      container.removeEventListener('touchstart', handleTouchStart)
      container.removeEventListener('touchmove', handleTouchMove)
      container.removeEventListener('touchend', handleTouchEnd)
    }
  }, [])

  // Auto-fit to view when output changes
  useEffect(() => {
    const container = outputContainerRef.current
    const content = outputContentRef.current
    if (!container || !content || !output) return

    // Wait for the DOM to update with new content dimensions
    requestAnimationFrame(() => {
      // Reset scroll position first
      container.scrollTop = 0
      container.scrollLeft = 0

      // Get container dimensions (viewport)
      const containerRect = container.getBoundingClientRect()
      const containerWidth = containerRect.width - 64 // Account for padding
      const containerHeight = containerRect.height - 64

      // Get content dimensions
      const contentWidth = content.scrollWidth
      const contentHeight = content.scrollHeight

      if (contentWidth === 0 || contentHeight === 0) return

      // Calculate scale to fit content in viewport
      const scaleX = containerWidth / contentWidth
      const scaleY = containerHeight / contentHeight
      const newZoom = Math.min(scaleX, scaleY, 1) // Don't zoom in beyond 100%

      // Apply new zoom and reset pan
      setZoom(newZoom)
      setPanX(0)
      setPanY(0)
    })
  }, [output])


  return (
    <div
      className="h-screen w-screen overflow-hidden bg-background font-sans"
      style={isDragging ? { userSelect: 'none' } : {}}
    >
      {/* Output - Full screen background, responsive */}
      <div
        ref={outputContainerRef}
        className={`absolute inset-0 overflow-auto flex items-center justify-center ${
          mobileView === 'editor' ? 'hidden md:flex' : 'flex'
        }`}
        style={{
          padding: '2rem',
        }}
      >
        <div
          ref={outputContentRef}
          style={{
            transform: `scale(${zoom}) translate(${panX}px, ${panY}px)`,
            transformOrigin: 'center center',
            userSelect: 'contain',
            WebkitUserSelect: 'contain',
          } as React.CSSProperties}
        >
          {loadingState === 'ready' && output && !isConverting ? (
            outputFormat === 'graphviz' ? (
              renderedGraphviz ? (
                <div
                  ref={(el) => {
                    if (el && renderedGraphviz) {
                      el.innerHTML = ''
                      el.appendChild(renderedGraphviz.cloneNode(true))
                    }
                  }}
                />
              ) : null
            ) : outputFormat === 'html' || outputFormat === 'svg' ? (
              <div
                dangerouslySetInnerHTML={{ __html: output }}
              />
            ) : (
              <pre className="font-mono text-xs md:text-sm leading-relaxed text-foreground/90" style={{ userSelect: 'text', WebkitUserSelect: 'text' }}>
                {output}
              </pre>
            )
          ) : null}
        </div>
      </div>

      {/* Input Pane - Full screen on mobile (header always visible), floating on desktop */}
      <div
        className={`bg-card border border-border flex flex-col overflow-hidden select-none ${
          isDragging ? '' : 'transition-shadow duration-200'
        } fixed left-0 right-0 top-0 md:pb-0 md:absolute md:top-8 md:left-8 md:rounded-lg md:shadow-2xl md:hover:shadow-3xl md:right-auto ${
          isMobile && mobileView === 'results' ? '' : 'bottom-0 pb-20 md:bottom-auto'
        }`}
        style={!isMobile ? {
          width: inputPaneCollapsed ? 'auto' : `${paneWidth}px`,
          height: inputPaneCollapsed ? 'auto' : `${paneHeight}px`,
        } : {}}
      >
        {/* Header - Clickable to collapse/expand */}
        <button
          onClick={() => !isMobile && setInputPaneCollapsed(!inputPaneCollapsed)}
          className={`flex items-center justify-between px-4 py-3 border-b border-border bg-muted/30 w-full text-left ${!isMobile ? 'cursor-pointer hover:bg-muted/50' : ''} transition-colors`}
        >
          <div className="flex items-center gap-2">
            {!isMobile && (
              <ChevronDown className={`w-4 h-4 text-muted-foreground transition-transform ${inputPaneCollapsed ? '-rotate-90' : ''}`} />
            )}
            <h1 className="text-sm font-medium text-foreground font-mono">
              {'[ graph ] ~~> [ easy ]'}
            </h1>
          </div>
          <div className="flex items-center gap-2 ml-4">
            {loadingState === 'ready' ? (
              !perlReady ? (
                <div className="w-2 h-2 rounded-full bg-orange-500 animate-pulse" title="Loading Perl modules..." />
              ) : (
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" title="Ready" />
              )
            ) : loadingState === 'error' ? (
              <div className="w-2 h-2 rounded-full bg-red-500" title="Error" />
            ) : null}
          </div>
        </button>

        {/* Content - Hidden when collapsed, different content for editor vs results on mobile */}
        {!inputPaneCollapsed && (
          <div className={`flex flex-col gap-3 overflow-hidden relative ${
            isMobile && mobileView === 'results' ? 'p-3' : 'flex-1 p-4'
          }`}>
            {/* Editor view content OR desktop */}
            {(!isMobile || mobileView === 'editor') && (
              <>
                {/* Example selector */}
                <div className="flex items-center gap-2">
                  <label className="text-xs text-muted-foreground shrink-0">Example:</label>
                  <Select
                    onChange={handleExampleChange}
                    className="flex-1 text-xs h-8"
                    value={selectedExample}
                  >
                    <option value="">Custom</option>
                    {EXAMPLES.map(ex => (
                      <option key={ex.name} value={ex.name}>{ex.name}</option>
                    ))}
                  </Select>
                </div>

                {/* Input */}
                <Textarea
                  value={input}
                  onChange={handleInputChange}
                  placeholder=""
                  className="flex-1 resize-none text-xs select-text"
                />

                {/* Error display */}
                {error && loadingState === 'ready' && (
                  <div className="text-xs text-destructive bg-destructive/10 px-3 py-2 rounded-md border border-destructive/20">
                    {error}
                  </div>
                )}

                {/* Performance metrics */}
                {!error && output && (
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Zap className="w-3 h-3" />
                      <span className="font-medium">Perl</span>
                    </div>
                    <span>•</span>
                    <span>{conversionTime.toFixed(1)}ms</span>
                  </div>
                )}

                {/* Minimap preview - Mobile only */}
                {isMobile && mobileView === 'editor' && output && !error && !isConverting && (
                  <div
                    className="absolute bottom-14 right-6 w-32 h-24 bg-background border border-border rounded-lg overflow-hidden shadow-lg active:scale-95 transition-transform cursor-pointer"
                    onClick={() => setMobileView('results')}
                  >
                    <div className="absolute inset-0 overflow-hidden flex items-center justify-center">
                      {outputFormat === 'graphviz' && renderedGraphviz ? (
                        <div
                          className="scale-[0.1] origin-center"
                          ref={(el) => {
                            if (el && renderedGraphviz) {
                              el.innerHTML = ''
                              el.appendChild(renderedGraphviz.cloneNode(true))
                            }
                          }}
                        />
                      ) : outputFormat === 'html' || outputFormat === 'svg' ? (
                        <div className="scale-[0.1] origin-center" dangerouslySetInnerHTML={{ __html: output }} />
                      ) : (
                        <pre className="font-mono text-[4px] leading-[1.2] text-foreground whitespace-pre text-center">
                          {output.slice(0, 500)}
                        </pre>
                      )}
                    </div>
                    <div className="absolute inset-x-0 bottom-0 flex items-center justify-center bg-gradient-to-t from-background to-transparent py-1">
                      <span className="text-[10px] font-medium text-foreground/80">Tap to view</span>
                    </div>
                  </div>
                )}
              </>
            )}

            {/* Results view content on mobile */}
            {isMobile && mobileView === 'results' && (
              <div className="flex items-center gap-2">
                <label className="text-xs text-muted-foreground shrink-0">Format:</label>
                <Select
                  value={outputFormat}
                  onChange={(e) => setOutputFormat(e.target.value as OutputFormat)}
                  className="flex-1 text-xs h-8"
                >
                  {COMMON_FORMATS.map(f => (
                    <option key={f.value} value={f.value}>{f.label}</option>
                  ))}
                </Select>
                <Button
                  onClick={handleCopyOutput}
                  size="sm"
                  variant="outline"
                  className="h-8 w-8 p-0"
                  title="Copy output"
                  disabled={!output || loadingState !== 'ready'}
                >
                  {copied ? <Check className="h-4 w-4 text-green-500" /> : <Copy className="h-4 w-4" />}
                </Button>
                <Button
                  onClick={() => setIsDarkMode(!isDarkMode)}
                  size="sm"
                  variant="outline"
                  className="h-8 w-8 p-0"
                >
                  {isDarkMode ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
                </Button>
              </div>
            )}
          </div>
        )}

        {/* Resize handles - Desktop only, hidden when collapsed */}
        {!inputPaneCollapsed && (
          <>
            <div
              className="hidden md:block absolute right-0 top-0 bottom-0 w-2 cursor-ew-resize hover:bg-primary/20 transition-colors"
              onMouseDown={(e) => {
                e.preventDefault()
                e.stopPropagation()
                setIsDragging('width')
              }}
            />
            <div
              className="hidden md:block absolute left-0 right-0 bottom-0 h-2 cursor-ns-resize hover:bg-primary/20 transition-colors"
              onMouseDown={(e) => {
                e.preventDefault()
                e.stopPropagation()
                setIsDragging('height')
              }}
            />
            <div
              className="hidden md:block absolute right-0 bottom-0 w-4 h-4 cursor-nwse-resize hover:bg-primary/20 transition-colors z-10"
              onMouseDown={(e) => {
                e.preventDefault()
                e.stopPropagation()
                setIsDragging('both')
              }}
            />
          </>
        )}
      </div>

      {/* Top Right Controls - Desktop only */}
      <div className="hidden md:flex absolute right-8 top-8 z-10 flex-row items-center gap-2 select-none">
        {/* Zoom controls - Desktop only */}
        <div className="hidden md:flex gap-1 bg-card border border-border rounded-lg overflow-hidden">
          <Button
            onClick={handleZoomOut}
            size="sm"
            variant="ghost"
            className="h-9 w-9 p-0 rounded-none"
            title="Zoom out (Ctrl/Cmd -)"
            disabled={!output || loadingState !== 'ready'}
          >
            <ZoomOut className="h-4 w-4" />
          </Button>
          <div className="flex items-center justify-center min-w-[3rem] px-2 text-xs font-medium text-muted-foreground border-x border-border select-none">
            {Math.round(zoom * 100)}%
          </div>
          <Button
            onClick={handleZoomIn}
            size="sm"
            variant="ghost"
            className="h-9 w-9 p-0 rounded-none"
            title="Zoom in (Ctrl/Cmd +)"
            disabled={!output || loadingState !== 'ready'}
          >
            <ZoomIn className="h-4 w-4" />
          </Button>
          <Button
            onClick={handleFitToView}
            size="sm"
            variant="ghost"
            className="h-9 w-9 p-0 rounded-none border-l border-border"
            title="Fit to view"
            disabled={!output || loadingState !== 'ready'}
          >
            <Minimize2 className="h-4 w-4" />
          </Button>
        </div>

        {/* Copy */}
        <Button
          onClick={handleCopyOutput}
          size="sm"
          variant="outline"
          className="h-9 w-9 p-0"
          title="Copy raw text output"
          disabled={!output || loadingState !== 'ready'}
        >
          {copied ? (
            <Check className="h-4 w-4 text-green-500" />
          ) : (
            <Copy className="h-4 w-4" />
          )}
        </Button>

        {/* Download - Desktop only */}
        <Button
          onClick={handleDownload}
          size="sm"
          variant="outline"
          className="hidden md:flex h-9 w-9 p-0"
          title="Download output"
          disabled={!output || loadingState !== 'ready'}
        >
          <Download className="h-4 w-4" />
        </Button>

        {/* Share - Desktop only */}
        <Button
          onClick={handleShare}
          size="sm"
          variant="outline"
          className="hidden md:flex h-9 w-9 p-0"
          title="Copy shareable URL"
        >
          {shareCopied ? (
            <Check className="h-4 w-4 text-green-500" />
          ) : (
            <Share2 className="h-4 w-4" />
          )}
        </Button>

        {/* Dark mode - Always visible */}
        <Button
          onClick={() => setIsDarkMode(!isDarkMode)}
          size="sm"
          variant="outline"
          className="h-9 w-9 p-0"
          title={isDarkMode ? 'Switch to light mode' : 'Switch to dark mode'}
        >
          {isDarkMode ? (
            <Sun className="h-4 w-4" />
          ) : (
            <Moon className="h-4 w-4" />
          )}
        </Button>
      </div>

      {/* Format Selector Panel - Bottom Right on desktop only (mobile uses inline) */}
      <div className="hidden md:block absolute bottom-8 right-8 z-10 select-none">
        <div className="bg-card border border-border rounded-lg shadow-2xl overflow-hidden transition-all duration-200">
          {/* Collapsed header */}
          {!formatPanelOpen && (
            <button
              onClick={() => setFormatPanelOpen(true)}
              className="flex items-center gap-2 px-4 py-2 hover:bg-muted/50 transition-colors text-sm"
            >
              <Settings className="w-4 h-4" />
              <span className="font-medium">
                {OUTPUT_FORMATS.find(f => f.value === outputFormat)?.label}
              </span>
              <ChevronUp className="w-3 h-3" />
            </button>
          )}

          {/* Expanded panel */}
          {formatPanelOpen && (
            <div className="w-64">
              {/* Header */}
              <button
                onClick={() => setFormatPanelOpen(false)}
                className="w-full flex items-center justify-between px-4 py-2 border-b border-border hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Settings className="w-4 h-4" />
                  <span className="text-sm font-medium">Output Format</span>
                </div>
                <ChevronDown className="w-3 h-3" />
              </button>

              {/* Format options */}
              <div className="p-2 space-y-2">
                <div className="text-xs font-medium text-muted-foreground px-1">Output Format</div>

                {/* Common formats */}
                <div className="space-y-1">
                  {COMMON_FORMATS.map((format) => (
                    <button
                      key={format.value}
                      onClick={() => !format.disabled && setOutputFormat(format.value)}
                      disabled={format.disabled}
                      className={`w-full text-left px-3 py-2 rounded-md transition-all duration-150 ${
                        format.disabled
                          ? 'opacity-50 cursor-not-allowed'
                          : outputFormat === format.value
                          ? 'bg-primary text-primary-foreground'
                          : 'hover:bg-muted/50'
                      }`}
                    >
                      <div className="text-sm font-medium">{format.label}</div>
                      <div className={`text-xs mt-0.5 ${
                        format.disabled
                          ? 'text-muted-foreground'
                          : outputFormat === format.value
                          ? 'text-primary-foreground/80'
                          : 'text-muted-foreground'
                      }`}>
                        {format.description}
                    </div>
                  </button>
                ))}
                </div>

                {/* Advanced formats collapsible */}
                <div className="border-t border-border pt-2">
                  <button
                    onClick={() => setAdvancedFormatsOpen(!advancedFormatsOpen)}
                    className="w-full text-left px-3 py-2 rounded-md hover:bg-muted/50 transition-all duration-150 flex items-center justify-between"
                  >
                    <span className="text-xs font-medium text-muted-foreground">Advanced Formats</span>
                    <ChevronRight className={`w-3 h-3 text-muted-foreground transition-transform ${advancedFormatsOpen ? 'rotate-90' : ''}`} />
                  </button>

                  {advancedFormatsOpen && (
                    <div className="space-y-1 mt-1">
                      {ADVANCED_FORMATS.map((format) => (
                        <button
                          key={format.value}
                          onClick={() => !format.disabled && setOutputFormat(format.value)}
                          disabled={format.disabled}
                          className={`w-full text-left px-3 py-2 rounded-md transition-all duration-150 ${
                            format.disabled
                              ? 'opacity-50 cursor-not-allowed'
                              : outputFormat === format.value
                              ? 'bg-primary text-primary-foreground'
                              : 'hover:bg-muted/50'
                          }`}
                        >
                          <div className="text-sm font-medium">{format.label}</div>
                          <div className={`text-xs mt-0.5 ${
                            format.disabled
                              ? 'text-muted-foreground'
                              : outputFormat === format.value
                              ? 'text-primary-foreground/80'
                              : 'text-muted-foreground'
                          }`}>
                            {format.description}
                          </div>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Help Button - Bottom Left */}
      <div className="hidden md:block absolute bottom-8 left-8 z-10 select-none">
        <Button
          onClick={() => setHelpOpen(!helpOpen)}
          size="sm"
          variant="outline"
          className="h-9 w-9 p-0"
          title="Help & Documentation"
        >
          <HelpCircle className="h-4 w-4" />
        </Button>
      </div>

      {/* Help Overlay */}
      {helpOpen && (
        <div
          ref={helpPanelRef}
          className="hidden md:block absolute bottom-20 left-8 z-20 w-80 bg-card border border-border rounded-lg shadow-2xl overflow-hidden"
        >
          <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-muted/30">
            <h2 className="text-sm font-medium">Help & Documentation</h2>
            <button
              onClick={() => setHelpOpen(false)}
              className="text-muted-foreground hover:text-foreground"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="p-4 space-y-4 text-sm">
            <div>
              <h3 className="font-medium mb-1">About</h3>
              <p className="text-muted-foreground text-xs">
                A web-based graph visualization tool supporting both Graph::Easy and DOT (Graphviz) notation. Renders to ASCII art and Box art.
              </p>
            </div>
            <div>
              <h3 className="font-medium mb-1">Keyboard Shortcuts</h3>
              <ul className="text-muted-foreground text-xs space-y-1">
                <li>• <strong>Cmd/Ctrl + Enter</strong> to re-render</li>
                <li>• <strong>Escape</strong> to close this panel</li>
                <li>• <strong>Shift + Scroll</strong> to zoom</li>
                <li>• <strong>Ctrl/Cmd + Drag</strong> to pan</li>
                <li>• Click header to collapse editor</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium mb-1">Syntax Examples</h3>
              <textarea
                readOnly
                className="w-full bg-muted/50 rounded p-2 font-mono text-xs text-muted-foreground resize-none border-0 focus:outline-none focus:ring-0"
                style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
                rows={3}
                defaultValue={`[ A ] -> [ B ]
[ A ] <-> [ B ]
[ A ] -> { label: text; } [ B ]`}
              />
            </div>
            <div className="pt-2 border-t border-border">
              <h3 className="font-medium mb-2">Resources</h3>
              <div className="space-y-1">
                <a
                  href="https://metacpan.org/pod/Graph::Easy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-xs text-blue-600 dark:text-blue-400 hover:underline"
                >
                  Graph::Easy Docs (CPAN) →
                </a>
                <a
                  href="https://graphviz.org/doc/info/lang.html"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-xs text-blue-600 dark:text-blue-400 hover:underline"
                >
                  DOT Language Docs →
                </a>
                <a
                  href="https://github.com/cjlm/graph-easy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-xs text-blue-600 dark:text-blue-400 hover:underline"
                >
                  GitHub →
                </a>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile View Toggle - Bottom Center (Mobile Only) */}
      <div className="md:hidden fixed bottom-4 left-1/2 transform -translate-x-1/2 z-50 flex gap-2">
        <div className="bg-card border border-border rounded-lg shadow-2xl overflow-hidden flex">
          <Button
            onClick={() => setMobileView('editor')}
            size="sm"
            variant={mobileView === 'editor' ? 'default' : 'ghost'}
            className="rounded-l-lg rounded-r-none px-4 py-2"
          >
            <Code className="h-4 w-4 mr-2" />
            Editor
          </Button>
          <Button
            onClick={() => setMobileView('results')}
            size="sm"
            variant={mobileView === 'results' ? 'default' : 'ghost'}
            className="rounded-r-lg rounded-l-none px-4 py-2"
          >
            <Eye className="h-4 w-4 mr-2" />
            Graph
          </Button>
        </div>
        <Button
          onClick={() => setHelpOpen(!helpOpen)}
          size="sm"
          variant="outline"
          className="px-3 shadow-2xl"
        >
          <HelpCircle className="h-4 w-4" />
        </Button>
      </div>

      {/* Mobile Help Overlay */}
      {helpOpen && isMobile && (
        <div
          ref={helpPanelRef}
          className="md:hidden fixed inset-x-4 bottom-24 z-50 bg-card border border-border rounded-lg shadow-2xl overflow-hidden max-h-[60vh] overflow-y-auto"
        >
          <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-muted/30 sticky top-0">
            <h2 className="text-sm font-medium">Help</h2>
            <button
              onClick={() => setHelpOpen(false)}
              className="text-muted-foreground hover:text-foreground p-1"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
          <div className="p-4 space-y-4 text-sm">
            <div>
              <h3 className="font-medium mb-1">About</h3>
              <p className="text-muted-foreground text-xs">
                Supports both Graph::Easy and DOT (Graphviz) notation. Renders to ASCII art and Box art.
              </p>
            </div>
            <div>
              <h3 className="font-medium mb-1">Tips</h3>
              <ul className="text-muted-foreground text-xs space-y-1">
                <li>• <strong>Pinch</strong> to zoom in Graph view</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium mb-1">Syntax Examples</h3>
              <textarea
                readOnly
                className="w-full bg-muted/50 rounded p-2 font-mono text-xs text-muted-foreground resize-none border-0 focus:outline-none focus:ring-0"
                style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
                rows={2}
                defaultValue={`[ A ] -> [ B ]
[ A ] <-> [ B ]`}
              />
            </div>
            <div className="pt-2 border-t border-border space-y-2">
              <p className="text-xs text-muted-foreground italic">
                Works best on desktop.
              </p>
              <div className="space-y-1">
                <a
                  href="https://metacpan.org/pod/Graph::Easy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-xs text-blue-600 dark:text-blue-400 hover:underline"
                >
                  Graph::Easy Docs →
                </a>
                <a
                  href="https://github.com/cjlm/graph-easy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-xs text-blue-600 dark:text-blue-400 hover:underline"
                >
                  GitHub →
                </a>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
