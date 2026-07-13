//! Hono framework recognizer.
//!
//! Detects Hono apps by import pattern. Same shape as Express
//! but from the 'hono' package.

use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;
use crate::framework_recognizer::{
    FrameworkRecognizer, FrameworkTopology, HttpMethod, Middleware, Route,
};

pub struct HonoRecognizer;

impl FrameworkRecognizer for HonoRecognizer {
    fn framework_id(&self) -> &str {
        "hono"
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
        let has_hono = source.contains("from 'hono'")
            || source.contains("from \"hono\"")
            || source.contains("require('hono')")
            || source.contains("require(\"hono\")");

        if !has_hono {
            return None;
        }

        let mut routes = Vec::new();
        let mut middleware = Vec::new();
        let mut middleware_order = 0;

        let app_names = detect_app_names(source);

        for line in source.lines() {
            let trimmed = line.trim();

            for app_name in &app_names {
                // Route detection: same pattern as Express.
                for (method_name, method) in &[
                    ("get", HttpMethod::Get),
                    ("post", HttpMethod::Post),
                    ("put", HttpMethod::Put),
                    ("delete", HttpMethod::Delete),
                    ("patch", HttpMethod::Patch),
                    ("all", HttpMethod::All),
                ] {
                    let pattern = format!("{}.{}(", app_name, method_name);
                    if let Some(start) = trimmed.find(&pattern) {
                        let after = start + pattern.len();
                        if let Some(path) = extract_string_arg(&trimmed[after..]) {
                            let handler_name = format!(
                                "{}_{}",
                                method_name,
                                sanitize_path(&path)
                            );

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

                // Middleware: app.use(path, middleware)
                let use_pattern = format!("{}.use(", app_name);
                if let Some(start) = trimmed.find(&use_pattern) {
                    let after = start + use_pattern.len();
                    let rest = &trimmed[after..];

                    let (path_prefix, name_start) = if rest.starts_with('\'') || rest.starts_with('"') {
                        let path = extract_string_arg(rest);
                        let after_path = rest.find(',').map(|i| i + 1).unwrap_or(0);
                        (path, after_path)
                    } else {
                        (None, 0)
                    };

                    let name_rest = rest[name_start..].trim();
                    let name: String = name_rest
                        .chars()
                        .take_while(|c| c.is_alphanumeric() || *c == '_')
                        .collect();

                    if !name.is_empty() {
                        middleware.push(Middleware {
                            name,
                            path_prefix,
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

        Some(FrameworkTopology {
            framework: "hono".to_string(),
            language: "typescript".to_string(),
            file_path: file_path.to_string(),
            routes,
            middleware,
            listen_port: None,
            config: HashMap::new(),
        })
    }
}

fn detect_app_names(source: &str) -> Vec<String> {
    let mut names = Vec::new();

    for line in source.lines() {
        let trimmed = line.trim();
        for prefix in &["const ", "let ", "var "] {
            if trimmed.starts_with(prefix) && trimmed.contains("new Hono(") {
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
        names.push("app".to_string());
    }

    names
}

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

fn sanitize_path(path: &str) -> String {
    path.chars()
        .map(|c| if c.is_alphanumeric() { c } else { '_' })
        .collect::<String>()
        .trim_matches('_')
        .to_string()
}
