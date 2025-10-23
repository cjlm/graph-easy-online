import { useState, useEffect, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Select } from '@/components/ui/select'
import { Loader2, Settings, ChevronDown, ChevronUp, Moon, Sun } from 'lucide-react'
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
  const [loadingMessage, setLoadingMessage] = useState('Initializing WebPerl...')
  const [converting, setConverting] = useState(false)
  const [paneWidth, setPaneWidth] = useState(400)
  const [paneHeight, setPaneHeight] = useState(300)
  const [isDragging, setIsDragging] = useState<'width' | 'height' | null>(null)
  const [outputFormat, setOutputFormat] = useState<OutputFormat>(urlState.format || 'ascii')
  const [formatPanelOpen, setFormatPanelOpen] = useState(false)
  const [isDarkMode, setIsDarkMode] = useState(false)
  const modulesLoadedRef = useRef(false)

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
          setLoadingMessage('Loading Graph::Easy modules...')

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
          setLoadingMessage('Ready to convert!')
          setError('') // Clear any loading errors

          // Auto-convert the first example
          setTimeout(() => convertGraph(EXAMPLES[0].graph), 100)
        } catch (err: any) {
          setLoadingState('error')
          setLoadingMessage(`Error loading modules: ${err.message}`)
          setError(err.message)
        }
      }
    }

    // WebPerl and initialization script are loaded in index.html
    initPerl()
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

  // Auto-convert when input changes (debounced)
  useEffect(() => {
    if (loadingState !== 'ready' || !input.trim()) return

    const timeoutId = setTimeout(() => {
      convertGraph()
    }, 500) // 500ms debounce

    return () => clearTimeout(timeoutId)
  }, [input, loadingState])

  // Auto-convert when output format changes
  useEffect(() => {
    if (loadingState === 'ready' && input.trim() && output) {
      // Only re-convert if we already have output
      // (don't convert on initial mount)
      convertGraph()
    }
  }, [outputFormat])

  const convertGraph = (graphInput?: string) => {
    const textToConvert = graphInput || input

    if (!textToConvert.trim()) {
      setOutput('')
      setError('Please enter some graph notation.')
      return
    }

    if (loadingState !== 'ready') {
      setError('Please wait for modules to finish loading.')
      return
    }

    try {
      setConverting(true)
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
        // Keep previous output visible
      } else if (result) {
        setOutput(result)
        setError('')
      } else {
        setError('No output generated')
        // Keep previous output visible
      }
    } catch (err: any) {
      setError(`Conversion error: ${err.message}`)
      // Keep previous output visible
    } finally {
      setConverting(false)
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

  return (
    <div className="h-screen w-screen overflow-hidden bg-background font-sans">
      {/* Output - Full screen background */}
      <div className="absolute inset-0 flex items-center justify-center p-8">
        {loadingState === 'ready' && output ? (
          outputFormat === 'html' || outputFormat === 'svg' ? (
            <div
              className="flex items-center justify-center w-full h-full overflow-auto"
              dangerouslySetInnerHTML={{ __html: output }}
            />
          ) : (
            <pre className="font-mono text-sm leading-relaxed text-foreground/90 select-text">
              {output}
            </pre>
          )
        ) : loadingState === 'ready' && !output ? (
          <div className="text-center text-muted-foreground">
            <p className="text-lg">Enter graph notation to see output</p>
          </div>
        ) : null}
      </div>

      {/* Input Pane - Floating, resizable, top-left */}
      <div
        className="absolute top-8 left-8 bg-card border border-border rounded-lg shadow-2xl flex flex-col overflow-hidden transition-shadow duration-200 hover:shadow-3xl"
        style={{
          width: `${paneWidth}px`,
          height: `${paneHeight}px`,
        }}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-muted/30">
          <h1 className="text-sm font-medium text-foreground font-mono">
            {'[ graph ] ~~> [ easy ]'}
          </h1>
          <div className="flex items-center gap-2">
            {loadingState === 'initializing' || loadingState === 'loading-modules' ? (
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Loader2 className="w-3 h-3 animate-spin" />
                <span>{loadingMessage}</span>
              </div>
            ) : loadingState === 'ready' ? (
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" title="Ready" />
            ) : (
              <div className="w-2 h-2 rounded-full bg-red-500" title="Error" />
            )}
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
            placeholder="Enter graph notation..."
            className="flex-1 resize-none text-xs"
          />

          {/* Error display */}
          {error && loadingState === 'ready' && (
            <div className="text-xs text-destructive bg-destructive/10 px-3 py-2 rounded-md border border-destructive/20">
              {error}
            </div>
          )}

          {/* Convert button */}
          <Button
            onClick={() => convertGraph()}
            disabled={loadingState !== 'ready' || converting}
            className="w-full"
            size="sm"
          >
            {converting ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Converting...
              </>
            ) : (
              'Convert to ASCII'
            )}
          </Button>
        </div>

        {/* Resize handles */}
        <div
          className="absolute right-0 top-0 bottom-0 w-1 cursor-ew-resize hover:bg-primary/20 transition-colors"
          onMouseDown={() => setIsDragging('width')}
        />
        <div
          className="absolute left-0 right-0 bottom-0 h-1 cursor-ns-resize hover:bg-primary/20 transition-colors"
          onMouseDown={() => setIsDragging('height')}
        />
        <div
          className="absolute right-0 bottom-0 w-4 h-4 cursor-nwse-resize hover:bg-primary/20 transition-colors rounded-tl-sm"
          onMouseDown={() => {
            setIsDragging('width')
            // Also enable height dragging
            setTimeout(() => setIsDragging('height'), 0)
          }}
        />
      </div>

      {/* Dark Mode Toggle - Top Right */}
      <div className="absolute top-8 right-8">
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

      {/* Format Selector Panel - Bottom Right */}
      <div className="absolute bottom-8 right-8">
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
    </div>
  )
}

export default App
