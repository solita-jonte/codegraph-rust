#!/bin/bash
# ABOUTME: Installs CodeGraph CLI with autoagent-lates features and SurrealDB enabled.
# ABOUTME: Checks WSL Ubuntu prerequisites and compiles codegraph-mcp with agentic tooling enabled.

set -euo pipefail

# Build with LATS
FEATURE_FLAGS="--features autoagents-lats"
SURR_URL="${CODEGRAPH_SURREALDB_URL:-ws://localhost:3004}"
SURR_NAMESPACE="${CODEGRAPH_SURREALDB_NAMESPACE:-ouroboros}"
SURR_DATABASE="${CODEGRAPH_SURREALDB_DATABASE:-codegraph}"
HTTP_PORT="${CODEGRAPH_HTTP_PORT:-3000}"
INSTALL_PATH="${CARGO_HOME:-$HOME/.cargo}/bin"

info() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[ERROR] %s\n' "$1"; exit 1; }

info "Preparing to install CodeGraph (autoagent-lats)"

[[ "${WSL_DISTRO_NAME:-}" == Ubuntu* ]] || fail "This installer targets WSL Ubuntu Linux."
command -v apt >/dev/null 2>&1 || fail "apt is required"
command -v cargo >/dev/null 2>&1 || fail "cargo is required"
command -v rustup >/dev/null 2>&1 || fail "rustup is required"
command -v pkg-config >/dev/null 2>&1 || fail "pkg-config is required"
command -v c++ >/dev/null 2>&1 || fail "c++ is required (build-essential)"

# Check for SurrealDB
if ! command -v surreal >/dev/null 2>&1; then
    warn "SurrealDB CLI not found; installing via script..."
    curl -sSf https://install.surrealdb.com | sh
    info "SurrealDB CLI installed"
else
    info "SurrealDB CLI detected"
fi

# Check for Ollama (optional but recommended)
if ! command -v ollama >/dev/null 2>&1; then
    warn "Ollama not found - local LLM/embedding support will be limited"
    warn "Install from: https://ollama.com/download"
else
    info "Ollama detected"
fi

surreal upgrade --version 2.2.8
sudo apt install libssl-dev
mkdir -p ~/.codegraph

info "Compiling CodeGraph with these features: ${FEATURE_FLAGS}"
info ""
info "This may take 5-10 minutes depending on your machine..."

# Binary now lives in the server crate after the MCP split
cargo install --target x86_64-unknown-linux-gnu --path crates/codegraph-mcp-server --bin codegraph ${FEATURE_FLAGS} --force

info "CodeGraph installed to ${INSTALL_PATH}"
cat <<EOF

✅ Installation Complete - AutoAgent-LATS Build
=============================================

Enabled Features:
-----------------
🔧 Daemon mode (file watching & auto re-indexing)
🤖 AI-enhanced (agentic tools with tier-aware reasoning)
🧠 All embedding providers:
   - Local: Candle (CPU/GPU), ONNX Runtime
   - Cloud: OpenAI, Jina AI
   - Local API: Ollama, LM Studio
🗣️ All LLM providers:
   - Anthropic Claude (Sonnet, Opus)
   - OpenAI (GPT-4, GPT-5)
   - xAI (Grok)
   - Ollama (local)
   - LM Studio (local)
   - OpenAI-compatible endpoints
🔧 Rig agent framework (all providers):
   - OpenAI, Anthropic, Ollama, xAI
   - LM Studio, OpenAI-compatible
🌐 HTTP server (SSE streaming support)
🔬 AutoAgents framework (experimental)
🗄️ SurrealDB backend with HNSW vector search

Next Steps
----------
1. Start SurrealDB with persistent storage:
     surreal start --bind 0.0.0.0:3004 --user root --pass root file://\$HOME/.codegraph/surreal.db

2. Configure your preferred providers in ~/.codegraph/config.toml:

   [embedding]
   provider = "lmstudio"           # or ollama, jina, openai, onnx, local
   model = "jina-embeddings-v4"
   lmstudio_url = "http://localhost:1234"
   dimension = 2048

   [llm]
   enabled = true
   provider = "anthropic"          # or openai, xai, ollama, lmstudio
   model = "claude-sonnet-4"

   [surrealdb]
   url = "${SURR_URL}"
   namespace = "${SURR_NAMESPACE}"
   database = "${SURR_DATABASE}"

3. Set API keys for cloud providers (if using):
     export ANTHROPIC_API_KEY=sk-ant-...
     export OPENAI_API_KEY=sk-...
     export JINA_API_KEY=jina_...

4. Index your repository:
     codegraph index . --languages rust,python,typescript

5. Start the MCP server:
     # STDIO mode (Claude Desktop, etc.)
     codegraph start stdio

     # HTTP mode (SSE streaming)
     codegraph start http --host 127.0.0.1 --port ${HTTP_PORT}

6. Enable daemon mode for auto-indexing (optional):
     codegraph daemon start . --foreground

Ensure ${INSTALL_PATH} is on your PATH so editors can find the binary.

For more info: https://github.com/yourusername/codegraph-rust
EOF
