//! Express.js framework recognizer.
//!
//! Detects Express apps by import pattern and extracts routes from
//! app.get/post/put/delete/patch/use calls.

use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;
use crate::framework_recognizer::{
    FrameworkRecognizer, FrameworkTopology, HttpMethod, Middleware, Route,
};

pub struct ExpressRecognizer;

impl FrameworkRecognizer for ExpressRecognizer {
    fn framework_id(&self) -> &str {
        "express"
    }

    fn language(&self) -> &str {
        "typescript"
    }

    fn detect(
        &self,
        source: &str,
        file_path: &str,
        cfgs: &[ControlFlowGraph],
    ) -> Option<FrameworkTopology> {
        // Detect Express import/require patterns.
        let has_express = source.contains("require('express')")
            || source.contains("require(\"express\")")
            || source.contains("from 'express'")
            || source.contains("from \"express\"");

        if !has_express {
            return None;
        }

        let mut routes = Vec::new();
        let mut middleware = Vec::new();
        let mut listen_port = None;
        let mut middleware_order = 0;

        // Detect the app variable name (usually `app` or `router`).
        let app_names = detect_app_names(source);

        for line in source.lines() {
            let trimmed = line.trim();

            for app_name in &app_names {
                // Route detection: app.get('/path', handler)
                if let Some(route) = parse_route_call(trimmed, app_name, cfgs) {
                    routes.push(route);
                }

                // Middleware detection: app.use(middleware)
                if let Some(mw) = parse_use_call(trimmed, app_name, middleware_order) {
                    middleware.push(mw);
                    middleware_order += 1;
                }

                // Listen detection: app.listen(3000)
                if let Some(port) = parse_listen_call(trimmed, app_name) {
                    listen_port = Some(port);
                }
            }
        }

        if routes.is_empty() && middleware.is_empty() {
            return None;
        }

        Some(FrameworkTopology {
            framework: "express".to_string(),
            language: "typescript".to_string(),
            file_path: file_path.to_string(),
            routes,
            middleware,
            listen_port,
            config: HashMap::new(),
        })
    }
}

/// Detect the variable name(s) used for the Express app instance.
/// e.g. `const app = express()` or `const router = express.Router()`
fn detect_app_names(source: &str) -> Vec<String> {
    let mut names = Vec::new();

    for line in source.lines() {
        let trimmed = line.trim();

        // const app = express()
        // let app = express()
        // var app = express()
        for prefix in &["const ", "let ", "var "] {
            if trimmed.starts_with(prefix) && trimmed.contains("express()") {
                if let Some(name) = trimmed
                    .strip_prefix(prefix)
                    .and_then(|rest| rest.split('=').next())
                    .map(|n| n.trim().to_string())
                {
                    if !name.is_empty() {
                        names.push(name);
                    }
                }
            }

            // const router = express.Router()
            if trimmed.starts_with(prefix) && trimmed.contains("express.Router()") {
                if let Some(name) = trimmed
                    .strip_prefix(prefix)
                    .and_then(|rest| rest.split('=').next())
                    .map(|n| n.trim().to_string())
                {
                    if !name.is_empty() {
                        names.push(name);
                    }
                }
            }
        }
    }

    if names.is_empty() {
        // Fallback: assume `app` is the name.
        names.push("app".to_string());
    }

    names
}

/// Parse a route call like `app.get('/users', handler)` or `app.post('/users', (req, res) => {...})`
fn parse_route_call(
    line: &str,
    app_name: &str,
    cfgs: &[ControlFlowGraph],
) -> Option<Route> {
    let methods = [
        ("get", HttpMethod::Get),
        ("post", HttpMethod::Post),
        ("put", HttpMethod::Put),
        ("delete", HttpMethod::Delete),
        ("patch", HttpMethod::Patch),
        ("head", HttpMethod::Head),
        ("options", HttpMethod::Options),
        ("all", HttpMethod::All),
    ];

    for (method_name, method) in &methods {
        let pattern = format!("{}.{}(", app_name, method_name);
        if let Some(start) = line.find(&pattern) {
            let after_paren = start + pattern.len();
            if let Some(path) = extract_string_arg(&line[after_paren..]) {
                let handler_name = extract_handler_name(&line[after_paren..])
                    .unwrap_or_else(|| format!("{}_{}", method_name, sanitize_path(&path)));

                // Try to find a matching CFG for the handler.
                let handler_cfg_index = cfgs
                    .iter()
                    .position(|cfg| cfg.function_name == handler_name);

                return Some(Route {
                    method: method.clone(),
                    path,
                    handler_name,
                    handler_cfg_index,
                    source_start: start,
                    source_end: start + line.len(),
                });
            }
        }
    }

    None
}

/// Parse a middleware call like `app.use(cors())` or `app.use('/api', authMiddleware)`
fn parse_use_call(line: &str, app_name: &str, order: usize) -> Option<Middleware> {
    let pattern = format!("{}.use(", app_name);
    if let Some(start) = line.find(&pattern) {
        let after_paren = start + pattern.len();
        let rest = &line[after_paren..];

        // Check if first arg is a path prefix.
        let (path_prefix, name_rest) = if rest.starts_with('\'') || rest.starts_with('"') {
            let path = extract_string_arg(rest);
            // Skip past the path arg and comma.
            let after_path = rest
                .find(',')
                .map(|i| &rest[i + 1..])
                .unwrap_or(rest);
            (path, after_path.trim())
        } else {
            (None, rest)
        };

        // Extract middleware name.
        let name = if let Some(paren_pos) = name_rest.find('(') {
            name_rest[..paren_pos].trim().to_string()
        } else if let Some(paren_pos) = name_rest.find(')') {
            name_rest[..paren_pos].trim().to_string()
        } else {
            name_rest.trim().to_string()
        };

        if !name.is_empty() {
            return Some(Middleware {
                name,
                path_prefix,
                handler_cfg_index: None,
                order,
            });
        }
    }

    None
}

/// Parse a listen call like `app.listen(3000)` and extract the port.
fn parse_listen_call(line: &str, app_name: &str) -> Option<u16> {
    let pattern = format!("{}.listen(", app_name);
    if let Some(start) = line.find(&pattern) {
        let after_paren = start + pattern.len();
        let rest = &line[after_paren..];
        // Extract the first numeric argument.
        let num_str: String = rest.chars().take_while(|c| c.is_ascii_digit()).collect();
        return num_str.parse().ok();
    }
    None
}

/// Extract a string literal argument from the beginning of a string.
/// Handles both single and double quotes.
fn extract_string_arg(s: &str) -> Option<String> {
    let s = s.trim();
    let quote = s.chars().next()?;
    if quote != '\'' && quote != '"' && quote != '`' {
        return None;
    }
    let rest = &s[1..];
    let end = rest.find(quote)?;
    Some(rest[..end].to_string())
}

/// Extract a named handler function from a route call.
/// In `app.get('/users', getUsers)`, extracts "getUsers".
/// In `app.get('/users', (req, res) => {...})`, returns None (anonymous).
fn extract_handler_name(s: &str) -> Option<String> {
    // Skip past the path argument.
    let after_path = s.find(',')? + 1;
    let rest = s[after_path..].trim();

    // If it starts with ( or async, it's an inline handler.
    if rest.starts_with('(') || rest.starts_with("async") || rest.starts_with("function") {
        return None;
    }

    // Otherwise, it's a named reference.
    let name: String = rest
        .chars()
        .take_while(|c| c.is_alphanumeric() || *c == '_' || *c == '$')
        .collect();

    if name.is_empty() {
        None
    } else {
        Some(name)
    }
}

/// Sanitize a path for use as a function name suffix.
fn sanitize_path(path: &str) -> String {
    path.chars()
        .map(|c| if c.is_alphanumeric() { c } else { '_' })
        .collect::<String>()
        .trim_matches('_')
        .to_string()
}
