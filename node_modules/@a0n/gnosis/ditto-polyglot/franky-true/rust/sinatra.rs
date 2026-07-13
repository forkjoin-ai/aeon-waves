//! Sinatra framework recognizer (Ruby).
//!
//! Detects Sinatra apps by require pattern and extracts routes from
//! top-level get/post/put/delete DSL calls.

use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;
use crate::framework_recognizer::{
    FrameworkRecognizer, FrameworkTopology, HttpMethod, Middleware, Route,
};

pub struct SinatraRecognizer;

impl FrameworkRecognizer for SinatraRecognizer {
    fn framework_id(&self) -> &str {
        "sinatra"
    }

    fn language(&self) -> &str {
        "ruby"
    }

    fn detect(
        &self,
        source: &str,
        file_path: &str,
        cfgs: &[ControlFlowGraph],
    ) -> Option<FrameworkTopology> {
        let has_sinatra = source.contains("require 'sinatra'")
            || source.contains("require \"sinatra\"")
            || source.contains("require 'sinatra/base'")
            || source.contains("require \"sinatra/base\"");

        if !has_sinatra {
            return None;
        }

        let mut routes = Vec::new();
        let mut middleware = Vec::new();
        let mut listen_port = None;
        let mut middleware_order = 0;

        for line in source.lines() {
            let trimmed = line.trim();

            // Route detection: get '/path' do ... end
            for (method_name, method) in &[
                ("get", HttpMethod::Get),
                ("post", HttpMethod::Post),
                ("put", HttpMethod::Put),
                ("delete", HttpMethod::Delete),
                ("patch", HttpMethod::Patch),
                ("head", HttpMethod::Head),
                ("options", HttpMethod::Options),
            ] {
                // Pattern: get '/path' do
                // Pattern: get('/path') do
                let space_pattern = format!("{} ", method_name);
                let paren_pattern = format!("{}(", method_name);

                let path = if trimmed.starts_with(&space_pattern) {
                    extract_ruby_string(&trimmed[space_pattern.len()..])
                } else if trimmed.starts_with(&paren_pattern) {
                    extract_ruby_string(&trimmed[paren_pattern.len()..])
                } else {
                    None
                };

                if let Some(path) = path {
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

            // Middleware: use Rack::Logger
            if trimmed.starts_with("use ") && !trimmed.contains("require") {
                let name = trimmed[4..].trim().to_string();
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

            // Before filter.
            if trimmed.starts_with("before do") || trimmed.starts_with("before '") {
                middleware.push(Middleware {
                    name: "before_filter".to_string(),
                    path_prefix: extract_ruby_string(&trimmed[7..]),
                    handler_cfg_index: None,
                    order: middleware_order,
                });
                middleware_order += 1;
            }

            // Port: set :port, 4567
            if trimmed.starts_with("set :port,") {
                let rest = trimmed[10..].trim().trim_start_matches(',').trim();
                if let Ok(p) = rest.parse::<u16>() {
                    listen_port = Some(p);
                }
            }
        }

        if routes.is_empty() {
            return None;
        }

        Some(FrameworkTopology {
            framework: "sinatra".to_string(),
            language: "ruby".to_string(),
            file_path: file_path.to_string(),
            routes,
            middleware,
            listen_port,
            config: HashMap::new(),
        })
    }
}

/// Extract a Ruby string literal (single or double quoted).
fn extract_ruby_string(s: &str) -> Option<String> {
    let s = s.trim();
    let quote = s.chars().next()?;
    if quote != '\'' && quote != '"' {
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
