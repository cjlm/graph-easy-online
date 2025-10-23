//! Graph::Easy Layout Engine in Rust
//!
//! High-performance grid-based layout algorithm compiled to WebAssembly.

use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};

#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

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
    #[serde(default)]
    pub config: LayoutConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeData {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub label: String,
    #[serde(default)]
    pub width: u32,
    #[serde(default)]
    pub height: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EdgeData {
    pub id: String,
    pub from: String,
    pub to: String,
    #[serde(default)]
    pub label: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutConfig {
    #[serde(default = "default_flow")]
    pub flow: String,
    #[serde(default = "default_node_spacing")]
    pub node_spacing: i32,
    #[serde(default = "default_rank_spacing")]
    pub rank_spacing: i32,
}

impl Default for LayoutConfig {
    fn default() -> Self {
        Self {
            flow: "east".to_string(),
            node_spacing: 3,
            rank_spacing: 5,
        }
    }
}

fn default_flow() -> String { "east".to_string() }
fn default_node_spacing() -> i32 { 3 }
fn default_rank_spacing() -> i32 { 5 }

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
    #[serde(skip_serializing_if = "Option::is_none")]
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
}

// ===== Layout Engine =====

#[wasm_bindgen]
pub struct LayoutEngine {
    _placeholder: u8,
}

#[wasm_bindgen]
impl LayoutEngine {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        Self { _placeholder: 0 }
    }

    pub fn layout(&self, graph_json: JsValue) -> Result<JsValue, JsValue> {
        let graph: GraphData = serde_wasm_bindgen::from_value(graph_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse graph: {}", e)))?;

        let result = compute_layout(&graph)
            .map_err(|e| JsValue::from_str(&e))?;

        serde_wasm_bindgen::to_value(&result)
            .map_err(|e| JsValue::from_str(&format!("Failed to serialize result: {}", e)))
    }

    #[wasm_bindgen(js_name = getVersion)]
    pub fn get_version() -> String {
        env!("CARGO_PKG_VERSION").to_string()
    }
}

// ===== Main Layout Algorithm =====

fn compute_layout(graph: &GraphData) -> Result<LayoutResult, String> {
    if graph.nodes.is_empty() {
        return Ok(LayoutResult {
            nodes: vec![],
            edges: vec![],
            bounds: Bounds { width: 0, height: 0 },
        });
    }

    // Build index
    let node_map: HashMap<String, &NodeData> = graph
        .nodes
        .iter()
        .map(|n| (n.id.clone(), n))
        .collect();

    // Topological sort to find layers
    let layers = topological_sort(graph)?;

    // Assign grid positions
    let node_positions = assign_positions(&layers, &node_map, &graph.config);

    // Route edges
    let edge_paths = route_edges(graph, &node_positions);

    // Calculate bounds
    let bounds = calculate_bounds(&node_positions);

    Ok(LayoutResult {
        nodes: node_positions,
        edges: edge_paths,
        bounds,
    })
}

// ===== Topological Sort =====

fn topological_sort(graph: &GraphData) -> Result<Vec<Vec<String>>, String> {
    let mut adj: HashMap<String, Vec<String>> = HashMap::new();
    let mut in_degree: HashMap<String, usize> = HashMap::new();

    // Initialize
    for node in &graph.nodes {
        adj.insert(node.id.clone(), Vec::new());
        in_degree.insert(node.id.clone(), 0);
    }

    // Build adjacency list and in-degrees
    for edge in &graph.edges {
        // Check if nodes exist
        if !in_degree.contains_key(&edge.from) {
            return Err(format!("Edge from unknown node: {}", edge.from));
        }
        if !in_degree.contains_key(&edge.to) {
            return Err(format!("Edge to unknown node: {}", edge.to));
        }

        adj.get_mut(&edge.from).unwrap().push(edge.to.clone());
        *in_degree.get_mut(&edge.to).unwrap() += 1;
    }

    // Kahn's algorithm with layer assignment
    let mut layers: Vec<Vec<String>> = Vec::new();
    let mut current_layer: Vec<String> = in_degree
        .iter()
        .filter(|(_, &deg)| deg == 0)
        .map(|(id, _)| id.clone())
        .collect();

    // Sort for deterministic output
    current_layer.sort();

    while !current_layer.is_empty() {
        layers.push(current_layer.clone());

        let mut next_layer = Vec::new();
        let mut seen = HashSet::new();

        for node_id in &current_layer {
            if let Some(neighbors) = adj.get(node_id) {
                for neighbor in neighbors {
                    let degree = in_degree.get_mut(neighbor).unwrap();
                    *degree -= 1;

                    if *degree == 0 && !seen.contains(neighbor) {
                        next_layer.push(neighbor.clone());
                        seen.insert(neighbor.clone());
                    }
                }
            }
        }

        next_layer.sort();
        current_layer = next_layer;
    }

    // Check if all nodes were processed (no cycles)
    let total_nodes: usize = layers.iter().map(|l| l.len()).sum();
    if total_nodes != graph.nodes.len() {
        // Graph has cycles - use all nodes in one layer
        eprintln!("Warning: Graph contains cycles, using simplified layout");
        let mut all_nodes: Vec<String> = graph.nodes.iter().map(|n| n.id.clone()).collect();
        all_nodes.sort();
        return Ok(vec![all_nodes]);
    }

    Ok(layers)
}

// ===== Position Assignment =====

fn assign_positions(
    layers: &[Vec<String>],
    node_map: &HashMap<String, &NodeData>,
    config: &LayoutConfig,
) -> Vec<NodePosition> {
    let mut positions = Vec::new();

    let horizontal = config.flow == "east" || config.flow == "west";

    for (layer_idx, layer) in layers.iter().enumerate() {
        for (node_idx, node_id) in layer.iter().enumerate() {
            let node = node_map.get(node_id).unwrap();

            let width = if node.width > 0 { node.width } else {
                node.label.len().max(node.name.len()).max(3) as u32 + 4
            };
            let height = if node.height > 0 { node.height } else { 3 };

            let (x, y) = if horizontal {
                // Layers go left-to-right (or right-to-left)
                let x = (layer_idx as i32) * (width as i32 + config.node_spacing);
                let y = (node_idx as i32) * (height as i32 + config.rank_spacing);
                (x, y)
            } else {
                // Layers go top-to-bottom (or bottom-to-top)
                let x = (node_idx as i32) * (width as i32 + config.node_spacing);
                let y = (layer_idx as i32) * (height as i32 + config.rank_spacing);
                (x, y)
            };

            positions.push(NodePosition {
                id: node.id.clone(),
                x,
                y,
                width,
                height,
                label: if !node.label.is_empty() {
                    node.label.clone()
                } else {
                    node.name.clone()
                },
            });
        }
    }

    positions
}

// ===== Edge Routing =====

fn route_edges(graph: &GraphData, node_positions: &[NodePosition]) -> Vec<EdgePath> {
    let pos_map: HashMap<String, &NodePosition> = node_positions
        .iter()
        .map(|p| (p.id.clone(), p))
        .collect();

    let mut edge_paths = Vec::new();

    for edge in &graph.edges {
        let from_pos = match pos_map.get(&edge.from) {
            Some(p) => p,
            None => continue, // Skip if node not found
        };

        let to_pos = match pos_map.get(&edge.to) {
            Some(p) => p,
            None => continue,
        };

        // Simple straight-line routing for now
        // Start from right-middle of source node
        let start_x = from_pos.x + from_pos.width as i32;
        let start_y = from_pos.y + (from_pos.height as i32 / 2);

        // End at left-middle of target node
        let end_x = to_pos.x;
        let end_y = to_pos.y + (to_pos.height as i32 / 2);

        // Create path with intermediate points for manhattan routing
        let points = if start_y == end_y {
            // Horizontal line
            vec![
                Point { x: start_x, y: start_y },
                Point { x: end_x, y: end_y },
            ]
        } else {
            // Manhattan routing: horizontal then vertical
            let mid_x = start_x + (end_x - start_x) / 2;

            vec![
                Point { x: start_x, y: start_y },
                Point { x: mid_x, y: start_y },
                Point { x: mid_x, y: end_y },
                Point { x: end_x, y: end_y },
            ]
        };

        edge_paths.push(EdgePath {
            id: edge.id.clone(),
            from: edge.from.clone(),
            to: edge.to.clone(),
            points,
            label: edge.label.clone(),
        });
    }

    edge_paths
}

// ===== Bounds Calculation =====

fn calculate_bounds(positions: &[NodePosition]) -> Bounds {
    if positions.is_empty() {
        return Bounds { width: 0, height: 0 };
    }

    let max_x = positions
        .iter()
        .map(|p| p.x + p.width as i32)
        .max()
        .unwrap_or(0);

    let max_y = positions
        .iter()
        .map(|p| p.y + p.height as i32)
        .max()
        .unwrap_or(0);

    Bounds {
        width: max_x.max(0) as u32,
        height: max_y.max(0) as u32,
    }
}

// ===== Tests =====

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_graph() {
        let graph = GraphData {
            nodes: vec![
                NodeData {
                    id: "a".to_string(),
                    name: "A".to_string(),
                    label: "A".to_string(),
                    width: 5,
                    height: 3,
                },
                NodeData {
                    id: "b".to_string(),
                    name: "B".to_string(),
                    label: "B".to_string(),
                    width: 5,
                    height: 3,
                },
            ],
            edges: vec![EdgeData {
                id: "e1".to_string(),
                from: "a".to_string(),
                to: "b".to_string(),
                label: None,
            }],
            config: LayoutConfig::default(),
        };

        let result = compute_layout(&graph).unwrap();

        assert_eq!(result.nodes.len(), 2);
        assert_eq!(result.edges.len(), 1);
        assert!(result.bounds.width > 0);
        assert!(result.bounds.height > 0);
    }

    #[test]
    fn test_topological_sort() {
        let graph = GraphData {
            nodes: vec![
                NodeData {
                    id: "a".to_string(),
                    name: "A".to_string(),
                    label: "A".to_string(),
                    width: 0,
                    height: 0,
                },
                NodeData {
                    id: "b".to_string(),
                    name: "B".to_string(),
                    label: "B".to_string(),
                    width: 0,
                    height: 0,
                },
                NodeData {
                    id: "c".to_string(),
                    name: "C".to_string(),
                    label: "C".to_string(),
                    width: 0,
                    height: 0,
                },
            ],
            edges: vec![
                EdgeData {
                    id: "e1".to_string(),
                    from: "a".to_string(),
                    to: "b".to_string(),
                    label: None,
                },
                EdgeData {
                    id: "e2".to_string(),
                    from: "b".to_string(),
                    to: "c".to_string(),
                    label: None,
                },
            ],
            config: LayoutConfig::default(),
        };

        let layers = topological_sort(&graph).unwrap();

        assert_eq!(layers.len(), 3);
        assert_eq!(layers[0], vec!["a"]);
        assert_eq!(layers[1], vec!["b"]);
        assert_eq!(layers[2], vec!["c"]);
    }
}
