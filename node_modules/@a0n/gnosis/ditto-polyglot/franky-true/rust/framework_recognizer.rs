//! Framework recognition: detect server frameworks (Express, Flask, Gin, etc.)
//! from source code and extract route topologies for compilation to GG.
//!
//! This is the Ditto layer -- gnosis assumes the interface of whatever framework
//! the developer already knows. The diversity theorem (ch17) proves this is
//! topologically necessary: monoculture has irreducible waste.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;

/// A recognized HTTP method.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum HttpMethod {
    Get,
    Post,
    Put,
    Delete,
    Patch,
    Head,
    Options,
    All,
}

impl HttpMethod {
    pub fn as_str(&self) -> &'static str {
        match self {
            HttpMethod::Get => "GET",
            HttpMethod::Post => "POST",
            HttpMethod::Put => "PUT",
            HttpMethod::Delete => "DELETE",
            HttpMethod::Patch => "PATCH",
            HttpMethod::Head => "HEAD",
            HttpMethod::Options => "OPTIONS",
            HttpMethod::All => "ALL",
        }
    }
}

/// A route extracted from framework source code.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Route {
    /// HTTP method (GET, POST, etc.)
    pub method: HttpMethod,
    /// Path pattern (e.g. "/users/:id", "/api/v1/items")
    pub path: String,
    /// Name of the handler function.
    pub handler_name: String,
    /// Index into the CFGs array for the handler function body.
    pub handler_cfg_index: Option<usize>,
    /// Source byte range of the route declaration.
    pub source_start: usize,
    pub source_end: usize,
}

/// Middleware extracted from framework source code.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Middleware {
    /// Name or identifier of the middleware.
    pub name: String,
    /// Path prefix this middleware applies to (None = all routes).
    pub path_prefix: Option<String>,
    /// Index into the CFGs array for the middleware function body.
    pub handler_cfg_index: Option<usize>,
    /// Ordering: lower = earlier in chain.
    pub order: usize,
}

/// Complete framework topology extracted from source.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FrameworkTopology {
    /// Framework identifier (e.g. "express", "flask", "gin").
    pub framework: String,
    /// Language of the source file.
    pub language: String,
    /// Source file path.
    pub file_path: String,
    /// Extracted routes.
    pub routes: Vec<Route>,
    /// Extracted middleware chain.
    pub middleware: Vec<Middleware>,
    /// Listen port (if statically determinable).
    pub listen_port: Option<u16>,
    /// Framework-specific configuration values.
    pub config: HashMap<String, String>,
}

/// Result of framework detection on a source file.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FrameworkDetectionResult {
    /// The detected framework topology, if any.
    pub topology: Option<FrameworkTopology>,
    /// The underlying scan result (CFGs, function topologies).
    pub scan_result: crate::serialization::PolyglotScanResult,
}

/// Trait that all framework recognizers implement.
/// A recognizer examines source code (and optionally pre-extracted CFGs)
/// to detect a specific server framework and extract its route topology.
pub trait FrameworkRecognizer: Send + Sync {
    /// The framework identifier (e.g. "express", "gin", "flask").
    fn framework_id(&self) -> &str;

    /// The language this recognizer targets (e.g. "typescript", "go", "python").
    fn language(&self) -> &str;

    /// Detect whether the source uses this framework and extract the topology.
    /// Returns None if the framework is not detected.
    fn detect(
        &self,
        source: &str,
        file_path: &str,
        cfgs: &[ControlFlowGraph],
    ) -> Option<FrameworkTopology>;
}

/// Get all registered framework recognizers.
pub fn all_recognizers() -> Vec<Box<dyn FrameworkRecognizer>> {
    vec![
        Box::new(super::framework_recognizers::express::ExpressRecognizer),
        Box::new(super::framework_recognizers::flask::FlaskRecognizer),
        Box::new(super::framework_recognizers::gin::GinRecognizer),
        Box::new(super::framework_recognizers::hono::HonoRecognizer),
        Box::new(super::framework_recognizers::sinatra::SinatraRecognizer),
        Box::new(super::framework_recognizers::spring::SpringRecognizer),
    ]
}

/// Try all recognizers on a source file and return the first match.
pub fn detect_framework(
    source: &str,
    file_path: &str,
    cfgs: &[ControlFlowGraph],
) -> Option<FrameworkTopology> {
    for recognizer in all_recognizers() {
        if let Some(topology) = recognizer.detect(source, file_path, cfgs) {
            return Some(topology);
        }
    }
    None
}
