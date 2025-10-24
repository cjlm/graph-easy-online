/**
 * Attribute management system
 *
 * Handles validation, inheritance, and type checking for graph attributes
 */

export interface GraphAttributes {
  // Graph-level attributes
  type?: 'directed' | 'undirected'
  flow?: 'east' | 'west' | 'north' | 'south' | 'up' | 'down'
  label?: string
  title?: string
  bgcolor?: string
  [key: string]: any
}

export interface NodeAttributes {
  label?: string
  shape?: 'rect' | 'circle' | 'ellipse' | 'point' | 'invisible'
  fill?: string
  color?: string
  border?: string
  width?: number
  height?: number
  [key: string]: any
}

export interface EdgeAttributes {
  label?: string
  style?: 'solid' | 'dashed' | 'dotted' | 'wave' | 'double' | 'bold'
  color?: string
  arrowStyle?: 'forward' | 'back' | 'both' | 'none'
  lineWidth?: number
  [key: string]: any
}

/**
 * Manages attributes with validation and inheritance
 */
export class AttributeManager {
  private attributes: Map<string, any> = new Map()
  private defaults: Map<string, any> = new Map()

  constructor(defaults?: Record<string, any>) {
    if (defaults) {
      for (const [key, value] of Object.entries(defaults)) {
        this.defaults.set(key, value)
      }
    }
  }

  /**
   * Set an attribute value
   */
  set(name: string, value: any): void {
    // TODO: Add validation based on attribute type
    this.attributes.set(name, value)
  }

  /**
   * Set attribute for a selector (e.g., "node.city")
   */
  setForSelector(selector: string, name: string, value: any): void {
    // For now, just set the attribute
    // In full implementation, this would handle class-based attributes
    this.set(`${selector}.${name}`, value)
  }

  /**
   * Get an attribute value
   */
  get(name: string): any {
    if (this.attributes.has(name)) {
      return this.attributes.get(name)
    }

    if (this.defaults.has(name)) {
      return this.defaults.get(name)
    }

    return undefined
  }

  /**
   * Get all attributes
   */
  getAll(): Record<string, any> {
    const result: Record<string, any> = {}

    // First add defaults
    for (const [key, value] of this.defaults) {
      result[key] = value
    }

    // Then override with actual values
    for (const [key, value] of this.attributes) {
      result[key] = value
    }

    return result
  }

  /**
   * Delete an attribute
   */
  delete(name: string): boolean {
    return this.attributes.delete(name)
  }

  /**
   * Check if attribute exists
   */
  has(name: string): boolean {
    return this.attributes.has(name) || this.defaults.has(name)
  }

  /**
   * Clear all attributes
   */
  clear(): void {
    this.attributes.clear()
  }

  /**
   * Get attribute count
   */
  size(): number {
    return this.attributes.size
  }
}

/**
 * Attribute validator
 */
export class AttributeValidator {
  private static validNodeShapes = new Set([
    'rect', 'circle', 'ellipse', 'point', 'invisible',
    'diamond', 'triangle', 'pentagon', 'hexagon',
  ])

  private static validEdgeStyles = new Set([
    'solid', 'dashed', 'dotted', 'wave', 'double', 'bold',
  ])

  private static validArrowStyles = new Set([
    'forward', 'back', 'both', 'none',
  ])

  /**
   * Validate a node attribute
   */
  static validateNodeAttribute(name: string, value: any): boolean {
    switch (name) {
      case 'shape':
        return this.validNodeShapes.has(value)

      case 'width':
      case 'height':
        return typeof value === 'number' && value > 0

      case 'fill':
      case 'color':
        return this.isValidColor(value)

      default:
        return true // Unknown attributes are allowed
    }
  }

  /**
   * Validate an edge attribute
   */
  static validateEdgeAttribute(name: string, value: any): boolean {
    switch (name) {
      case 'style':
        return this.validEdgeStyles.has(value)

      case 'arrowStyle':
        return this.validArrowStyles.has(value)

      case 'lineWidth':
        return typeof value === 'number' && value > 0

      case 'color':
        return this.isValidColor(value)

      default:
        return true
    }
  }

  /**
   * Check if a value is a valid color
   */
  private static isValidColor(value: any): boolean {
    if (typeof value !== 'string') return false

    // Hex color
    if (/^#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$/.test(value)) {
      return true
    }

    // RGB/RGBA
    if (/^rgba?\(/.test(value)) {
      return true
    }

    // Named color (basic check)
    if (/^[a-z]+$/.test(value)) {
      return true
    }

    return false
  }

  /**
   * Validate and coerce an attribute value
   */
  static validateAndCoerce(
    objectType: 'node' | 'edge' | 'group' | 'graph',
    name: string,
    value: any
  ): any {
    // Type coercion
    if (name === 'width' || name === 'height' || name === 'lineWidth') {
      const num = Number(value)
      if (!isNaN(num) && num > 0) {
        return num
      }
      throw new Error(`Invalid ${name}: must be a positive number`)
    }

    // Validation
    if (objectType === 'node' && !this.validateNodeAttribute(name, value)) {
      throw new Error(`Invalid node attribute ${name}=${value}`)
    }

    if (objectType === 'edge' && !this.validateEdgeAttribute(name, value)) {
      throw new Error(`Invalid edge attribute ${name}=${value}`)
    }

    return value
  }
}

/**
 * Color utilities
 */
export class ColorUtils {
  private static namedColors: Record<string, string> = {
    black: '#000000',
    white: '#FFFFFF',
    red: '#FF0000',
    green: '#00FF00',
    blue: '#0000FF',
    yellow: '#FFFF00',
    cyan: '#00FFFF',
    magenta: '#FF00FF',
    gray: '#808080',
    lightgray: '#D3D3D3',
    darkgray: '#A9A9A9',
    // Add more as needed...
  }

  /**
   * Convert color name to hex
   */
  static toHex(color: string): string {
    // Already hex
    if (color.startsWith('#')) {
      return color.length === 4
        ? this.expandShortHex(color)
        : color
    }

    // Named color
    if (color in this.namedColors) {
      return this.namedColors[color]
    }

    // RGB(A)
    if (color.startsWith('rgb')) {
      return this.rgbToHex(color)
    }

    return color
  }

  /**
   * Expand short hex (#RGB to #RRGGBB)
   */
  private static expandShortHex(hex: string): string {
    const r = hex[1]
    const g = hex[2]
    const b = hex[3]
    return `#${r}${r}${g}${g}${b}${b}`
  }

  /**
   * Convert RGB/RGBA to hex
   */
  private static rgbToHex(rgb: string): string {
    const match = rgb.match(/\d+/g)
    if (!match || match.length < 3) return rgb

    const [r, g, b] = match.map(Number)

    return `#${[r, g, b]
      .map(x => x.toString(16).padStart(2, '0'))
      .join('')}`
  }
}
