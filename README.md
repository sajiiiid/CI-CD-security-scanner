
# CI/CD DevSecOps Security Scanner (netscan)

A portable, containerized, single-purpose network security auditing CLI tool guarded by a robust, multi-stage GitHub Actions CI/CD pipeline. 

This project demonstrates production-grade shell scripting, automated unit/integration testing with `bats-core`, lightweight containerization with Alpine Linux, and strict automated repository gates.

---

## 🚀 Key Features

The core scanner (`netscan.sh`) is built with defensive Bash scripting standards (`set -euo pipefail`) and performs four fast security checks:

1. **Port Scanning:** Probes the top 20 most common TCP ports using `nmap`, skipping ICMP pinging (`-Pn`) to bypass restrictive firewalls.
2. **SSL/TLS Expiry Audit:** Intercepts secure handshakes on Port 443 via `openssl s_client`, converts timestamps to Unix Epoch seconds, and calculates certificate days remaining.
3. **HTTP Security Headers:** Inspects HTTP response headers using `curl` to verify modern browser protection protocols (HSTS, CSP, X-Frame-Options, X-Content-Type-Options).
4. **DNS Mapping Records:** Audits authoritative routing layers (A, MX, and NS records) via the `host` command, with custom filters to swallow local network resolver warnings.

---

## 🛠️ System Architecture

```text
[Local Git Push] 
       │
       ▼
 [GitHub Actions Runner (ubuntu-latest)]
       │
 ┌─────┴────────────────────────┐
 │ JOB 1: Linting               │ 
 │ └── ShellCheck (static)      │ ──► [Fail: Halt Pipeline]
 └─────┬────────────────────────┘
       │ (Needs: lint)
       ▼
 ┌─────┴────────────────────────┐
 │ JOB 2: Testing               │ 
 │ └── BATS-core (Unit/Int)     │ ──► [Fail: Halt Pipeline]
 └─────┬────────────────────────┘
       │ (Needs: test)
       ▼
 ┌─────┴────────────────────────┐
 │ JOB 3: Packaging             │ 
 │ └── Docker Build (Alpine)    │ ──► [Success: Artifact Ready]
 └──────────────────────────────┘
```

---

## 📦 Local Installation

To run this scanner and its test suite natively on your local machine:

### Prerequisites

Ensure you have the required dependencies installed. On Ubuntu/Pop!_OS:

```bash
# Update package repositories
sudo apt update

# Install network utilities
sudo apt install -y nmap openssl curl bind9-dnsutils shellcheck

# Install BATS-core testing framework from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
cd .. && rm -rf bats-core
```

### Cloning & Permissions

```bash
# Clone the repository
git clone https://github.com/sajiiiid/CI-CD-security-scanner.git
cd CI-CD-security-scanner

# Grant execution permissions to the script
chmod +x netscan.sh
```

---

## 💻 Usage

```bash
# Display the help menu
./netscan.sh --help

# Run all security audits against a target
./netscan.sh --target example.com --scan all

# Run only a specific scan module (ports, ssl, headers, or dns)
./netscan.sh --target example.com --scan ssl
```

---

## 🧪 Automated Testing

We enforce continuous verification. The test suite inside `test/netscan.bats` contains 8 isolated unit and integration test blocks verifying error boundaries, argument constraints, and live network handshakes.

To run the test suite locally:

```bash
bats test/
```

---

## 🐳 Containerization (Docker)

To run the utility on any machine without installing local dependencies, compile the optimized, minimal Alpine-based Docker container:

```bash
# Build the Docker image
docker build -t netscan .

# Run a containerized security scan (automatically destroys container layers on exit)
docker run --rm netscan --target example.com --scan all
```

---

## 🤖 CI/CD Pipeline Gates

This repository utilizes a **Multi-Job GitHub Actions workflow** (`.github/workflows/ci.yml`) to enforce code quality gates. 

Jobs run in sequential, dependency-ordered blocks:
1. **Lint Stage (`lint`):** Triggers on push. Runs `ShellCheck` to enforce variable quoting and catch warnings before execution.
2. **Test Stage (`test`):** Starts only if linting passes. Spins up a runner, installs dependencies, and runs the `bats-core` test suite.
3. **Build Stage (`build`):** Starts only if testing passes. Compiles the Dockerfile to verify environment compilation.
