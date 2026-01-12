# BIBLE_PROJECT.md - Project-Specific Conventions

> **MUTABLE**: This document defines conventions for YOUR project built with cosmo-scaffold.
> Copy this template and modify it to match your project's needs.
> For immutable framework conventions, see `BIBLE_IMMUTABLE.md`.

---

## Project Identity

| Field | Value | Notes |
|-------|-------|-------|
| Project Name | `{{project_name}}` | Copier will substitute |
| Project Type | `{{project_type}}` | cli, server, embedded, library, wasm |
| Version | `0.1.0` | Semantic versioning |
| Created | `{{current_date}}` | Generation date |
| Lead Maintainer | `{{maintainer}}` | Primary contact |

---

## 1. Project-Specific Naming

### 1.1 Module Prefix

```
CONVENTION: This project uses the prefix: {{project_prefix}}_
```

Example (if project is "netcat"):
```c
// Project-specific symbols
netcat_connect()
NetcatSocket
NETCAT_DEFAULT_PORT

// Framework symbols (unchanged)
cosmo_arena_create()
CosmoArena
COSMO_ASSERT()
```

### 1.2 File Organization

```
CONVENTION: This project follows this source layout:
```

```
{{project_name}}/
├── src/
│   ├── main.c                  # Entry point
│   ├── {{project_prefix}}_*.c  # Project modules
│   └── {{project_prefix}}_*.h  # Project headers
├── include/
│   └── {{project_name}}.h      # Public API (if library)
├── vendor/                     # Third-party code
├── tests/
│   ├── unit/                   # Unit tests
│   └── integration/            # Integration tests
└── docs/
    └── api/                    # API documentation
```

---

## 2. Coding Style Amendments

### 2.1 Indentation

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| Style | [ ] Spaces / [ ] Tabs | _Fill in your preference_ |
| Width | [ ] 2 / [ ] 4 / [ ] 8 | _Fill in your preference_ |
| Max Line | [ ] 80 / [ ] 100 / [ ] 120 | _Fill in your preference_ |

### 2.2 Brace Style

```c
// Option A: K&R (recommended for C)
if (condition) {
    do_something();
} else {
    do_other();
}

// Option B: Allman
if (condition)
{
    do_something();
}
else
{
    do_other();
}

// SELECTED: [ ] K&R / [ ] Allman
```

### 2.3 Pointer Declaration

```c
// Option A: Pointer with type
char* str;

// Option B: Pointer with variable (C tradition)
char *str;

// SELECTED: [ ] With Type / [ ] With Variable
```

---

## 3. Memory Model Selection

### 3.1 Primary Allocation Strategy

```
CONVENTION: This project primarily uses: [ ] Arena / [ ] Malloc / [ ] Hybrid
```

| Component | Strategy | Lifetime |
|-----------|----------|----------|
| Request handling | Arena | Per-request |
| Configuration | Malloc | Application lifetime |
| Parsed data | Arena | Per-parse |
| Long-lived caches | Malloc | Explicit free |

### 3.2 Arena Configuration

```c
// Project-specific arena defaults (override framework defaults)
#define {{PROJECT_PREFIX}}_ARENA_DEFAULT_SIZE  (64 * 1024)  // 64KB
#define {{PROJECT_PREFIX}}_ARENA_MAX_SIZE      (16 * 1024 * 1024)  // 16MB
#define {{PROJECT_PREFIX}}_ARENA_ALIGNMENT     16
```

### 3.3 Overflow Behavior

```
CONVENTION: When arena is exhausted: [ ] Fail / [ ] Grow / [ ] Fallback to malloc
```

---

## 4. Assertion Configuration

### 4.1 Assertion Density Target

| Build | Density | Rationale |
|-------|---------|-----------|
| Debug | 1:15 | Extra thorough checking |
| Test | 1:10 | Maximum coverage |
| Release | N/A | Disabled |

### 4.2 Custom Assertion Actions

```c
// Define project-specific assertion failure handler
#define {{PROJECT_PREFIX}}_ASSERT_HANDLER(expr, file, line) \
    do { \
        {{project_prefix}}_log_assert_failure(expr, file, line); \
        {{project_prefix}}_dump_state(); \
        COSMO_ASSERT_DEFAULT_HANDLER(expr, file, line); \
    } while(0)
```

### 4.3 Assertion Categories Enabled

| Category | Debug | Release | Test |
|----------|-------|---------|------|
| Preconditions | Yes | No | Yes |
| Postconditions | Yes | No | Yes |
| Invariants | Yes | No | Yes |
| Bounds checks | Yes | No | Yes |
| Null checks | Yes | No | Yes |
| Alignment | Yes | No | Yes |

---

## 5. Error Handling Policy

### 5.1 Error Propagation

```
CONVENTION: Errors propagate via: [ ] Return codes / [ ] Output params / [ ] Both
```

```c
// If using return codes
{{ProjectPrefix}}Status {{project_prefix}}_operation(args...);

// If using output params
bool {{project_prefix}}_operation(args..., {{ProjectPrefix}}Error *err);

// If using both
int {{project_prefix}}_read(File *f, void *buf, size_t len, {{ProjectPrefix}}Error *err);
```

### 5.2 Project Error Codes

```c
// Extend framework errors with project-specific codes
typedef enum {
    // Framework errors (0-99)
    {{PROJECT_PREFIX}}_OK = COSMO_OK,
    {{PROJECT_PREFIX}}_ERR_NOMEM = COSMO_ERR_NOMEM,
    // ... include all COSMO_ERR_* ...

    // Project-specific errors (100+)
    {{PROJECT_PREFIX}}_ERR_PROTOCOL = 100,  // Protocol violation
    {{PROJECT_PREFIX}}_ERR_AUTH,            // Authentication failed
    {{PROJECT_PREFIX}}_ERR_CONFIG,          // Configuration error
    // Add your project errors here...
} {{ProjectPrefix}}Status;
```

---

## 6. Branchless Usage Policy

### 6.1 Opt-in Locations

```
CONVENTION: Branchless is [ ] Everywhere possible / [ ] Hot paths only / [ ] Disabled
```

Mark hot paths in code:
```c
// HOT PATH - branchless optimized
COSMO_HOT
int {{project_prefix}}_process_packet(Packet *p) {
    // Uses branchless primitives
    int action = COSMO_SELECT(p->type == TYPE_A, ACTION_A, ACTION_B);
    ...
}
```

### 6.2 Measurement Requirement

```
CONVENTION: Branchless changes require: [ ] Benchmark proof / [ ] Code review / [ ] Neither
```

---

## 7. Hash Table Configuration

### 7.1 Static Keyword Sets

| Set Name | Size | Generation |
|----------|------|------------|
| `{{project_prefix}}_keywords` | ~50 | gperf |
| `{{project_prefix}}_opcodes` | ~200 | gperf |
| _(add your sets)_ | | |

### 7.2 Dynamic Tables

```c
// Project defaults for runtime hash tables
#define {{PROJECT_PREFIX}}_HASH_INITIAL_BUCKETS  16
#define {{PROJECT_PREFIX}}_HASH_LOAD_FACTOR      0.75
#define {{PROJECT_PREFIX}}_HASH_GROWTH_FACTOR    2
```

---

## 8. Build Configuration

### 8.1 Default Build Mode

```
CONVENTION: Default make target builds: [ ] Debug / [ ] Release
```

### 8.2 Platform Targets

| Platform | Supported | Primary | Notes |
|----------|-----------|---------|-------|
| Linux x86_64 | Yes | Yes | Primary development |
| Linux ARM64 | Yes | Yes | CI tested |
| macOS x86_64 | Yes | No | CI tested |
| macOS ARM64 | Yes | No | CI tested |
| Windows x86_64 | Yes | No | CI tested |
| FreeBSD | Yes | No | Manual testing |
| OpenBSD | [ ] | No | _Fill in_ |
| NetBSD | [ ] | No | _Fill in_ |
| Bare Metal | [ ] | No | _Fill in_ |

### 8.3 Size Constraints

```
CONVENTION: Maximum binary size: [ ] Unconstrained / [ ] <1MB / [ ] <500KB / [ ] <100KB
```

If constrained, use `-mtiny` and size optimization techniques.

---

## 9. Testing Configuration

### 9.1 Coverage Target

| Metric | Target | Current |
|--------|--------|---------|
| Line coverage | 80% | _TBD_ |
| Branch coverage | 70% | _TBD_ |
| Function coverage | 100% | _TBD_ |

### 9.2 Test Categories

| Category | Required | Run Frequency |
|----------|----------|---------------|
| Unit | Yes | Every commit |
| Integration | Yes | Every PR |
| Fuzz | [ ] Yes / [ ] No | Nightly |
| Performance | [ ] Yes / [ ] No | Weekly |
| Platform | Yes | CI matrix |

### 9.3 Test Naming

```
CONVENTION: Test functions follow: test_<module>_<scenario>_<expected>
```

```c
COSMO_TEST(test_arena_alloc_returns_aligned_pointer)
COSMO_TEST(test_arena_reset_clears_all_allocations)
COSMO_TEST(test_arena_overflow_returns_null_when_strict)
```

---

## 10. Documentation Policy

### 10.1 Required Documentation

| Artifact | Format | Required |
|----------|--------|----------|
| README | Markdown | Yes |
| API reference | Doxygen | [ ] Yes / [ ] No |
| Architecture | Markdown | [ ] Yes / [ ] No |
| Changelog | CHANGELOG.md | Yes |
| Man pages | roff | [ ] Yes / [ ] No |

### 10.2 Comment Requirements

```
CONVENTION: Comments explain: [ ] What / [ ] Why / [ ] Both
```

```c
// WHAT: Explains the operation
offset = (offset + alignment - 1) & ~(alignment - 1);

// WHY: Explains the rationale (preferred)
// Align to boundary using bitmask (faster than modulo)
offset = (offset + alignment - 1) & ~(alignment - 1);
```

---

## 11. Version Control Policy

### 11.1 Branch Strategy

```
CONVENTION: [ ] Trunk-based / [ ] Git Flow / [ ] GitHub Flow
```

| Branch | Purpose | Merge To |
|--------|---------|----------|
| `main` | Stable releases | N/A |
| `develop` | Integration | main |
| `feature/*` | New features | develop |
| `fix/*` | Bug fixes | develop/main |
| `release/*` | Release prep | main |

### 11.2 Commit Message Format

```
CONVENTION: [ ] Conventional Commits / [ ] Custom / [ ] Freeform
```

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## 12. CI/CD Configuration

### 12.1 Required Checks

| Check | Required to Merge | Timeout |
|-------|-------------------|---------|
| Build (all modes) | Yes | 10m |
| Unit tests | Yes | 5m |
| Integration tests | Yes | 15m |
| Static analysis | Yes | 5m |
| Coverage report | No | 5m |

### 12.2 Release Process

```
CONVENTION: Releases are: [ ] Manual / [ ] Automated on tag / [ ] Automated on merge
```

---

## 13. Third-Party Dependencies

### 13.1 Allowed Dependencies

| Dependency | Version | Purpose | License |
|------------|---------|---------|---------|
| Cosmopolitan | 4.x | Runtime | ISC |
| _(add yours)_ | | | |

### 13.2 Vendoring Policy

```
CONVENTION: Third-party code is: [ ] Vendored / [ ] Submodule / [ ] Forbidden
```

---

## 14. Security Considerations

### 14.1 Sensitive Data Handling

```
CONVENTION: Secrets are: [ ] Never in code / [ ] Environment only / [ ] Config file
```

### 14.2 Input Validation

```
CONVENTION: All external input is validated: [ ] At boundary / [ ] Everywhere / [ ] Critical paths
```

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| {{current_date}} | Initial creation | {{maintainer}} |
| | | |

---

*This document is MUTABLE. Update it as your project evolves.*
*Template version: 1.0.0*
