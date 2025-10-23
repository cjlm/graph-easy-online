//! Graph::Easy Layout Engine in Rust
//!
//! This is a high-performance layout engine compiled to WebAssembly
//! that implements the Graph::Easy manhattan grid-based layout algorithm.

use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// When the `wee_alloc` feature is enabled, use `wee_alloc` as the global allocator
#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

// Set up panic hook for better error messages
#[wasm_bindgen(start)]
pub fn init() {
    #[cfg(feature = "console_error_panic_hook")]
    console_error_panic_hook::set_once();
}

// ===== Data Structures =====

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphData {
    pub nodes: Vec<NodeData>,
    pub edges: Vec<EdgeData>,
    pub config: LayoutConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeData {
    pub id: String,
    pub name: String,
    pub label: String,
    #[serde(default)]
    pub width: u32,
    #[serde(default)]
    pub height: u32,
    #[serde(default)]
    pub shape: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EdgeData {
    pub id: String,
    pub from: String,
    pub to: String,
    #[serde(default)]
    pub label: Option<String>,
    #[serde(default)]
    pub style: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutConfig {
    #[serde(default = "default_flow")]
    pub flow: String,
    #[serde(default = "default_directed")]
    pub directed: bool,
    #[serde(default = "default_node_spacing")]
    pub node_spacing: u32,
    #[serde(default = "default_rank_spacing")]
    pub rank_spacing: u32,
}

fn default_flow() -> String { "east".to_string() }
fn default_directed() -> bool { true }
fn default_node_spacing() -> u32 { 2 }
fn default_rank_spacing() -> u32 { 3 }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutResult {
    pub nodes: Vec<NodePosition>,
    pub edges: Vec<EdgePath>,
    pub bounds: Bounds,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodePosition {
    pub id: String,
    pub x: i32,
    pub y: i32,
    pub width: u32,
    pub height: u32,
    pub label: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EdgePath {
    pub id: String,
    pub from: String,
    pub to: String,
    pub points: Vec<Point>,
    pub label: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Point {
    pub x: i32,
    pub y: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bounds {
    pub width: u32,
    pub height: u32,
    pub min_x: i32,
    pub min_y: i32,
    pub max_x: i32,
    pub max_y: i32,
}

// ===== Main Layout Engine =====

#[wasm_bindgen]
pub struct LayoutEngine {
    grid: Grid,
}

#[wasm_bindgen]
impl LayoutEngine {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        Self {
            grid: Grid::new(),
        }
    }

    /// Compute layout for the given graph
    pub fn layout(&mut self, graph_json: JsValue) -> Result<JsValue, JsValue> {
        // Deserialize input
        let graph: GraphData = serde_wasm_bindgen::from_value(graph_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse graph: {}", e)))?;

        // Perform layout
        let result = self.compute_layout(&graph)
            .map_err(|e| JsValue::from_str(&e))?;

        // Serialize result
        serde_wasm_bindgen::to_value(&result)
            .map_err(|e| JsValue::from_str(&format!("Failed to serialize result: {}", e)))
    }

    /// Get version string
    #[wasm_bindgen(js_name = getVersion)]
    pub fn get_version() -> String {
        env!("CARGO_PKG_VERSION").to_string()
    }
}

impl LayoutEngine {
    fn compute_layout(&mut self, graph: &GraphData) -> Result<LayoutResult, String> {
        // 1. Build internal graph representation
        let mut node_map: HashMap<String, NodeData> = HashMap::new();
        for node in &graph.nodes {
            node_map.insert(node.id.clone(), node.clone());
        }

        // 2. Perform topological sort to determine layers
        let layers = self.topological_sort(graph)?;

        // 3. Assign positions based on layers and flow direction
        let node_positions = self.assign_positions(&layers, &node_map, &graph.config);

        // 4. Route edges using A* pathfinding
        let edge_paths = self.route_edges(graph, &node_positions)?;

        // 5. Calculate bounds
        let bounds = self.calculate_bounds(&node_positions);

        Ok(LayoutResult {
            nodes: node_positions,
            edges: edge_paths,
            bounds,
        })
    }

    fn topological_sort(&self, graph: &GraphData) -> Result<Vec<Vec<String>>, String> {
        // Build adjacency list
        let mut adj: HashMap<String, Vec<String>> = HashMap::new();
        let mut in_degree: HashMap<String, usize> = HashMap::new();

        // Initialize
        for node in &graph.nodes {
            adj.insert(node.id.clone(), Vec::new());
            in_degree.insert(node.id.clone(), 0);
        }

        // Build graph
        for edge in &graph.edges {
            adj.get_mut(&edge.from)
                .ok_or("Edge from unknown node")?
                .push(edge.to.clone());

            *in_degree.get_mut(&edge.to)
                .ok_or("Edge to unknown node")? += 1;
        }

        // Kahn's algorithm with layer assignment
        let mut layers: Vec<Vec<String>> = Vec::new();
        let mut current_layer: Vec<String> = in_degree
            .iter()
            .filter(|(_, &degree)| degree == 0)
            .map(|(id, _)| id.clone())
            .collect();

        while !current_layer.is_empty() {
            layers.push(current_layer.clone());

            let mut next_layer = Vec::new();

            for node_id in &current_layer {
                if let Some(neighbors) = adj.get(node_id) {
                    for neighbor in neighbors {
                        let degree = in_degree.get_mut(neighbor)
                            .ok_or("Neighbor not found")?;
                        *degree -= 1;

                        if *degree == 0 {
                            next_layer.push(neighbor.clone());
                        }
                    }
                }
            }

            current_layer = next_layer;
        }

        // Check for cycles
        let total_nodes: usize = layers.iter().map(|l| l.len()).sum();
        if total_nodes != graph.nodes.len() {
            return Err("Graph contains cycles".to_string());
        }

        Ok(layers)
    }

    fn assign_positions(
        &self,
        layers: &[Vec<String>],
        node_map: &HashMap<String, NodeData>,
        config: &LayoutConfig,
    ) -> Vec<NodePosition> {
        let mut positions = Vec::new();

        // Determine if we're laying out horizontally or vertically
        let horizontal = matches!(config.flow.as_str(), "east" | "west");

        for (layer_idx, layer) in layers.iter().enumerate() {
            for (node_idx, node_id) in layer.iter().enumerate() {
                let node = node_map.get(node_id).unwrap();

                // Calculate position based on flow direction
                let (x, y) = if horizontal {
                    // East/West flow: layers are columns
                    let x = (layer_idx as i32) * (config.node_spacing as i32 + 10);
                    let y = (node_idx as i32) * (config.rank_spacing as i32 + 5);
                    (x, y)
                } else {
                    // North/South flow: layers are rows
                    let x = (node_idx as i32) * (config.node_spacing as i32 + 10);
                    let y = (layer_idx as i32) * (config.rank_spacing as i32 + 5);
                    (x, y)
                };

                positions.push(NodePosition {
                    id: node.id.clone(),
                    x,
                    y,
                    width: if node.width > 0 { node.width } else { 8 },
                    height: if node.height > 0 { node.height } else { 3 },
                    label: node.label.clone(),
                });
            }
        }

        positions
    }

    fn route_edges(
        &self,
        graph: &GraphData,
        node_positions: &[NodePosition],
    ) -> Result<Vec<EdgePath>, String> {
        let mut edge_paths = Vec::new();

        // Create position lookup
        let pos_map: HashMap<String, &NodePosition> = node_positions
            .iter()
            .map(|p| (p.id.clone(), p))
            .collect();

        for edge in &graph.edges {
            let from_pos = pos_map.get(&edge.from)
                .ok_or_else(|| format!("Node {} not found", edge.from))?;
            let to_pos = pos_map.get(&edge.to)
                .ok_or_else(|| format!("Node {} not found", edge.to))?;

            // For now, simple direct path
            // In full implementation, use A* to route around nodes
            let points = vec![
                Point {
                    x: from_pos.x + from_pos.width as i32,
                    y: from_pos.y + from_pos.height as i32 / 2,
                },
                Point {
                    x: to_pos.x,
                    y: to_pos.y + to_pos.height as i32 / 2,
                },
            ];

            edge_paths.push(EdgePath {
                id: edge.id.clone(),
                from: edge.from.clone(),
                to: edge.to.clone(),
                points,
                label: edge.label.clone(),
            });
        }

        Ok(edge_paths)
    }

    fn calculate_bounds(&self, positions: &[NodePosition]) -> Bounds {
        let mut min_x = i32::MAX;
        let mut min_y = i32::MAX;
        let mut max_x = i32::MIN;
        let mut max_y = i32::MIN;

        for pos in positions {
            min_x = min_x.min(pos.x);
            min_y = min_y.min(pos.y);
            max_x = max_x.max(pos.x + pos.width as i32);
            max_y = max_y.max(pos.y + pos.height as i32);
        }

        Bounds {
            width: (max_x - min_x) as u32,
            height: (max_y - min_y) as u32,
            min_x,
            min_y,
            max_x,
            max_y,
        }
    }
}

// ===== Grid for collision detection =====

struct Grid {
    cells: HashMap<(i32, i32), CellState>,
}

#[derive(Debug, Clone, Copy, PartialEq)]
enum CellState {
    Empty,
    Node,
    Edge,
}

impl Grid {
    fn new() -> Self {
        Self {
            cells: HashMap::new(),
        }
    }

    fn mark_node(&mut self, x: i32, y: i32, width: u32, height: u32) {
        for dx in 0..width as i32 {
            for dy in 0..height as i32 {
                self.cells.insert((x + dx, y + dy), CellState::Node);
            }
        }
    }

    fn is_free(&self, x: i32, y: i32) -> bool {
        self.cells.get(&(x, y)).map(|&s| s == CellState::Empty).unwrap_or(true)
    }
}

// ===== Tests =====

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_layout() {
        let graph = GraphData {
            nodes: vec![
                NodeData {
                    id: "a".to_string(),
                    name: "A".to_string(),
                    label: "A".to_string(),
                    width: 3,
                    height: 1,
                    shape: "rect".to_string(),
                },
                NodeData {
                    id: "b".to_string(),
                    name: "B".to_string(),
                    label: "B".to_string(),
                    width: 3,
                    height: 1,
                    shape: "rect".to_string(),
                },
            ],
            edges: vec![
                EdgeData {
                    id: "e1".to_string(),
                    from: "a".to_string(),
                    to: "b".to_string(),
                    label: None,
                    style: "solid".to_string(),
                },
            ],
            config: LayoutConfig {
                flow: "east".to_string(),
                directed: true,
                node_spacing: 2,
                rank_spacing: 3,
            },
        };

        let mut engine = LayoutEngine::new();
        let result = engine.compute_layout(&graph).unwrap();

        assert_eq!(result.nodes.len(), 2);
        assert_eq!(result.edges.len(), 1);
    }
}
