# Product Requirements Document: Cosmo-Scaffold Universal C Framework

## Executive Summary

**Project Codename**: `cosmo-scaffold`
**Version**: 0.1.0-draft
**Status**: Planning Phase
**Last Updated**: 2026-01-12

Cosmo-Scaffold is a meta-framework and scaffolding system for generating portable, high-performance C applications using [Cosmopolitan Libc](https://github.com/jart/cosmopolitan). It combines deterministic templating (Copier/Cookiecutter), preprocessor macros, and probabilistic code generation (LLM-assisted) to produce applications that run on Linux, macOS, Windows, FreeBSD, OpenBSD, NetBSD, and bare metal from a single compilation.

---

## 1. Problem Statement

### Current Landscape

The Cosmopolitan ecosystem already provides powerful scaffolding and codegen tools:
- **[cosmo-project](https://github.com/matt-dunleavy/cosmo-project)** - Cross-platform C project template with Makefile
- **[redbean-template](https://github.com/nicholatian/redbean-template)** - Web server project scaffold
- **[action-static-redbean](https://github.com/TimonLukas/action-static-redbean)** - GitHub Actions for APE builds
- **[superconfigure](https://github.com/Welding-Torch/superconfigure)** - Cross-platform autoconf wrappers
- **Copier/Cookiecutter** - Work with cosmocc for template-based generation
- **cosmocc toolchain** - Already handles cross-OS/arch compilation

### Additional Ecosystem Capabilities

- **[Cosmopolitan CPython](https://github.com/jart/cosmopolitan)** - Python 3.x compiled with cosmocc, enabling portable Copier/Cookiecutter execution
- **[cosmo SQLite](https://github.com/nicholatian/sqlite-cosmo)** - Embedded database as APE
- **[redbean](https://redbean.dev)** - Single-file web server with Lua, SQLite, serves 1M+ req/sec
- **[Microwindows/Nano-X](https://github.com/nicholatian/microwindows)** - Cross-platform GUI framework
- **htmx.js** - Hypermedia-driven frontend for redbean web apps

### Gap Analysis

1. **Fragmented tooling** - These tools exist but aren't unified into a single coherent framework with consistent conventions
2. **Performance patterns not templated** - Branchless programming, arena allocators, and perfect hashing exist in theory but lack ready-to-use scaffolded implementations
3. **Assertion coverage inconsistent** - No enforced assertion density or structured precondition/postcondition patterns across projects
4. **LLM codegen lacks C-specific guardrails** - AI-generated C code needs validation frameworks, memory safety checks, and convention enforcement
5. **No lifecycle management** - Existing templates are one-shot; Copier's update capability is underutilized for evolving portable C projects
6. **Web/GUI templates missing** - redbean + htmx.js + SQLite stack lacks project scaffolding with best practices

### Target Users

- Systems programmers building cross-platform tools
- Embedded developers needing desktop/server test harnesses
- Security researchers creating portable analysis tools
- Application developers wanting single-binary distribution

---

## 2. Goals & Non-Goals

### Goals

| ID | Goal | Success Metric |
|----|------|----------------|
| G1 | Single-command project scaffolding | `copier copy cosmo-scaffold ./myproject` works in <5s |
| G2 | Build-once run-anywhere binaries | Output runs on 6+ OS without modification |
| G3 | Extensive assert coverage | Minimum 1 assert per 20 LOC in generated code |
| G4 | Hybrid memory management | Arena + malloc coexistence with clear ownership |
| G5 | Branchless-first hot paths | Critical paths use CMOV/lookup tables where beneficial |
| G6 | Precomputed hash tables | Static keyword sets use gperf-generated tables |
| G7 | LLM-assisted code generation | Spec-driven probabilistic codegen with validation |
| G8 | CI/CD from day one | GitHub Actions workflow generated with project |

### Non-Goals

- GUI framework (focus on CLI, server, embedded, library targets)
- C++ support (pure C11/C23 with Cosmopolitan extensions)
- Runtime dependency management (static linking only)
- Windows-only features (use masm64-framework for that)

---

## 3. Upstream Dependencies & ludoplex Forks

### Existing ludoplex Cosmopolitan Forks (Sync Required)

| ludoplex Fork | Upstream | Purpose | Sync Status |
|---------------|----------|---------|-------------|
| [ludoplex/superconfigure](https://github.com/ludoplex/superconfigure) | ahgamut/superconfigure | Autotools wrapper for Cosmopolitan builds | **SYNC NEEDED** |
| [ludoplex/cosmo-gcc-plugin](https://github.com/ludoplex/cosmo-gcc-plugin) | ahgamut/cosmo-gcc-plugin | GCC plugin for porting C to Cosmopolitan | **SYNC NEEDED** |
| [ludoplex/cosmo-cross-sdk](https://github.com/ludoplex/cosmo-cross-sdk) | Ronsor/cosmo-cross-sdk | Cross-compiling SDK for Cosmopolitan | **SYNC NEEDED** |
| [ludoplex/rust-ape-example](https://github.com/ludoplex/rust-ape-example) | ahgamut/rust-ape-example | Rust + Cosmopolitan APE examples (175+ programs) | **SYNC NEEDED** |
| [ludoplex/cosmosocks](https://github.com/ludoplex/cosmosocks) | bannsec/cosmosocks | SOCKS4/5 server in Cosmopolitan libc | **SYNC NEEDED** |
| [ludoplex/redbean-template](https://github.com/ludoplex/redbean-template) | nicholatian/redbean-template | Redbean project scaffold | **SYNC NEEDED** |
| [ludoplex/redbean-cardgames](https://github.com/ludoplex/redbean-cardgames) | (upstream) | Card games collection in redbean | **SYNC NEEDED** |
| [ludoplex/ludofile](https://github.com/ludoplex/ludofile) | trailofbits/polyfile | Polyfile with Cosmopolitan APE support | **SYNC NEEDED** |
| [ludoplex/diffoscope-with-Python3.11.0rc1-and-Cosmopolitan](https://github.com/ludoplex/diffoscope-with-Python3.11.0rc1-and-Cosmopolitan) | diffoscope | Diffoscope with Cosmopolitan Python | **SYNC NEEDED** |
| [ludoplex/cookiecutter](https://github.com/ludoplex/cookiecutter) | cookiecutter/cookiecutter | Project templating (for cosmo python) | **SYNC NEEDED** |
| [ludoplex/awesome-cosmo](https://github.com/ludoplex/awesome-cosmo) | burggraf/awesome-cosmo | Curated Cosmopolitan apps (redbean, SQLite, Python, etc.) | **SYNC NEEDED** |

### Primary Upstream (Not Yet Forked)

| Repository | Purpose | Action Required |
|------------|---------|-----------------|
| [jart/cosmopolitan](https://github.com/jart/cosmopolitan) | Core libc, cosmocc, CPython | **FORK NEEDED** |
| [shmup/awesome-cosmopolitan](https://github.com/shmup/awesome-cosmopolitan) | Resource aggregation | Watch only |
| [matt-dunleavy/cosmo-project](https://github.com/matt-dunleavy/cosmo-project) | Build system reference | Reference only |

### Scaffolding Tools

| Tool | Role | Selection Rationale |
|------|------|---------------------|
| [Copier](https://copier.readthedocs.io/) | Primary templating | Lifecycle management, YAML config, template updates |
| [ludoplex/cookiecutter](https://github.com/ludoplex/cookiecutter) | Fallback (runs on cosmo python) | Broader ecosystem, portable via Cosmopolitan CPython |
| [gperf](https://www.gnu.org/software/gperf/) | Perfect hash generation | Compile-time hash table codegen |
| [m4](https://www.gnu.org/software/m4/) | Macro preprocessing | Complex conditional generation |

### Probabilistic Codegen

| Tool | Role |
|------|------|
| Claude Code / Claude API | Spec-to-code generation with validation loop |
| Local LLM (Ollama) | Offline generation fallback |

### Sync Procedure

```bash
# For each ludoplex fork, sync with upstream:
cd /path/to/ludoplex/<repo>
git remote add upstream https://github.com/<upstream-owner>/<repo>.git
git fetch upstream
git checkout main
git merge upstream/main --no-edit
git push origin main

# Tag compatible versions for cosmo-scaffold
git tag -a cosmo-scaffold-compat-v1 -m "Compatible with cosmo-scaffold v1.0"
git push origin --tags
```

---

## 4. Architecture Overview

```
cosmo-scaffold/
├── .copier/                    # Copier template configuration
│   ├── copier.yaml             # Template questions & answers
│   └── extensions.py           # Custom Jinja2 extensions
├── bible/                      # Canonical documentation
│   ├── BIBLE_IMMUTABLE.md      # Framework truths (never changes)
│   └── BIBLE_PROJECT.md        # Project conventions (user-editable)
├── state/                      # Application state tracking
│   ├── STATE_IMMUTABLE.md      # Required application properties
│   └── STATE_PROJECT.md        # Current project state (mutable)
├── core/                       # Core framework headers
│   ├── cosmo_abi.h             # ABI conventions & calling
│   ├── cosmo_assert.h          # Extensive assertion macros
│   ├── cosmo_arena.h           # Arena allocator
│   ├── cosmo_branchless.h      # Branchless primitives
│   ├── cosmo_hash.h            # Hash table utilities
│   └── cosmo_platform.h        # Platform detection
├── lib/                        # Optional library modules
│   ├── arena/                  # Arena allocator implementation
│   ├── pool/                   # Pool allocator (fixed-size)
│   ├── hash/                   # Hash table implementations
│   ├── string/                 # String utilities
│   ├── io/                     # I/O abstractions
│   └── test/                   # Testing framework
├── templates/                  # Project type templates
│   ├── cli/                    # Command-line application
│   ├── server/                 # Network server (TCP/UDP)
│   ├── web/                    # Web app (redbean + SQLite + htmx.js)
│   ├── gui/                    # Desktop GUI (Microwindows/Nano-X)
│   ├── embedded/               # Embedded/bare-metal
│   ├── library/                # Shared library (.so/.dll/.dylib)
│   └── wasm/                   # WebAssembly target
├── tools/                      # Portable tooling (cosmo python)
│   ├── python.com              # Cosmopolitan CPython (portable)
│   ├── copier/                 # Copier installed in cosmo python
│   └── cookiecutter/           # Cookiecutter as fallback
├── codegen/                    # Code generation tools
│   ├── gperf/                  # Perfect hash generators
│   ├── prompts/                # LLM prompt templates
│   └── validators/             # Generated code validators
├── build/                      # Build system files
│   ├── Makefile.template       # GNU Make template
│   ├── meson.build.template    # Meson template
│   └── cosmocc.mk              # Cosmocc integration
├── .github/                    # CI/CD templates
│   └── workflows/
│       ├── build.yml           # Multi-platform build
│       ├── test.yml            # Test execution
│       └── release.yml         # Release automation
└── tests/                      # Framework self-tests
    ├── unit/                   # Unit tests
    ├── integration/            # Integration tests
    └── platform/               # Platform-specific tests
```

---

## 5. Core Components

### 5.1 Assertion System

Every generated project includes extensive assertions:

```c
// cosmo_assert.h patterns
COSMO_ASSERT(condition);                    // Basic assertion
COSMO_ASSERT_MSG(condition, "message");     // With message
COSMO_ASSERT_EQ(a, b);                      // Equality
COSMO_ASSERT_NE(a, b);                      // Inequality
COSMO_ASSERT_LT(a, b);                      // Less than
COSMO_ASSERT_LE(a, b);                      // Less or equal
COSMO_ASSERT_GT(a, b);                      // Greater than
COSMO_ASSERT_GE(a, b);                      // Greater or equal
COSMO_ASSERT_NULL(ptr);                     // Null check
COSMO_ASSERT_NOT_NULL(ptr);                 // Non-null check
COSMO_ASSERT_ALIGNED(ptr, alignment);       // Alignment check
COSMO_ASSERT_ARENA_VALID(arena);            // Arena state check
COSMO_PRECONDITION(condition);              // Function precondition
COSMO_POSTCONDITION(condition);             // Function postcondition
COSMO_INVARIANT(condition);                 // Loop/class invariant
COSMO_UNREACHABLE();                        // Mark unreachable code
```

**Requirement**: Minimum 1 assertion per 20 lines of generated code.

### 5.2 Memory Management (Hybrid Arena + Dynamic)

```c
// Arena for batch allocations with shared lifetime
CosmoArena *arena = cosmo_arena_create(COSMO_ARENA_DEFAULT_SIZE);
void *batch_data = cosmo_arena_alloc(arena, size);
// ... use batch_data ...
cosmo_arena_reset(arena);  // Free all at once

// Dynamic for individual lifetimes
void *individual = cosmo_malloc(size);
// ... use individual ...
cosmo_free(individual);

// Hybrid: arena-backed with overflow to malloc
CosmoHybridAlloc *hybrid = cosmo_hybrid_create(arena, OVERFLOW_TO_MALLOC);
void *data = cosmo_hybrid_alloc(hybrid, size);
```

### 5.3 Branchless Programming Primitives

```c
// cosmo_branchless.h
#define COSMO_SELECT(cond, a, b)    ((b) ^ (((a) ^ (b)) & -(cond)))
#define COSMO_MIN(a, b)             ((b) ^ (((a) ^ (b)) & -((a) < (b))))
#define COSMO_MAX(a, b)             ((a) ^ (((a) ^ (b)) & -((a) < (b))))
#define COSMO_ABS(x)                (((x) ^ ((x) >> 31)) - ((x) >> 31))
#define COSMO_SIGN(x)               (((x) > 0) - ((x) < 0))
#define COSMO_CLAMP(x, lo, hi)      COSMO_MIN(COSMO_MAX(x, lo), hi)

// Lookup table pattern for computed gotos
typedef void (*BranchlessHandler)(void *ctx);
static const BranchlessHandler dispatch_table[] = {
    [STATE_A] = handle_a,
    [STATE_B] = handle_b,
    // ...
};
dispatch_table[state](context);  // No branch prediction needed
```

### 5.4 Precomputed Hash Tables (gperf Integration)

```bash
# Generate perfect hash for keywords
gperf --language=ANSI-C --struct-type keywords.gperf > keywords_hash.h
```

```c
// keywords.gperf
%{
#include "keywords_hash.h"
%}
struct keyword { const char *name; int token; };
%%
if,      TOKEN_IF
else,    TOKEN_ELSE
while,   TOKEN_WHILE
for,     TOKEN_FOR
return,  TOKEN_RETURN
%%

// Usage - O(1) lookup
const struct keyword *kw = in_word_set(str, len);
if (kw) {
    COSMO_ASSERT(kw->token >= TOKEN_FIRST && kw->token <= TOKEN_LAST);
    return kw->token;
}
```

---

## 6. Web Application Stack (redbean + SQLite + htmx.js)

### 6.1 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    redbean.com (APE)                     │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Lua Application Layer                              │ │
│  │  ┌─────────────┐ ┌─────────────┐ ┌───────────────┐  │ │
│  │  │  Routes     │ │  Handlers   │ │  Middleware   │  │ │
│  │  └─────────────┘ └─────────────┘ └───────────────┘  │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Embedded Assets (/zip/)                            │ │
│  │  ┌─────────────┐ ┌─────────────┐ ┌───────────────┐  │ │
│  │  │  htmx.js    │ │  CSS        │ │  Templates    │  │ │
│  │  └─────────────┘ └─────────────┘ └───────────────┘  │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  SQLite Database (embedded or external)             │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Web Template Structure

```
templates/web/
├── .init.lua                   # Application entry point
├── routes/
│   ├── index.lua               # GET / handler
│   ├── api/                    # JSON API endpoints
│   └── pages/                  # HTML page handlers
├── static/
│   ├── htmx.min.js             # htmx.js (hypermedia)
│   ├── style.css               # Minimal CSS
│   └── favicon.ico
├── templates/
│   ├── base.html               # Base layout
│   ├── partials/               # htmx partial responses
│   └── pages/                  # Full page templates
├── db/
│   ├── schema.sql              # SQLite schema
│   └── migrations/             # Schema migrations
├── Makefile                    # Build redbean bundle
└── test/
    └── api_test.lua            # API tests
```

### 6.3 htmx.js Patterns

```html
<!-- Hypermedia-driven UI - no JavaScript SPA needed -->
<button hx-post="/api/items"
        hx-target="#item-list"
        hx-swap="beforeend">
  Add Item
</button>

<div id="item-list" hx-get="/api/items" hx-trigger="load">
  <!-- Items loaded via htmx -->
</div>
```

### 6.4 SQLite Integration

```lua
-- .init.lua
local sqlite = require 'lsqlite3'
local db = sqlite.open('/zip/data.db')  -- Embedded in APE

-- Or external for persistence
local db = sqlite.open('app.db')

-- Prepared statements for safety
local stmt = db:prepare('SELECT * FROM items WHERE id = ?')
stmt:bind(1, item_id)
for row in stmt:nrows() do
  -- Process row with assertions
  assert(row.id ~= nil, "item must have id")
end
```

---

## 7. GUI Application Stack (Microwindows/Nano-X)

### 7.1 Cross-Platform GUI Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Application (APE binary)                    │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  GUI Layer (cosmo_gui.h)                            │ │
│  │  ┌─────────────┐ ┌─────────────┐ ┌───────────────┐  │ │
│  │  │  Windows    │ │  Widgets    │ │  Events       │  │ │
│  │  └─────────────┘ └─────────────┘ └───────────────┘  │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Microwindows/Nano-X                                │ │
│  │  (Compiled into APE or dynamically linked)          │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Platform Backends                                  │ │
│  │  Linux(X11/FB) | Windows(GDI) | macOS(Quartz)      │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 7.2 GUI Template Structure

```
templates/gui/
├── src/
│   ├── main.c                  # Entry point with GUI init
│   ├── window.c                # Main window
│   ├── widgets/                # Custom widgets
│   └── handlers/               # Event handlers
├── resources/
│   ├── icons/                  # Application icons
│   ├── fonts/                  # Embedded fonts
│   └── themes/                 # UI themes
├── include/
│   └── app_gui.h               # Application GUI header
├── Makefile
└── test/
    └── gui_test.c              # GUI component tests
```

### 7.3 GUI Assertions

```c
// cosmo_gui.h patterns
COSMO_ASSERT_WINDOW_VALID(window);
COSMO_ASSERT_WIDGET_ATTACHED(widget, parent);
COSMO_ASSERT_EVENT_HANDLED(event);
COSMO_ASSERT_RENDER_CONTEXT(ctx);
```

---

## 8. Self-Hosting Toolchain (Cosmopolitan CPython)

### 8.1 Portable Scaffolding

The scaffolding tools themselves are portable APEs:

```bash
# Download once, run anywhere
curl -O https://cosmo.zip/pub/cosmos/bin/python3.11.com
chmod +x python3.11.com

# Install Copier portably
./python3.11.com -m pip install copier --target=./copier_pkg

# Run Copier as portable command
./python3.11.com -m copier copy gh:ludoplex/cosmo-scaffold ./myproject
```

### 8.2 Bundled Tools Distribution

```
cosmo-scaffold-tools.zip (APE archive)
├── python.com                  # Cosmopolitan Python 3.11
├── copier/                     # Copier package
├── cookiecutter/               # Cookiecutter package
├── jinja2/                     # Template engine
├── pyyaml/                     # YAML parser
└── scaffold.py                 # Wrapper script

# Single command from any OS:
./python.com scaffold.py new myproject --template=web
```

### 8.3 Module Generation

```bash
# Generate a new module in existing project
./python.com scaffold.py add-module \
  --name=auth \
  --type=service \
  --with-tests \
  --with-arena

# Generates:
# src/auth/
# ├── auth.c
# ├── auth.h
# ├── auth_arena.c      # Arena-backed allocations
# └── auth_test.c       # With assertion coverage
```

---

## 9. Scaffolding Workflow

### 6.1 Copier-Based Generation (Primary)

```yaml
# copier.yaml
_min_copier_version: "9.0.0"
_subdirectory: "template"

project_name:
  type: str
  help: "Project name (lowercase, hyphens allowed)"
  validator: "{% if not project_name | regex_search('^[a-z][a-z0-9-]*$') %}Invalid name{% endif %}"

project_type:
  type: str
  choices:
    - cli
    - server
    - embedded
    - library
    - wasm
  default: cli

memory_model:
  type: str
  choices:
    - arena_only
    - malloc_only
    - hybrid
  default: hybrid

enable_branchless:
  type: bool
  default: true

hash_table_type:
  type: str
  choices:
    - none
    - gperf_static
    - runtime_dynamic
  default: gperf_static

llm_codegen:
  type: bool
  help: "Enable LLM-assisted code generation prompts"
  default: false
```

### 6.2 Generation Command

```bash
# Primary: Copier (supports updates)
copier copy gh:ludoplex/cosmo-scaffold ./my-project

# Update existing project when template evolves
copier update ./my-project

# Fallback: Cookiecutter (one-shot)
cookiecutter gh:ludoplex/cosmo-scaffold
```

### 6.3 LLM-Assisted Generation

```bash
# Generate module from spec
./codegen/generate.sh --spec=specs/parser.yaml --output=src/parser/

# Validation loop
./codegen/validate.sh src/parser/  # Runs assertions, tests, static analysis
```

---

## 7. Build System

### 7.1 Makefile (Default)

```makefile
CC := cosmocc
CFLAGS := -O2 -Wall -Wextra -Werror -std=c11
CFLAGS += -DCOSMO_ASSERTIONS_ENABLED

# Build modes
ifeq ($(MODE),debug)
  CFLAGS += -g -O0 -fsanitize=undefined,address
endif
ifeq ($(MODE),tiny)
  CFLAGS += -Os -mtiny
endif
ifeq ($(MODE),linux)
  CFLAGS += -moptlinux
endif

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^
```

### 7.2 Meson (Alternative)

```meson
project('{{project_name}}', 'c',
  version: '0.1.0',
  default_options: ['c_std=c11', 'warning_level=3'])

cosmocc = find_program('cosmocc')

executable('{{project_name}}',
  sources,
  c_args: ['-DCOSMO_ASSERTIONS_ENABLED'],
)
```

---

## 8. CI/CD Pipeline

```yaml
# .github/workflows/build.yml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download cosmocc
        run: |
          curl -LO https://cosmo.zip/pub/cosmocc/cosmocc-4.0.2.zip
          unzip cosmocc-4.0.2.zip -d cosmocc
          echo "$PWD/cosmocc/bin" >> $GITHUB_PATH

      - name: Build (all modes)
        run: |
          make MODE=release
          make MODE=debug
          make MODE=tiny

      - name: Run tests
        run: make test

      - name: Verify cross-platform
        run: |
          file bin/{{project_name}}
          ./bin/{{project_name}} --version
```

---

## 9. Upstream Sync Strategy

### ludoplex Fork Requirements

| Upstream | Fork Name | Sync Frequency |
|----------|-----------|----------------|
| jart/cosmopolitan | ludoplex/cosmopolitan | Monthly / on release |
| shmup/awesome-cosmopolitan | (watch only) | N/A |

### Sync Procedure

```bash
# Initial fork setup
gh repo fork jart/cosmopolitan --clone --remote

# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

# For cosmo-scaffold, tag compatible versions
git tag -a cosmo-compat-4.0.2 -m "Compatible with cosmopolitan 4.0.2"
```

---

## 10. Success Criteria

| Criterion | Measurement | Target |
|-----------|-------------|--------|
| Scaffolding time | `time copier copy ...` | < 5 seconds |
| Binary portability | Runs on N operating systems | >= 6 |
| Assert density | Assertions / LOC | >= 1:20 |
| Build reproducibility | Same binary hash | 100% |
| Test coverage | Line coverage | >= 80% |
| CI pass rate | Successful builds | >= 99% |

---

## 11. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Cosmopolitan breaking changes | High | Pin to specific versions, maintain compat layer |
| cosmocc unavailable | Medium | Fallback to GCC/Clang with reduced portability |
| gperf input limits | Low | Use runtime hash tables for large sets |
| LLM codegen quality | Medium | Mandatory validation loop, human review gates |

---

## 12. Timeline & Phases

### Phase 1: Foundation (Current)
- [ ] Fork jart/cosmopolitan to ludoplex
- [ ] Create Bible and State documents
- [ ] Design core headers (assert, arena, branchless)
- [ ] Create Copier template skeleton

### Phase 2: Core Implementation
- [ ] Implement cosmo_assert.h
- [ ] Implement cosmo_arena.h
- [ ] Implement cosmo_branchless.h
- [ ] Integrate gperf workflow

### Phase 3: Templates & Codegen
- [ ] CLI template
- [ ] Server template
- [ ] LLM prompt library
- [ ] Validation framework

### Phase 4: CI/CD & Polish
- [ ] GitHub Actions workflows
- [ ] Documentation site
- [ ] Example projects
- [ ] Release automation

---

## Appendix A: Reference Links

- [Cosmopolitan Libc](https://github.com/jart/cosmopolitan)
- [cosmocc README](https://github.com/jart/cosmopolitan/blob/master/tool/cosmocc/README.md)
- [Awesome Cosmopolitan](https://github.com/shmup/awesome-cosmopolitan)
- [Copier Documentation](https://copier.readthedocs.io/)
- [GNU gperf Manual](https://www.gnu.org/software/gperf/manual/gperf.html)
- [Branchless Programming - Algorithmica](https://en.algorithmica.org/hpc/pipelining/branchless/)
- [Arena Allocators - Ryan Fleury](https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator)

---

*This PRD is a living document. See BIBLE_PROJECT.md for mutable conventions.*
