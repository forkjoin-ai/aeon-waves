use serde::{Deserialize, Serialize};

/// A span in source code, used to map GG topology nodes back to original source locations.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct SourceSpan {
    pub file: String,
    pub start_line: usize,
    pub start_column: usize,
    pub end_line: usize,
    pub end_column: usize,
    pub start_byte: usize,
    pub end_byte: usize,
}

impl SourceSpan {
    pub fn from_tree_sitter(file: &str, node: &tree_sitter::Node) -> Self {
        let start = node.start_position();
        let end = node.end_position();
        Self {
            file: file.to_string(),
            // tree-sitter uses 0-based lines, we use 1-based
            start_line: start.row + 1,
            start_column: start.column + 1,
            end_line: end.row + 1,
            end_column: end.column + 1,
            start_byte: node.start_byte(),
            end_byte: node.end_byte(),
        }
    }

    pub fn synthetic(file: &str) -> Self {
        Self {
            file: file.to_string(),
            start_line: 0,
            start_column: 0,
            end_line: 0,
            end_column: 0,
            start_byte: 0,
            end_byte: 0,
        }
    }
}

/// Maps GG topology node IDs back to their original source locations.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct SourceMap {
    pub entries: Vec<SourceMapEntry>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SourceMapEntry {
    /// The GG node id (e.g. "fn_entry_0").
    pub gg_node_id: String,
    /// The original source span.
    pub span: SourceSpan,
    /// Optional snippet of the source text.
    pub snippet: Option<String>,
}

impl SourceMap {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }

    pub fn add(&mut self, gg_node_id: String, span: SourceSpan, snippet: Option<String>) {
        self.entries.push(SourceMapEntry {
            gg_node_id,
            span,
            snippet,
        });
    }

    pub fn find_by_gg_id(&self, gg_node_id: &str) -> Option<&SourceMapEntry> {
        self.entries.iter().find(|e| e.gg_node_id == gg_node_id)
    }
}
