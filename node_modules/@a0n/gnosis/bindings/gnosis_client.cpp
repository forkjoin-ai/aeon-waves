#include <array>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <string>
#include <sys/wait.h>
#include <vector>

struct GnosisResult {
  int exit_code;
  std::string output;
};

class GnosisClient {
 public:
  explicit GnosisClient(std::string binary = "gnosis")
      : binary_(binary.empty() ? "gnosis" : std::move(binary)) {}

  GnosisResult run(const std::vector<std::string>& args) const {
    std::string command = quote(binary_);
    for (const auto& arg : args) {
      command += " " + quote(arg);
    }
    command += " 2>&1";

    std::array<char, 256> buffer{};
    std::string output;

    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(command.c_str(), "r"), pclose);
    if (!pipe) {
      throw std::runtime_error("failed to open gnosis process");
    }

    while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe.get()) != nullptr) {
      output.append(buffer.data());
    }

    int status = pclose(pipe.release());
#ifdef WEXITSTATUS
    if (status >= 0) {
      status = WEXITSTATUS(status);
    }
#endif
    if (status < 0) {
      status = 1;
    }

    return GnosisResult{status, output};
  }

  GnosisResult lint(const std::string& topology_path, const std::string& target = "", bool as_json = false) const {
    std::vector<std::string> args = {"lint", topology_path};
    if (!target.empty()) {
      args.push_back("--target");
      args.push_back(target);
    }
    if (as_json) {
      args.push_back("--json");
    }
    return run(args);
  }

  GnosisResult analyze(const std::string& target_path, bool as_json = false) const {
    std::vector<std::string> args = {"analyze", target_path};
    if (as_json) {
      args.push_back("--json");
    }
    return run(args);
  }

  GnosisResult verify(const std::string& topology_path, const std::string& tla_out = "") const {
    std::vector<std::string> args = {"verify", topology_path};
    if (!tla_out.empty()) {
      args.push_back("--tla-out");
      args.push_back(tla_out);
    }
    return run(args);
  }

  GnosisResult run_topology(const std::string& topology_path, bool native = false) const {
    std::vector<std::string> args = {"run", topology_path};
    if (native) {
      args.push_back("--native");
    }
    return run(args);
  }

  GnosisResult test_topology(const std::string& topology_path) const {
    return run({"test", topology_path});
  }

 private:
  static std::string quote(const std::string& value) {
    std::string quoted = "'";
    for (const char ch : value) {
      if (ch == '\'') {
        quoted += "'\\''";
      } else {
        quoted.push_back(ch);
      }
    }
    quoted.push_back('\'');
    return quoted;
  }

  std::string binary_;
};
