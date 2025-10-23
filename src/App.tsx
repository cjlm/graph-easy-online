import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Select } from '@/components/ui/select'

import { Settings, ChevronDown, ChevronUp, Moon, Sun, Code, Eye, Check, Copy, ZoomIn, ZoomOut, Minimize2 } from 'lucide-react'
import * as Viz from '@viz-js/viz'

import './App.css'

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
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 1; }
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 2; }

# Two bridges connecting South Bank to Kneiphof
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 3; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 4; }

# One bridge connecting North to South via Lomse
[ North Bank ] -- [ Island Lomse ] { label: Bridge 5; }
[ Island Lomse ] -- [ South Bank ] { label: Bridge 6; }

# One bridge connecting Lomse to Kneiphof
[ Island Lomse ] -- [ Island Kneiphof ] { label: Bridge 7; }`
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
    name: 'Large Network Graph',
    graph: `[ aa ] -> [ab]
[ aa ] -> [ab]
[ ae ] -> [af]
[ ag ] -> [af]
[ ag ] -> [aj]
[ ag ] -> [aj]
[ ag ] -> [an]
[ ao ] -> [ap]
[ ao ] -> [ar]
[ ao ] -> [ar]
[ ao ] -> [ar]
[ ao ] -> [ax]
[ ao ] -> [az]
[ ao ] -> [ar]
[ bc ] -> [bd]
[ bc ] -> [bf]
[ bc ] -> [bh]
[ bc ] -> [bj]
[ bc ] -> [bl]
[ bc ] -> [bn]
[ bc ] -> [bp]
[ bc ] -> [br]
[ bc ] -> [bt]
[ bc ] -> [bt]
[ bw ] -> [bx]
[ bw ] -> [bx]
[ bw ] -> [bx]
[ bw ] -> [cd]
[ bw ] -> [cf]
[ bw ] -> [cf]
[ bw ] -> [cd]
[ bw ] -> [cl]
[ bw ] -> [cn]
[ bw ] -> [cp]
[ bw ] -> [cr]
[ bw ] -> [cl]
[ bw ] -> [cv]
[ bw ] -> [cx]
[ bw ] -> [cz]
[ bw ] -> [cf]
[ bw ] -> [cl]
[ de ] -> [df]
[ de ] -> [dh]
[ de ] -> [dh]
[ dk ] -> [dl]
[ dk ] -> [dh]
[ do ] -> [dp]
[ do ] -> [ar]
[ do ] -> [dt]
[ do ] -> [ar]
[ do ] -> [ar]
[ do ] -> [ar]
[ do ] -> [eb]
[ do ] -> [ed]
[ do ] -> [ef]
[ do ] -> [ef]
[ do ] -> [ar]
[ do ] -> [el]
[ do ] -> [eb]
[ do ] -> [ep]
[ do ] -> [er]
[ do ] -> [et]
[ do ] -> [eb]
[ do ] -> [ex]
[ do ] -> [dt]
[ do ] -> [fb]
[ do ] -> [fd]
[ do ] -> [dt]
[ do ] -> [fh]
[ do ] -> [fj]
[ do ] -> [fl]
[ do ] -> [fn]
[ do ] -> [fp]
[ do ] -> [fr]
[ do ] -> [ft]
[ do ] -> [ft]
[ do ] -> [ft]
[ do ] -> [fz]
[ do ] -> [gb]
[ do ] -> [gd]
[ do ] -> [gf]
[ do ] -> [gh]
[ do ] -> [gj]
[ do ] -> [gl]
[ do ] -> [gn]
[ do ] -> [bn]
[ do ] -> [cl]
[ do ] -> [cl]
[ do ] -> [bj]
[ do ] -> [br]
[ do ] -> [gz]
[ do ] -> [ar]
[ hc ] -> [hd]
[ hc ] -> [ar]
[ hc ] -> [hh]
[ hc ] -> [ar]
[ hc ] -> [hl]
[ hc ] -> [hn]
[ hc ] -> [hp]
[ hc ] -> [ar]
[ hc ] -> [eb]
[ hc ] -> [hv]
[ hc ] -> [hx]
[ hc ] -> [hz]
[ hc ] -> [ib]
[ hc ] -> [hv]
[ hc ] -> [if]
[ hc ] -> [ih]
[ hc ] -> [ij]
[ hc ] -> [il]
[ hc ] -> [in]
[ hc ] -> [hv]
[ hc ] -> [ir]
[ hc ] -> [hv]
[ hc ] -> [iv]
[ hc ] -> [hv]
[ hc ] -> [iz]
[ hc ] -> [jb]
[ hc ] -> [jd]
[ hc ] -> [jf]
[ hc ] -> [jh]
[ hc ] -> [jj]
[ hc ] -> [jl]
[ hc ] -> [jn]
[ hc ] -> [jp]
[ hc ] -> [jr]
[ hc ] -> [jt]
[ hc ] -> [hv]
[ hc ] -> [ar]
[ hc ] -> [eb]
[ hc ] -> [cf]
[ hc ] -> [bn]
[ hc ] -> [kf]
[ hc ] -> [cl]
[ hc ] -> [cl]
[ hc ] -> [cl]
[ hc ] -> [cl]
[ hc ] -> [gz]
[ hc ] -> [hh]
[ hc ] -> [ar]
[ ku ] -> [kv]
[ ku ] -> [ar]
[ ku ] -> [dt]
[ ku ] -> [ar]
[ ku ] -> [ar]
[ ku ] -> [cn]
[ ku ] -> [ar]
[ ku ] -> [eb]
[ ku ] -> [ed]
[ ku ] -> [ef]
[ ku ] -> [ef]
[ ku ] -> [ar]
[ ku ] -> [el]
[ ku ] -> [eb]
[ ku ] -> [ep]
[ ku ] -> [er]
[ ku ] -> [eb]
[ ku ] -> [ex]
[ ku ] -> [dt]
[ ku ] -> [fb]
[ ku ] -> [fd]
[ ku ] -> [dt]
[ ku ] -> [fh]
[ ku ] -> [fj]
[ ku ] -> [fl]
[ ku ] -> [fn]
[ ku ] -> [fp]
[ ku ] -> [fr]
[ ku ] -> [mz]
[ ku ] -> [ft]
[ ku ] -> [ft]
[ ku ] -> [ft]
[ ku ] -> [fz]
[ ku ] -> [gd]
[ ku ] -> [gh]
[ ku ] -> [bt]
[ ku ] -> [bt]
[ ku ] -> [gj]
[ ku ] -> [gn]
[ ku ] -> [cl]
[ ku ] -> [bj]
[ ku ] -> [br]
[ ku ] -> [gz]
[ ku ] -> [ar]
[ oe ] -> [of]
[ oe ] -> [af]
[ oi ] -> [af]
[ oi ] -> [ol]
[ om ] -> [bt]
[ om ] -> [bt]
[ om ] -> [bt]
[ om ] -> [ot]
[ om ] -> [ot]
[ om ] -> [ot]
[ om ] -> [bt]
[ om ] -> [bt]
[ om ] -> [pd]
[ om ] -> [bt]
[ om ] -> [bt]
[ om ] -> [bt]
[ om ] -> [bt]
[ om ] -> [pn]
[ om ] -> [pn]
[ om ] -> [pn]
[ om ] -> [pn]
[ om ] -> [bt]
[ pw ] -> [px]
[ pw ] -> [px]
[ pw ] -> [qb]
[ qc ] -> [qd]
[ qc ] -> [ab]
[ qg ] -> [qh]
[ qi ] -> [qj]
[ qi ] -> [ql]
[ qm ] -> [qj]
[ qm ] -> [ql]
[ qq ] -> [qr]
[ qq ] -> [ql]
[ qq ] -> [qr]
[ qq ] -> [qr]
[ qq ] -> [qr]
[ qq ] -> [qr]
[ rc ] -> [qj]
[ rc ] -> [ql]
[ rg ] -> [rh]
[ rg ] -> [rh]
[ rg ] -> [qj]
[ rg ] -> [ql]
[ rg ] -> [rp]
[ rg ] -> [rp]
[ rg ] -> [rh]
[ rg ] -> [rh]
[ rg ] -> [rh]
[ rg ] -> [rz]
[ rg ] -> [rz]
[ rg ] -> [rz]
[ rg ] -> [sf]
[ rg ] -> [sf]
[ rg ] -> [sf]
[ rg ] -> [rp]
[ sm ] -> [qj]
[ sm ] -> [ql]
[ sm ] -> [rh]
[ ss ] -> [qj]
[ ss ] -> [ql]
[ sw ] -> [qj]
[ sw ] -> [ql]
[ ta ] -> [qj]
[ ta ] -> [ql]
[ te ] -> [qj]
[ te ] -> [ql]
[ te ] -> [tj]
[ tk ] -> [qj]
[ tk ] -> [ql]
[ to ] -> [qj]
[ to ] -> [ql]
[ ts ] -> [qj]
[ ts ] -> [ql]
[ tw ] -> [qj]
[ tw ] -> [ql]
[ ua ] -> [qj]
[ ua ] -> [ql]
[ ue ] -> [qj]
[ ue ] -> [ql]
[ ue ] -> [uj]
[ ue ] -> [ul]
[ ue ] -> [un]
[ ue ] -> [un]
[ uq ] -> [ue]
[ uq ] -> [ue]
[ uq ] -> [qj]
[ uq ] -> [ue]
[ uq ] -> [ql]
[ uq ] -> [vb]
[ vc ] -> [qj]
[ vc ] -> [ql]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [qj]
[ vg ] -> [ql]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [vh]
[ vg ] -> [wh]
[ wi ] -> [qj]
[ wi ] -> [bt]
[ wi ] -> [ql]
[ wi ] -> [wp]
[ wi ] -> [wr]
[ ws ] -> [af]
[ ws ] -> [wv]
[ ww ] -> [qj]
[ ww ] -> [ql]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xb]
[ ww ] -> [xz]
[ ww ] -> [xb]
[ ww ] -> [xz]
[ ww ] -> [xz]
[ ww ] -> [xb]
[ ww ] -> [yj]
[ ww ] -> [bt]
[ ym ] -> [vg]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [qj]
[ ym ] -> [ql]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ ym ] -> [yp]
[ zq ] -> [zr]
[ zq ] -> [qj]
[ zq ] -> [ql]
[ zw ] -> [af]
[ zw ] -> [zz]
[ zw ] -> [zz]
[ zw ] -> [aad]
[ zw ] -> [aad]
[ aag ] -> [qj]
[ aag ] -> [ql]
[ aak ] -> [aal]
[ aam ] -> [aan]
[ aam ] -> [aap]
[ aam ] -> [aar]
[ aam ] -> [aat]
[ aam ] -> [aav]
[ aam ] -> [aax]
[ aam ] -> [aaz]
[ aam ] -> [abb]
[ aam ] -> [abd]
[ of ] -> [abf]
[ of ] -> [abh]
[ of ] -> [abj]
[ abk ] -> [zw]
[ abm ] -> [af]
[ abm ] -> [ae]
[ abm ] -> [ae]
[ abs ] -> [abt]
[ abs ] -> [abt]
[ abs ] -> [abx]
[ abs ] -> [abx]
[ aca ] -> [qd]
[ aca ] -> [ab]
[ ab ] -> [af]
[ ab ] -> [ach]
[ af ] -> [acj]
[ ack ] -> [ax]
[ acm ] -> [bf]
[ acm ] -> [bf]
[ acm ] -> [bf]
[ acs ] -> [bh]
[ acs ] -> [acv]`
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
      : undefined
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

type OutputFormat = 'ascii' | 'boxart' | 'html' | 'svg' | 'graphviz' | 'graphml' | 'vcg' | 'txt'

const OUTPUT_FORMATS: { value: OutputFormat; label: string; description: string; disabled?: boolean }[] = [
  { value: 'ascii', label: 'ASCII Art', description: 'Uses +, -, <, | to render boxes' },
  { value: 'boxart', label: 'Box Art', description: 'Unicode box drawing characters' },
  { value: 'html', label: 'HTML', description: 'HTML table output' },
  { value: 'svg', label: 'SVG', description: 'Scalable Vector Graphics' },
  { value: 'graphviz', label: 'Graphviz', description: 'Graphviz DOT format' },
  { value: 'graphml', label: 'GraphML', description: 'GraphML XML format' },
  { value: 'vcg', label: 'VCG/GDL', description: 'VCG Graph Description Language' },
  { value: 'txt', label: 'Text', description: 'Normalized text representation' },
]

function App() {
  // Initialize state from URL or defaults
  const urlState = getStateFromURL()
  const [input, setInput] = useState(urlState.input || EXAMPLES[0].graph)
  const [output, setOutput] = useState('')
  const [error, setError] = useState('')
  const [loadingState, setLoadingState] = useState<LoadingState>('initializing')
  const [paneWidth, setPaneWidth] = useState(400)
  const [paneHeight, setPaneHeight] = useState(300)
  const [isDragging, setIsDragging] = useState<'width' | 'height' | null>(null)
  const [outputFormat, setOutputFormat] = useState<OutputFormat>(urlState.format || 'ascii')
  const [formatPanelOpen, setFormatPanelOpen] = useState(false)
  const [isDarkMode, setIsDarkMode] = useState(false)
  const [copied, setCopied] = useState(false)
  const [renderedGraphviz, setRenderedGraphviz] = useState<SVGSVGElement | null>(null)
  const [mobileView, setMobileView] = useState<'editor' | 'results'>('editor')
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768)
  const [zoom, setZoom] = useState(1)
  const [panX, setPanX] = useState(0)
  const [panY, setPanY] = useState(0)
  const [isConverting, setIsConverting] = useState(false)
  const [isPanning, setIsPanning] = useState(false)
  const [panStartX, setPanStartX] = useState(0)
  const [panStartY, setPanStartY] = useState(0)

  const modulesLoadedRef = useRef(false)
  const vizInstanceRef = useRef<any>(null)
  const outputContainerRef = useRef<HTMLDivElement>(null)
  const outputContentRef = useRef<HTMLDivElement>(null)

  // Initialize Perl modules
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
          setLoadingState('loading-modules')

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
            const response = await fetch(`/graph-easy/${file}`)
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
          setLoadingState('ready')
          setError('') // Clear any loading errors

          // Auto-convert the first example
          setTimeout(() => convertGraph(EXAMPLES[0].graph), 100)
        } catch (err: any) {
          setLoadingState('error')
          setError(err.message)
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

  // Update URL when input or output format changes
  useEffect(() => {
    updateURL(input, outputFormat)
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

    const timeoutId = setTimeout(() => {
      setIsConverting(true)
      convertGraph()
    }, 500) // 500ms debounce

    return () => clearTimeout(timeoutId)
  }, [input, loadingState])

  // Auto-convert when output format changes
  useEffect(() => {
    if (loadingState === 'ready' && input.trim() && output) {
      // Only re-convert if we already have output
      // (don't convert on initial mount)
      setIsConverting(true)
      convertGraph()
    }
  }, [outputFormat])

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

  const convertGraph = (graphInput?: string) => {
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

    try {
      setError('')

      const escapedInput = textToConvert
        .replace(/\\/g, '\\\\')
        .replace(/\$/g, '\\$')

      // Map format to Perl method
      const formatMethodMap: Record<OutputFormat, string> = {
        ascii: 'as_ascii()',
        boxart: 'as_boxart()',
        html: 'as_html()',
        svg: 'as_svg()',
        graphviz: 'as_graphviz()',
        graphml: 'as_graphml()',
        vcg: 'as_vcg()',
        txt: 'as_txt()',
      }

      const perlMethod = formatMethodMap[outputFormat]

      const perlScript = `
        use strict;
        use warnings;
        use lib '/lib';
        use Graph::Easy;

        my $input = <<'END_INPUT';
${escapedInput}
END_INPUT

        my $output;

        eval {
          my $graph = Graph::Easy->new($input);

          if ($graph->error()) {
            $output = "Error: " . $graph->error();
          } else {
            $output = $graph->${perlMethod};
          }
        };

        if ($@) {
          $output = "Error: $@";
        }

        $output;
      `

      const result = window.Perl.eval(perlScript)

      if (result && result.startsWith('Error:')) {
        setError(result)
        setIsConverting(false)
        // Keep previous output visible
      } else if (result) {
        setOutput(result)
        setError('')
        // For non-graphviz formats, conversion is complete immediately
        // For graphviz, the rendering effect will set isConverting to false
        if (outputFormat !== 'graphviz') {
          setIsConverting(false)
        }
      } else {
        setError('No output generated')
        setIsConverting(false)
        // Keep previous output visible
      }
    } catch (err: any) {
      setError(`Conversion error: ${err.message}`)
      setIsConverting(false)
      // Keep previous output visible
    }
  }

  const handleExampleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const example = EXAMPLES.find(ex => ex.name === e.target.value)
    if (example) {
      setInput(example.graph)
      if (loadingState === 'ready') {
        convertGraph(example.graph)
      }
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

    // Center the content
    const scaledWidth = contentWidth * newZoom
    const scaledHeight = contentHeight * newZoom
    const newPanX = (containerWidth - scaledWidth) / 2 / newZoom
    const newPanY = (containerHeight - scaledHeight) / 2 / newZoom

    setZoom(newZoom)
    setPanX(newPanX)
    setPanY(newPanY)
  }

  // Handle resize dragging
  useEffect(() => {
    if (!isDragging) return

    const handleMouseMove = (e: MouseEvent) => {
      if (isDragging === 'width') {
        setPaneWidth(Math.max(300, Math.min(800, e.clientX)))
      } else if (isDragging === 'height') {
        setPaneHeight(Math.max(200, Math.min(600, e.clientY)))
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


  return (
    <div className="h-screen w-screen overflow-hidden bg-background font-sans">
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
          }}
        >
          {loadingState === 'ready' && output && !isConverting ? (
            outputFormat === 'graphviz' && renderedGraphviz ? (
              <div
                ref={(el) => {
                  if (el && renderedGraphviz) {
                    el.innerHTML = ''
                    el.appendChild(renderedGraphviz.cloneNode(true))
                  }
                }}
              />
            ) : outputFormat === 'html' || outputFormat === 'svg' ? (
              <div
                dangerouslySetInnerHTML={{ __html: output }}
              />
            ) : (
              <pre className="font-mono text-xs md:text-sm leading-relaxed text-foreground/90 select-text">
                {output}
              </pre>
            )
          ) : loadingState === 'ready' && !output ? (
            <div className="text-center text-muted-foreground">
              <p className="text-base md:text-lg">Enter graph notation to see output</p>
            </div>
          ) : null}
        </div>
      </div>

      {/* Input Pane - Full screen on mobile, floating on desktop */}
      <div
        className={`bg-card border border-border flex flex-col overflow-hidden transition-shadow duration-200 ${
          mobileView === 'results' ? 'hidden md:flex' : 'flex'
        } fixed inset-0 md:absolute md:top-8 md:left-8 md:rounded-lg md:shadow-2xl md:hover:shadow-3xl md:inset-auto`}
        style={!isMobile ? {
          width: `${paneWidth}px`,
          height: `${paneHeight}px`,
        } : {}}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-muted/30">
          <h1 className="text-sm font-medium text-foreground font-mono">
            {'[ graph ] ~~> [ easy ]'}
          </h1>
          <div className="flex items-center gap-2">
            {loadingState === 'ready' ? (
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" title="Ready" />
            ) : loadingState === 'error' ? (
              <div className="w-2 h-2 rounded-full bg-red-500" title="Error" />
            ) : null}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 flex flex-col p-4 gap-3 overflow-hidden">
          {/* Example selector */}
          <div className="flex items-center gap-2">
            <label className="text-xs text-muted-foreground shrink-0">Example:</label>
            <Select
              onChange={handleExampleChange}
              className="flex-1 text-xs h-8"
              defaultValue={EXAMPLES[0].name}
            >
              {EXAMPLES.map(ex => (
                <option key={ex.name} value={ex.name}>{ex.name}</option>
              ))}
            </Select>
          </div>

          {/* Input */}
          <Textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder=""
            className="flex-1 resize-none text-xs"
          />

          {/* Error display */}
          {error && loadingState === 'ready' && (
            <div className="text-xs text-destructive bg-destructive/10 px-3 py-2 rounded-md border border-destructive/20">
              {error}
            </div>
          )}
        </div>

        {/* Resize handles - Desktop only */}
        <div
          className="hidden md:block absolute right-0 top-0 bottom-0 w-1 cursor-ew-resize hover:bg-primary/20 transition-colors"
          onMouseDown={() => setIsDragging('width')}
        />
        <div
          className="hidden md:block absolute left-0 right-0 bottom-0 h-1 cursor-ns-resize hover:bg-primary/20 transition-colors"
          onMouseDown={() => setIsDragging('height')}
        />
        <div
          className="hidden md:block absolute right-0 bottom-0 w-4 h-4 cursor-nwse-resize hover:bg-primary/20 transition-colors rounded-tl-sm"
          onMouseDown={() => {
            setIsDragging('width')
            // Also enable height dragging
            setTimeout(() => setIsDragging('height'), 0)
          }}
        />
      </div>

      {/* Top Right Controls - Zoom, Copy and Dark Mode Toggle */}
      <div className="absolute top-4 right-4 md:top-8 md:right-8 z-10 flex gap-2">
        <div className="flex gap-1 bg-card border border-border rounded-lg overflow-hidden">
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
          <div className="flex items-center justify-center min-w-[3rem] px-2 text-xs font-medium text-muted-foreground border-x border-border">
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

      {/* Format Selector Panel - Top on mobile, Bottom Right on desktop, hidden on mobile when editor is shown */}
      <div className={`absolute top-4 right-4 md:top-auto md:bottom-8 md:right-8 ${
        mobileView === 'editor' ? 'hidden md:block' : 'block'
      }`}>
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
              <div className="p-2 space-y-1">
                {OUTPUT_FORMATS.map((format) => (
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
            </div>
          )}
        </div>
      </div>

      {/* Mobile View Toggle - Bottom Center (Mobile Only) */}
      <div className="md:hidden fixed bottom-4 left-1/2 transform -translate-x-1/2 z-50">
        <div className="bg-card border border-border rounded-lg shadow-2xl overflow-hidden flex">
          <Button
            onClick={() => setMobileView('editor')}
            size="sm"
            variant={mobileView === 'editor' ? 'default' : 'ghost'}
            className="rounded-r-none px-6 py-6"
          >
            <Code className="h-5 w-5 mr-2" />
            Editor
          </Button>
          <Button
            onClick={() => setMobileView('results')}
            size="sm"
            variant={mobileView === 'results' ? 'default' : 'ghost'}
            className="rounded-l-none px-6 py-6"
          >
            <Eye className="h-5 w-5 mr-2" />
            Results
          </Button>
        </div>
      </div>
    </div>
  )
}

export default App
