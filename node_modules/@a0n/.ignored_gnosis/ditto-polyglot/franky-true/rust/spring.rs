//! Spring Boot framework recognizer (Java).
//!
//! Detects Spring Boot controllers by annotation patterns and extracts
//! routes from @GetMapping, @PostMapping, @RequestMapping.

use std::collections::HashMap;

use crate::cfg::ControlFlowGraph;
use crate::framework_recognizer::{
    FrameworkRecognizer, FrameworkTopology, HttpMethod, Route,
};

pub struct SpringRecognizer;

impl FrameworkRecognizer for SpringRecognizer {
    fn framework_id(&self) -> &str {
        "spring"
    }

    fn language(&self) -> &str {
        "java"
    }

    fn detect(
        &self,
        source: &str,
        file_path: &str,
        cfgs: &[ControlFlowGraph],
    ) -> Option<FrameworkTopology> {
        let has_spring = source.contains("@RestController")
            || source.contains("@Controller")
            || source.contains("org.springframework.web");

        if !has_spring {
            return None;
        }

        let mut routes = Vec::new();
        let mut class_prefix = String::new();

        let lines: Vec<&str> = source.lines().collect();

        for (i, line) in lines.iter().enumerate() {
            let trimmed = line.trim();

            // Class-level @RequestMapping("/api/v1")
            if trimmed.starts_with("@RequestMapping") && is_class_level(&lines, i) {
                if let Some(path) = extract_annotation_path(trimmed) {
                    class_prefix = path;
                }
            }

            // Method-level route annotations.
            for (annotation, method) in &[
                ("@GetMapping", HttpMethod::Get),
                ("@PostMapping", HttpMethod::Post),
                ("@PutMapping", HttpMethod::Put),
                ("@DeleteMapping", HttpMethod::Delete),
                ("@PatchMapping", HttpMethod::Patch),
            ] {
                if trimmed.starts_with(annotation) {
                    let path = extract_annotation_path(trimmed).unwrap_or_default();
                    let full_path = format!("{}{}", class_prefix, path);

                    if let Some(func_name) = find_java_method(&lines, i + 1) {
                        let handler_cfg_index = cfgs
                            .iter()
                            .position(|cfg| cfg.function_name == func_name);

                        routes.push(Route {
                            method: method.clone(),
                            path: if full_path.is_empty() {
                                "/".to_string()
                            } else {
                                full_path
                            },
                            handler_name: func_name,
                            handler_cfg_index,
                            source_start: 0,
                            source_end: 0,
                        });
                    }
                }
            }

            // @RequestMapping on methods with explicit method.
            if trimmed.starts_with("@RequestMapping") && !is_class_level(&lines, i) {
                let path = extract_annotation_path(trimmed).unwrap_or_default();
                let full_path = format!("{}{}", class_prefix, path);
                let methods = extract_request_methods(trimmed);

                if let Some(func_name) = find_java_method(&lines, i + 1) {
                    let handler_cfg_index = cfgs
                        .iter()
                        .position(|cfg| cfg.function_name == func_name);

                    for method in methods {
                        routes.push(Route {
                            method,
                            path: if full_path.is_empty() {
                                "/".to_string()
                            } else {
                                full_path.clone()
                            },
                            handler_name: func_name.clone(),
                            handler_cfg_index,
                            source_start: 0,
                            source_end: 0,
                        });
                    }
                }
            }
        }

        if routes.is_empty() {
            return None;
        }

        // Spring Boot default port.
        let listen_port = detect_spring_port(source);

        Some(FrameworkTopology {
            framework: "spring".to_string(),
            language: "java".to_string(),
            file_path: file_path.to_string(),
            routes,
            middleware: Vec::new(),
            listen_port,
            config: HashMap::new(),
        })
    }
}

/// Extract path from annotation: @GetMapping("/users") or @GetMapping(value = "/users")
fn extract_annotation_path(line: &str) -> Option<String> {
    let paren_start = line.find('(')?;
    let rest = &line[paren_start + 1..];

    // Simple case: @GetMapping("/users")
    if rest.starts_with('"') {
        let end = rest[1..].find('"')?;
        return Some(rest[1..end + 1].to_string());
    }

    // Named parameter: @RequestMapping(value = "/users")
    if let Some(val_pos) = rest.find("value") {
        let after_val = &rest[val_pos + 5..];
        let eq_pos = after_val.find('=')?;
        let after_eq = after_val[eq_pos + 1..].trim();
        if after_eq.starts_with('"') {
            let end = after_eq[1..].find('"')?;
            return Some(after_eq[1..end + 1].to_string());
        }
    }

    // path parameter.
    if let Some(path_pos) = rest.find("path") {
        let after = &rest[path_pos + 4..];
        let eq_pos = after.find('=')?;
        let after_eq = after[eq_pos + 1..].trim();
        if after_eq.starts_with('"') {
            let end = after_eq[1..].find('"')?;
            return Some(after_eq[1..end + 1].to_string());
        }
    }

    None
}

/// Extract request methods from @RequestMapping(method = RequestMethod.GET)
fn extract_request_methods(line: &str) -> Vec<HttpMethod> {
    let mut methods = Vec::new();

    if line.contains("RequestMethod.GET") {
        methods.push(HttpMethod::Get);
    }
    if line.contains("RequestMethod.POST") {
        methods.push(HttpMethod::Post);
    }
    if line.contains("RequestMethod.PUT") {
        methods.push(HttpMethod::Put);
    }
    if line.contains("RequestMethod.DELETE") {
        methods.push(HttpMethod::Delete);
    }
    if line.contains("RequestMethod.PATCH") {
        methods.push(HttpMethod::Patch);
    }

    if methods.is_empty() {
        methods.push(HttpMethod::Get);
    }

    methods
}

/// Check if a @RequestMapping is at the class level (before class declaration).
fn is_class_level(lines: &[&str], annotation_line: usize) -> bool {
    for line in lines.iter().skip(annotation_line + 1) {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('@') {
            continue;
        }
        return trimmed.contains("class ");
    }
    false
}

/// Find the Java method name following an annotation.
fn find_java_method(lines: &[&str], start: usize) -> Option<String> {
    for line in lines.iter().skip(start) {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('@') {
            continue;
        }

        // Look for method declaration: public ResponseEntity<...> methodName(...)
        // or: public String methodName(...)
        if let Some(paren_pos) = trimmed.find('(') {
            let before_paren = &trimmed[..paren_pos];
            // Method name is the last word before the parenthesis.
            let name = before_paren
                .split_whitespace()
                .last()
                .map(|s| s.to_string());
            if let Some(ref n) = name {
                if !n.is_empty() && n != "class" && n != "interface" {
                    return name;
                }
            }
        }
        break;
    }
    None
}

/// Detect Spring Boot server port from application properties or annotations.
fn detect_spring_port(source: &str) -> Option<u16> {
    // Check for @SpringBootApplication with server.port property.
    // This is typically in application.properties, not Java source.
    // For now, return default 8080.
    if source.contains("@SpringBootApplication") {
        return Some(8080);
    }
    None
}
