//! Gin framework recognizer (Go).
//!
//! Detects Gin apps by import path and extracts routes from
//! r.GET/POST/PUT/DELETE calls.

use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;
use crate::framework_recognizer::{
    FrameworkRecognizer, FrameworkTopology, HttpMethod, Middleware, Route,
};

pub struct GinRecognizer;

impl FrameworkRecognizer for GinRecognizer {
    fn framework_id(&self) -> &str {
        "gin"
    }

    fn language(&self) -> &str {
        "go"
    }

    fn detect(
        &self,
        source: &str,
        file_path: &str,
        cfgs: &[ControlFlowGraph],
    ) -> Option<FrameworkTopology> {
        let has_gin = source.contains("\"github.com/gin-gonic/gin\"");

        if !has_gin {
            return None;
        }

        let mut routes = Vec::new();
        let mut middleware = Vec::new();
        let mut middleware_order = 0;

        // Detect router variable names.
        let router_names = detect_router_names(source);

        for line in source.lines() {
            let trimmed = line.trim();

            for router in &router_names {
                // Route detection: r.GET("/path", handler)
                for (method_name, method) in &[
                    ("GET", HttpMethod::Get),
                    ("POST", HttpMethod::Post),
                    ("PUT", HttpMethod::Put),
                    ("DELETE", HttpMethod::Delete),
                    ("PATCH", HttpMethod::Patch),
                    ("HEAD", HttpMethod::Head),
                    ("OPTIONS", HttpMethod::Options),
                    ("Any", HttpMethod::All),
                    ("Handle", HttpMethod::All),
                ] {
                    let pattern = format!("{}.{}(", router, method_name);
                    if let Some(start) = trimmed.find(&pattern) {
                        let after_paren = start + pattern.len();
                        if let Some(path) = extract_string_arg(&trimmed[after_paren..]) {
                            let handler_name = extract_go_handler(&trimmed[after_paren..])
                                .unwrap_or_else(|| {
                                    format!("{}_{}", method_name.to_lowercase(), sanitize_path(&path))
                                });

                            let handler_cfg_index = cfgs
                                .iter()
                                .position(|cfg| cfg.function_name == handler_name);

                            routes.push(Route {
                                method: method.clone(),
                                path,
                                handler_name,
                                handler_cfg_index,
                                source_start: 0,
                                source_end: 0,
                            });
                        }
                    }
                }

                // Middleware detection: r.Use(middleware)
                let use_pattern = format!("{}.Use(", router);
                if let Some(start) = trimmed.find(&use_pattern) {
                    let after_paren = start + use_pattern.len();
                    let rest = &trimmed[after_paren..];
                    let name: String = rest
                        .chars()
                        .take_while(|c| c.is_alphanumeric() || *c == '_' || *c == '.')
                        .collect();
                    if !name.is_empty() {
                        middleware.push(Middleware {
                            name,
                            path_prefix: None,
                            handler_cfg_index: None,
                            order: middleware_order,
                        });
                        middleware_order += 1;
                    }
                }
            }
        }

        if routes.is_empty() {
            return None;
        }

        // Detect listen port from r.Run(":8080")
        let listen_port = detect_gin_port(source, &router_names);

        Some(FrameworkTopology {
            framework: "gin".to_string(),
            language: "go".to_string(),
            file_path: file_path.to_string(),
            routes,
            middleware,
            listen_port,
            config: HashMap::new(),
        })
    }
}

/// Detect Gin router variable names.
fn detect_router_names(source: &str) -> Vec<String> {
    let mut names = Vec::new();

    for line in source.lines() {
        let trimmed = line.trim();

        // r := gin.Default()
        // r := gin.New()
        for factory in &["gin.Default()", "gin.New()"] {
            if trimmed.contains(factory) {
                if let Some(name) = trimmed.split(":=").next().map(|n| n.trim().to_string()) {
                    if !name.is_empty() {
                        names.push(name);
                    }
                }
            }
        }
    }

    if names.is_empty() {
        names.push("r".to_string());
        names.push("router".to_string());
    }

    names
}

/// Extract the handler name from a Gin route call.
fn extract_go_handler(s: &str) -> Option<String> {
    let after_path = s.find(',')? + 1;
    let rest = s[after_path..].trim();

    // Skip inline funcs.
    if rest.starts_with("func(") || rest.starts_with("func (") {
        return None;
    }

    let name: String = rest
        .chars()
        .take_while(|c| c.is_alphanumeric() || *c == '_' || *c == '.')
        .collect();

    if name.is_empty() { None } else { Some(name) }
}

/// Extract string argument.
fn extract_string_arg(s: &str) -> Option<String> {
    let s = s.trim();
    let quote = s.chars().next()?;
    if quote != '"' {
        return None;
    }
    let rest = &s[1..];
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

/// Detect port from r.Run(":8080")
fn detect_gin_port(source: &str, router_names: &[String]) -> Option<u16> {
    for line in source.lines() {
        let trimmed = line.trim();
        for router in router_names {
            let pattern = format!("{}.Run(", router);
            if let Some(start) = trimmed.find(&pattern) {
                let after = start + pattern.len();
                let rest = &trimmed[after..];
                // Extract ":8080" and parse the port.
                if let Some(port_str) = extract_string_arg(rest) {
                    if let Some(port) = port_str.strip_prefix(':') {
                        if let Ok(p) = port.parse::<u16>() {
                            return Some(p);
                        }
                    }
                }
            }
        }
    }
    None
}

fn sanitize_path(path: &str) -> String {
    path.chars()
        .map(|c| if c.is_alphanumeric() { c } else { '_' })
        .collect::<String>()
        .trim_matches('_')
        .to_string()
}
