use std::io;
use std::process::Command;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GnosisResult {
    pub exit_code: i32,
    pub stdout: String,
    pub stderr: String,
}

#[derive(Debug, Clone)]
pub struct GnosisClient {
    binary: String,
}

impl Default for GnosisClient {
    fn default() -> Self {
        Self {
            binary: String::from("gnosis"),
        }
    }
}

impl GnosisClient {
    pub fn new(binary: impl Into<String>) -> Self {
        let binary = binary.into();
        if binary.trim().is_empty() {
            return Self::default();
        }
        Self { binary }
    }

    pub fn run<I, S>(&self, args: I) -> io::Result<GnosisResult>
    where
        I: IntoIterator<Item = S>,
        S: AsRef<str>,
    {
        let output = Command::new(&self.binary)
            .args(args.into_iter().map(|arg| arg.as_ref().to_string()))
            .output()?;

        Ok(GnosisResult {
            exit_code: output.status.code().unwrap_or(1),
            stdout: String::from_utf8_lossy(&output.stdout).to_string(),
            stderr: String::from_utf8_lossy(&output.stderr).to_string(),
        })
    }

    pub fn lint(&self, topology_path: &str, target: Option<&str>, as_json: bool) -> io::Result<GnosisResult> {
        let mut args = vec![String::from("lint"), topology_path.to_string()];
        if let Some(target_value) = target {
            args.push(String::from("--target"));
            args.push(target_value.to_string());
        }
        if as_json {
            args.push(String::from("--json"));
        }
        self.run(args)
    }

    pub fn analyze(&self, target_path: &str, as_json: bool) -> io::Result<GnosisResult> {
        let mut args = vec![String::from("analyze"), target_path.to_string()];
        if as_json {
            args.push(String::from("--json"));
        }
        self.run(args)
    }

    pub fn verify(&self, topology_path: &str, tla_out: Option<&str>) -> io::Result<GnosisResult> {
        let mut args = vec![String::from("verify"), topology_path.to_string()];
        if let Some(tla_out_path) = tla_out {
            args.push(String::from("--tla-out"));
            args.push(tla_out_path.to_string());
        }
        self.run(args)
    }

    pub fn run_topology(&self, topology_path: &str, native: bool) -> io::Result<GnosisResult> {
        let mut args = vec![String::from("run"), topology_path.to_string()];
        if native {
            args.push(String::from("--native"));
        }
        self.run(args)
    }

    pub fn test_topology(&self, test_path: &str) -> io::Result<GnosisResult> {
        self.run(["test", test_path])
    }
}
