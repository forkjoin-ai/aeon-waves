//! Flask framework recognizer.
//!
//! Detects Flask apps by import pattern and extracts routes from
//! @app.route() decorators.

use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;
use crate::framework_recognizer::{
    FrameworkRecognizer, FrameworkTopology, HttpMethod, Middleware, Route,
};

pub struct FlaskRecognizer;

impl FrameworkRecognizer for FlaskRecognizer {
    fn framework_id(&self) -> &str {
        "flask"
    }

    fn language(&self) -> &str {
        "python"
    }

    fn detect(
        &self,
        source: &str,
        file_path: &str,
        cfgs: &[ControlFlowGraph],
    ) -> Option<FrameworkTopology> {
        let has_flask = source.contains("from flask import")
            || source.contains("import flask");

        if !has_flask {
            return None;
        }

        let mut routes = Vec::new();
        let mut middleware = Vec::new();
        let mut listen_port = None;
        let mut middleware_order = 0;

        let lines: Vec<&str> = source.lines().collect();

        for (i, line) in lines.iter().enumerate() {
            let trimmed = line.trim();

            // Route detection: @app.route('/path', methods=['GET', 'POST'])
            if let Some(route_info) = parse_route_decorator(trimmed) {
                // The function name is on the next non-decorator, non-empty line.
                if let Some(func_name) = find_decorated_function(&lines, i + 1) {
                    let handler_cfg_index = cfgs
                        .iter()
                        .position(|cfg| cfg.function_name == func_name);

                    for method in route_info.methods {
                        routes.push(Route {
                            method,
                            path: route_info.path.clone(),
                            handler_name: func_name.clone(),
                            handler_cfg_index,
                            source_start: 0,
                            source_end: 0,
                        });
                    }
                }
            }

            // Shorthand decorators: @app.get('/path'), @app.post('/path')
            for (decorator, method) in &[
                ("@app.get(", HttpMethod::Get),
                ("@app.post(", HttpMethod::Post),
                ("@app.put(", HttpMethod::Put),
                ("@app.delete(", HttpMethod::Delete),
                ("@app.patch(", HttpMethod::Patch),
            ] {
                if trimmed.starts_with(decorator) {
                    if let Some(path) = extract_string_arg(&trimmed[decorator.len()..]) {
                        if let Some(func_name) = find_decorated_function(&lines, i + 1) {
                            let handler_cfg_index = cfgs
                                .iter()
                                .position(|cfg| cfg.function_name == func_name);

                            routes.push(Route {
                                method: method.clone(),
                                path,
                                handler_name: func_name,
                                handler_cfg_index,
                                source_start: 0,
                                source_end: 0,
                            });
                        }
                    }
                }
            }

            // Before_request middleware.
            if trimmed.starts_with("@app.before_request") {
                if let Some(func_name) = find_decorated_function(&lines, i + 1) {
                    middleware.push(Middleware {
                        name: func_name,
                        path_prefix: None,
                        handler_cfg_index: None,
                        order: middleware_order,
                    });
                    middleware_order += 1;
                }
            }

            // Listen port: app.run(port=5000)
            if trimmed.contains("app.run(") {
                if let Some(port) = extract_port_kwarg(trimmed) {
                    listen_port = Some(port);
                }
            }
        }

        if routes.is_empty() {
            return None;
        }

        Some(FrameworkTopology {
            framework: "flask".to_string(),
            language: "python".to_string(),
            file_path: file_path.to_string(),
            routes,
            middleware,
            listen_port,
            config: HashMap::new(),
        })
    }
}

struct RouteDecoratorInfo {
    path: String,
    methods: Vec<HttpMethod>,
}

/// Parse @app.route('/path', methods=['GET', 'POST'])
fn parse_route_decorator(line: &str) -> Option<RouteDecoratorInfo> {
    let prefix = "@app.route(";
    if !line.starts_with(prefix) {
        return None;
    }

    let rest = &line[prefix.len()..];
    let path = extract_string_arg(rest)?;

    // Extract methods if specified.
    let methods = if let Some(methods_pos) = rest.find("methods=") {
        let methods_rest = &rest[methods_pos + 8..];
        parse_methods_list(methods_rest)
    } else {
        vec![HttpMethod::Get]
    };

    Some(RouteDecoratorInfo { path, methods })
}

/// Parse a Python list of method strings: ['GET', 'POST']
fn parse_methods_list(s: &str) -> Vec<HttpMethod> {
    let mut methods = Vec::new();
    let s = s.trim();

    // Simple parser: find strings between quotes.
    let mut in_quote = false;
    let mut quote_char = ' ';
    let mut current = String::new();

    for c in s.chars() {
        if !in_quote && (c == '\'' || c == '"') {
            in_quote = true;
            quote_char = c;
            current.clear();
        } else if in_quote && c == quote_char {
            in_quote = false;
            match current.to_uppercase().as_str() {
                "GET" => methods.push(HttpMethod::Get),
                "POST" => methods.push(HttpMethod::Post),
                "PUT" => methods.push(HttpMethod::Put),
                "DELETE" => methods.push(HttpMethod::Delete),
                "PATCH" => methods.push(HttpMethod::Patch),
                "HEAD" => methods.push(HttpMethod::Head),
                "OPTIONS" => methods.push(HttpMethod::Options),
                _ => {}
            }
        } else if in_quote {
            current.push(c);
        } else if c == ']' {
            break;
        }
    }

    if methods.is_empty() {
        vec![HttpMethod::Get]
    } else {
        methods
    }
}

/// Find the function definition following a decorator line.
fn find_decorated_function(lines: &[&str], start: usize) -> Option<String> {
    for line in lines.iter().skip(start) {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('@') {
            continue;
        }
        if let Some(rest) = trimmed.strip_prefix("def ") {
            let name: String = rest.chars().take_while(|c| c.is_alphanumeric() || *c == '_').collect();
            if !name.is_empty() {
                return Some(name);
            }
        }
        if let Some(rest) = trimmed.strip_prefix("async def ") {
            let name: String = rest.chars().take_while(|c| c.is_alphanumeric() || *c == '_').collect();
            if !name.is_empty() {
                return Some(name);
            }
        }
        break;
    }
    None
}

/// Extract string argument from beginning of text.
fn extract_string_arg(s: &str) -> Option<String> {
    let s = s.trim();
    let quote = s.chars().next()?;
    if quote != '\'' && quote != '"' {
        return None;
    }
    let rest = &s[1..];
    let end = rest.find(quote)?;
    Some(rest[..end].to_string())
}

/// Extract port= keyword argument from app.run() call.
fn extract_port_kwarg(s: &str) -> Option<u16> {
    if let Some(port_pos) = s.find("port=") {
        let rest = &s[port_pos + 5..];
        let num_str: String = rest.chars().take_while(|c| c.is_ascii_digit()).collect();
        return num_str.parse().ok();
    }
    None
}
