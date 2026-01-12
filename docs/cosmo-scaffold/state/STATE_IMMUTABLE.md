# STATE_IMMUTABLE.md - Required Application Properties

> **IMMUTABLE**: This document defines what EVERY application built with cosmo-scaffold MUST have.
> These are non-negotiable properties enforced by the framework.
> For project-specific state, see `STATE_PROJECT.md`.

---

## 1. Binary Properties

### 1.1 Output Format

```
REQUIREMENT: All applications produce Actually Portable Executables (APE).
```

| Property | Required Value | Verification |
|----------|----------------|--------------|
| Format | APE (polyglot) | `file <binary>` shows multiple formats |
| Architectures | x86_64 + aarch64 | Both embedded in single binary |
| Zip-compatible | Yes | `unzip -l <binary>` lists embedded files |
| Self-contained | Yes | No external runtime dependencies |

### 1.2 Entry Point

```
REQUIREMENT: Applications have a single, well-defined entry point.
```

```c
// REQUIRED: main() signature
int main(int argc, char *argv[]);

// For embedded/bare-metal
void _start(void);
```

### 1.3 Exit Behavior

```
REQUIREMENT: Applications exit with meaningful status codes.
```

| Exit Code | Meaning | Usage |
|-----------|---------|-------|
| 0 | Success | Normal completion |
| 1 | General error | Unspecified failure |
| 2 | Usage error | Bad arguments |
| 64-78 | BSD sysexits.h | Standard error categories |
| 126 | Cannot execute | Permission or format issue |
| 127 | Not found | Command/file not found |
| 128+N | Signal N | Terminated by signal |

---

## 2. Initialization Sequence

### 2.1 Required Init Order

```
REQUIREMENT: Initialization follows this exact sequence.
```

```c
// IMMUTABLE SEQUENCE
int main(int argc, char *argv[]) {
    // 1. Platform detection (automatic, before main)
    // 2. Assertion system initialization
    cosmo_assert_init();

    // 3. Memory system initialization
    cosmo_memory_init();

    // 4. Signal handlers
    cosmo_signals_init();

    // 5. Logging (if used)
    cosmo_log_init();

    // 6. Application-specific init
    app_init(argc, argv);

    // 7. Main loop / execution
    int result = app_run();

    // 8. Cleanup (reverse order)
    app_cleanup();
    cosmo_log_cleanup();
    cosmo_signals_cleanup();
    cosmo_memory_cleanup();
    cosmo_assert_cleanup();

    return result;
}
```

### 2.2 Signal Handling

```
REQUIREMENT: Applications handle termination signals gracefully.
```

| Signal | Required Handler | Behavior |
|--------|------------------|----------|
| SIGTERM | Yes | Clean shutdown |
| SIGINT | Yes | Clean shutdown |
| SIGPIPE | Yes | Ignore (return EPIPE) |
| SIGSEGV | Debug only | Print backtrace, abort |
| SIGABRT | Debug only | Print backtrace |

---

## 3. Memory State

### 3.1 Arena State Invariants

```
REQUIREMENT: Arena state is always consistent.
```

```c
// INVARIANT: Arena struct validity
typedef struct CosmoArena {
    uint8_t *base;      // INVARIANT: base != NULL after create
    size_t pos;         // INVARIANT: pos <= cap
    size_t cap;         // INVARIANT: cap > 0
    uint32_t flags;     // INVARIANT: valid flag bits only
    uint32_t alignment; // INVARIANT: power of 2
} CosmoArena;

// INVARIANT: After any operation
COSMO_INVARIANT(arena->pos <= arena->cap);
COSMO_INVARIANT(arena->base != NULL);
COSMO_INVARIANT(COSMO_IS_POWER_OF_2(arena->alignment));
```

### 3.2 Allocation Guarantees

```
REQUIREMENT: Allocations have these properties.
```

| Property | Guarantee | Enforcement |
|----------|-----------|-------------|
| Alignment | Minimum 8 bytes (16 for SIMD) | `COSMO_ASSERT_ALIGNED()` |
| Zeroing | Explicit via `_calloc` variants | Never implicit |
| Bounds | No buffer overflow | Assertions + sanitizers |
| Lifetime | Explicit ownership | Documentation + review |

### 3.3 Global State Limits

```
REQUIREMENT: Minimize mutable global state.
```

| Allowed Globals | Purpose | Mutability |
|-----------------|---------|------------|
| `g_cosmo_arena_default` | Default arena | Write-once at init |
| `g_cosmo_log_level` | Logging verbosity | Mutable (thread-safe) |
| `g_cosmo_signals` | Signal handlers | Write-once at init |
| `g_cosmo_platform` | Platform info | Read-only after detect |

---

## 4. Assertion State

### 4.1 Assertion Counters

```
REQUIREMENT: Debug builds track assertion statistics.
```

```c
// IMMUTABLE: Assertion tracking structure
typedef struct CosmoAssertStats {
    uint64_t total_checked;     // Assertions evaluated
    uint64_t preconditions;     // COSMO_PRECONDITION count
    uint64_t postconditions;    // COSMO_POSTCONDITION count
    uint64_t invariants;        // COSMO_INVARIANT count
    uint64_t failed;            // Should be 0 in correct program
} CosmoAssertStats;

// Access via
const CosmoAssertStats *cosmo_assert_stats(void);
```

### 4.2 Assertion Failure State

```
REQUIREMENT: Assertion failures are recorded before abort.
```

```c
// IMMUTABLE: Failure record
typedef struct CosmoAssertFailure {
    const char *expr;           // Failed expression
    const char *file;           // Source file
    int line;                   // Line number
    const char *func;           // Function name
    uint64_t timestamp;         // When it failed
} CosmoAssertFailure;

// Last failure available for crash handlers
const CosmoAssertFailure *cosmo_assert_last_failure(void);
```

---

## 5. Error State

### 5.1 Thread-Local Error

```
REQUIREMENT: Each thread has its own error state.
```

```c
// IMMUTABLE: Error state structure
typedef struct CosmoError {
    CosmoStatus code;           // Error code
    int sys_errno;              // System errno at time of error
    const char *message;        // Human-readable message
    const char *file;           // Source file
    int line;                   // Line number
} CosmoError;

// Thread-local access
CosmoError *cosmo_error_get(void);
void cosmo_error_set(CosmoStatus code, const char *msg);
void cosmo_error_clear(void);
```

### 5.2 Error Chain

```
REQUIREMENT: Errors can be chained for context.
```

```c
// Set error with cause
cosmo_error_set_with_cause(COSMO_ERR_IO, "read failed", inner_error);

// Walk chain
for (CosmoError *e = cosmo_error_get(); e; e = e->cause) {
    log_error("%s at %s:%d", e->message, e->file, e->line);
}
```

---

## 6. Platform State

### 6.1 Platform Detection Results

```
REQUIREMENT: Platform is detected once at startup and cached.
```

```c
// IMMUTABLE: Platform info structure
typedef struct CosmoPlatform {
    // Operating System
    enum {
        COSMO_OS_LINUX,
        COSMO_OS_MACOS,
        COSMO_OS_WINDOWS,
        COSMO_OS_FREEBSD,
        COSMO_OS_OPENBSD,
        COSMO_OS_NETBSD,
        COSMO_OS_BARE,
    } os;

    // Architecture
    enum {
        COSMO_ARCH_X86_64,
        COSMO_ARCH_AARCH64,
    } arch;

    // CPU Features (x86_64)
    struct {
        bool sse2;
        bool sse4_1;
        bool sse4_2;
        bool avx;
        bool avx2;
        bool avx512f;
        bool popcnt;
        bool bmi1;
        bool bmi2;
    } x86_features;

    // CPU Features (aarch64)
    struct {
        bool neon;
        bool crc32;
        bool aes;
        bool sha2;
    } arm_features;

    // System info
    size_t page_size;
    size_t cache_line_size;
    int cpu_count;
} CosmoPlatform;

// Access (read-only after init)
const CosmoPlatform *cosmo_platform(void);
```

---

## 7. I/O State

### 7.1 Standard Streams

```
REQUIREMENT: Standard streams are properly initialized.
```

```c
// IMMUTABLE: Stream state
typedef struct CosmoStdStreams {
    CosmoFile *stdin;       // Standard input
    CosmoFile *stdout;      // Standard output (buffered)
    CosmoFile *stderr;      // Standard error (unbuffered)
    bool stdin_tty;         // Is stdin a terminal?
    bool stdout_tty;        // Is stdout a terminal?
    bool stderr_tty;        // Is stderr a terminal?
} CosmoStdStreams;

// Access
const CosmoStdStreams *cosmo_std_streams(void);
```

### 7.2 File Descriptor Limits

```
REQUIREMENT: Applications check and respect FD limits.
```

```c
// Query limits
size_t cosmo_fd_limit_soft(void);   // Current limit
size_t cosmo_fd_limit_hard(void);   // Maximum possible
size_t cosmo_fd_count(void);        // Currently open

// Assertion
COSMO_ASSERT(cosmo_fd_count() < cosmo_fd_limit_soft());
```

---

## 8. Logging State

### 8.1 Log Levels

```
REQUIREMENT: Logging uses these exact levels.
```

```c
typedef enum {
    COSMO_LOG_TRACE = 0,    // Extremely verbose
    COSMO_LOG_DEBUG = 1,    // Debug information
    COSMO_LOG_INFO = 2,     // Informational messages
    COSMO_LOG_WARN = 3,     // Warning conditions
    COSMO_LOG_ERROR = 4,    // Error conditions
    COSMO_LOG_FATAL = 5,    // Fatal errors (then abort)
    COSMO_LOG_OFF = 6,      // Disable logging
} CosmoLogLevel;
```

### 8.2 Log Entry Format

```
REQUIREMENT: Log entries have consistent structure.
```

```
[LEVEL] YYYY-MM-DD HH:MM:SS.mmm [file:line] message
```

Example:
```
[ERROR] 2026-01-12 15:30:45.123 [parser.c:456] unexpected token
```

---

## 9. Test State

### 9.1 Test Registry

```
REQUIREMENT: Tests are automatically discovered and registered.
```

```c
// IMMUTABLE: Test registration
typedef struct CosmoTest {
    const char *name;           // Test function name
    const char *suite;          // Suite name (file-based)
    void (*func)(void);         // Test function pointer
    bool skip;                  // Skip this test?
    const char *skip_reason;    // Why skipped
} CosmoTest;

// Auto-registration macro expands to
static void test_foo(void);
static const CosmoTest _reg_test_foo
    __attribute__((section("cosmo_tests"), used)) = {
    .name = "test_foo",
    .suite = __FILE__,
    .func = test_foo,
};
```

### 9.2 Test Results

```
REQUIREMENT: Test results are machine-parseable.
```

```c
typedef struct CosmoTestResult {
    const char *name;
    enum {
        COSMO_TEST_PASS,
        COSMO_TEST_FAIL,
        COSMO_TEST_SKIP,
        COSMO_TEST_ERROR,
    } status;
    uint64_t duration_ns;       // Execution time
    const char *failure_msg;    // If failed
    const char *failure_file;   // Where it failed
    int failure_line;           // Line number
} CosmoTestResult;
```

---

## 10. Build State

### 10.1 Compile-Time Constants

```
REQUIREMENT: These constants are embedded in every binary.
```

```c
// IMMUTABLE: Build info (generated at compile time)
extern const char COSMO_BUILD_VERSION[];      // "1.2.3"
extern const char COSMO_BUILD_HASH[];         // Git commit hash
extern const char COSMO_BUILD_DATE[];         // ISO 8601 date
extern const char COSMO_BUILD_MODE[];         // "debug", "release", "tiny"
extern const char COSMO_COMPILER_VERSION[];   // "cosmocc 4.0.2"

// Query at runtime
const char *cosmo_version(void);
const char *cosmo_build_info(void);
```

### 10.2 Feature Flags

```
REQUIREMENT: Compile-time features are queryable.
```

```c
// IMMUTABLE: Feature detection
#ifdef COSMO_FEATURE_ARENA
#define COSMO_HAS_ARENA 1
#else
#define COSMO_HAS_ARENA 0
#endif

// Runtime query
bool cosmo_has_feature(const char *feature);
// Returns: cosmo_has_feature("arena") -> true/false
```

---

## 11. Crash State

### 11.1 Crash Handler Requirements

```
REQUIREMENT: Crashes produce useful diagnostics.
```

```c
// IMMUTABLE: Crash info structure
typedef struct CosmoCrashInfo {
    int signal;                 // Signal number
    void *fault_addr;           // Address of fault (if applicable)
    void *instruction_ptr;      // Where crash occurred
    void *stack_frames[32];     // Backtrace
    size_t frame_count;         // Number of frames
    const char *last_assert;    // Last assertion checked
    CosmoArena *active_arena;   // Arena in use at crash
} CosmoCrashInfo;
```

### 11.2 Debug Symbol Availability

```
REQUIREMENT: Debug builds include symbols for crash analysis.
```

| Build Mode | Symbols | Backtrace Quality |
|------------|---------|-------------------|
| Debug | Full DWARF | Function + line + args |
| Release | None | Address only |
| Release + debug | Separate .dbg | Full with .dbg present |

---

## Appendix: State Invariants Summary

1. **Arena: pos <= cap** - Never allocate beyond capacity
2. **Alignment: power of 2** - All alignments valid
3. **Errors: thread-local** - No cross-thread corruption
4. **Platform: read-only** - Detected once, never changes
5. **Streams: initialized** - Usable from first statement
6. **Logs: ordered** - TRACE < DEBUG < INFO < WARN < ERROR < FATAL
7. **Tests: registered** - No orphan tests
8. **Build info: present** - Always queryable
9. **Crash info: captured** - Before abort
10. **Globals: minimal** - Only framework-managed

---

*This document is IMMUTABLE. These requirements define what it means to be a cosmo-scaffold application.*
*Document version: 1.0.0*
