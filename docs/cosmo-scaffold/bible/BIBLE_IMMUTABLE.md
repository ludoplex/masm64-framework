# BIBLE_IMMUTABLE.md - Framework Source Code Conventions

> **IMMUTABLE**: This document defines eternal truths about the cosmo-scaffold framework itself.
> These conventions are baked into the framework and MUST NOT be changed by users.
> For project-specific conventions, see `BIBLE_PROJECT.md`.

---

## 1. Language Standard

```
TRUTH: The framework uses C11 as the base standard with C23 features where supported.
```

| Aspect | Immutable Value |
|--------|-----------------|
| Base Standard | C11 (`-std=c11`) |
| Extended Standard | C23 (`-std=c23`) when available |
| Extensions | Cosmopolitan-specific (`_COSMO_SOURCE`) |
| Dialect | POSIX-compatible, platform-agnostic |

**Rationale**: C11 provides `_Static_assert`, `_Alignas`, `_Generic`, and thread support while maintaining maximum compiler compatibility. C23 adds `#embed`, `nullptr`, and improved `static_assert`.

---

## 2. Naming Conventions

### 2.1 Prefix Hierarchy

```
TRUTH: All framework symbols use the COSMO_ or cosmo_ prefix.
```

| Type | Prefix | Example |
|------|--------|---------|
| Public macros | `COSMO_` | `COSMO_ASSERT()` |
| Public functions | `cosmo_` | `cosmo_arena_create()` |
| Public types | `Cosmo` | `CosmoArena` |
| Internal macros | `COSMO__` | `COSMO__IMPL_DETAIL()` |
| Internal functions | `cosmo__` | `cosmo__internal_fn()` |
| Constants | `COSMO_` | `COSMO_ARENA_DEFAULT_SIZE` |
| Enum values | `COSMO_` | `COSMO_ERR_NOMEM` |

### 2.2 Case Conventions

```
TRUTH: snake_case for functions/variables, PascalCase for types, SCREAMING_SNAKE for macros.
```

```c
// Correct
CosmoArena *arena = cosmo_arena_create(COSMO_ARENA_DEFAULT_SIZE);
COSMO_ASSERT_NOT_NULL(arena);

// Incorrect
CosmoArena *Arena = Cosmo_Arena_Create(cosmo_arena_default_size);
```

### 2.3 File Naming

```
TRUTH: All framework headers use cosmo_ prefix, lowercase, underscores.
```

| Pattern | Example |
|---------|---------|
| Core headers | `cosmo_assert.h`, `cosmo_arena.h` |
| Implementation | `cosmo_arena.c` |
| Internal headers | `cosmo__arena_impl.h` |
| Generated | `cosmo_keywords_hash.h` |

---

## 3. Assertion Philosophy

```
TRUTH: Assertions are documentation that executes. They are NEVER optional in debug builds.
```

### 3.1 Assertion Density Requirement

| Build Mode | Assertion State | Minimum Density |
|------------|-----------------|-----------------|
| Debug | Enabled | 1 per 20 LOC |
| Release | Disabled (NDEBUG) | N/A |
| Test | Enabled | 1 per 10 LOC |

### 3.2 Assertion Categories

```
TRUTH: Every function has preconditions, postconditions are explicit, invariants are documented.
```

```c
// IMMUTABLE PATTERN: Function structure
int cosmo_buffer_write(CosmoBuffer *buf, const void *data, size_t len) {
    // PRECONDITIONS - Check inputs
    COSMO_PRECONDITION(buf != NULL);
    COSMO_PRECONDITION(data != NULL || len == 0);
    COSMO_PRECONDITION(len <= COSMO_BUFFER_MAX_WRITE);

    // INVARIANT - Check state consistency
    COSMO_INVARIANT(buf->pos <= buf->cap);

    // Implementation...
    size_t written = impl_write(buf, data, len);

    // POSTCONDITION - Check outputs
    COSMO_POSTCONDITION(written <= len);
    COSMO_POSTCONDITION(buf->pos <= buf->cap);

    return written;
}
```

### 3.3 Assertion Macros (Immutable Set)

```c
// These macros exist and have fixed semantics
COSMO_ASSERT(expr)                      // Basic boolean assertion
COSMO_ASSERT_MSG(expr, msg)             // With message
COSMO_ASSERT_EQ(a, b)                   // a == b
COSMO_ASSERT_NE(a, b)                   // a != b
COSMO_ASSERT_LT(a, b)                   // a < b
COSMO_ASSERT_LE(a, b)                   // a <= b
COSMO_ASSERT_GT(a, b)                   // a > b
COSMO_ASSERT_GE(a, b)                   // a >= b
COSMO_ASSERT_NULL(ptr)                  // ptr == NULL
COSMO_ASSERT_NOT_NULL(ptr)              // ptr != NULL
COSMO_ASSERT_ALIGNED(ptr, align)        // Alignment check
COSMO_ASSERT_IN_RANGE(val, lo, hi)      // lo <= val <= hi
COSMO_PRECONDITION(expr)                // Function entry check
COSMO_POSTCONDITION(expr)               // Function exit check
COSMO_INVARIANT(expr)                   // Loop/state invariant
COSMO_UNREACHABLE()                     // Mark unreachable code
COSMO_STATIC_ASSERT(expr)               // Compile-time assertion
```

---

## 4. Memory Management Architecture

```
TRUTH: Memory ownership is explicit. Every allocation has exactly one owner.
```

### 4.1 Allocation Strategies (Immutable)

| Strategy | Lifetime | Use Case |
|----------|----------|----------|
| Arena | Batch (reset together) | Parsing, request handling |
| Pool | Fixed-size, individual | Nodes, small objects |
| Malloc | Individual, arbitrary | Long-lived, variable size |
| Stack | Function scope | Temporary buffers |
| Hybrid | Arena + overflow | Unknown size batches |

### 4.2 Ownership Markers

```
TRUTH: Pointer parameters are annotated with ownership semantics.
```

```c
// IMMUTABLE ANNOTATIONS (in comments, enforced by convention)
void process(
    CosmoArena *arena,           // BORROWS: caller retains ownership
    const char *input,           // BORROWS: read-only access
    char **out_result            // GIVES: caller receives ownership
);

// Ownership transfer naming
CosmoBuffer *cosmo_buffer_create(void);     // GIVES to caller
void cosmo_buffer_destroy(CosmoBuffer *b);  // TAKES from caller
CosmoBuffer *cosmo_buffer_clone(const CosmoBuffer *b); // GIVES new copy
```

### 4.3 Arena Semantics

```
TRUTH: Arena allocation never fails if arena has capacity. Overflow behavior is configurable.
```

```c
// Immutable arena operations
CosmoArena *cosmo_arena_create(size_t initial_size);
CosmoArena *cosmo_arena_create_with_flags(size_t size, CosmoArenaFlags flags);
void *cosmo_arena_alloc(CosmoArena *a, size_t size);
void *cosmo_arena_alloc_aligned(CosmoArena *a, size_t size, size_t align);
void cosmo_arena_reset(CosmoArena *a);      // Reset to empty, keep memory
void cosmo_arena_destroy(CosmoArena *a);    // Free all memory
size_t cosmo_arena_used(const CosmoArena *a);
size_t cosmo_arena_capacity(const CosmoArena *a);
```

---

## 5. Branchless Programming Primitives

```
TRUTH: Branchless operations use arithmetic, not compiler intrinsics, for portability.
```

### 5.1 Core Primitives (Immutable)

```c
// These implementations are fixed
#define COSMO_SELECT(cond, a, b) \
    ((b) ^ (((a) ^ (b)) & -((cond) != 0)))

#define COSMO_MIN(a, b) \
    ((b) ^ (((a) ^ (b)) & -((a) < (b))))

#define COSMO_MAX(a, b) \
    ((a) ^ (((a) ^ (b)) & -((a) < (b))))

#define COSMO_ABS(x) \
    (((x) ^ ((x) >> (sizeof(x) * 8 - 1))) - ((x) >> (sizeof(x) * 8 - 1)))

#define COSMO_SIGN(x) \
    (((x) > 0) - ((x) < 0))

#define COSMO_CLAMP(x, lo, hi) \
    COSMO_MIN(COSMO_MAX(x, lo), hi)

#define COSMO_IS_POWER_OF_2(x) \
    ((x) != 0 && ((x) & ((x) - 1)) == 0)

#define COSMO_ALIGN_UP(x, align) \
    (((x) + (align) - 1) & ~((align) - 1))
```

### 5.2 When to Use Branchless

```
TRUTH: Branchless is used when: (1) branch is unpredictable, (2) data is cache-hot.
```

| Scenario | Use Branchless | Rationale |
|----------|----------------|-----------|
| Random boolean selection | Yes | Branch predictor ~50% miss |
| Sequential state machine | No | Branch predictor accurate |
| Sorting comparisons | Yes | Data-dependent branches |
| Error checking | No | Errors are rare (predictable) |
| Lookup table dispatch | Yes | Eliminates branch entirely |

---

## 6. Hash Table Integration

```
TRUTH: Static keyword sets MUST use gperf. Dynamic sets use framework hash tables.
```

### 6.1 gperf Integration Pattern

```
TRUTH: gperf output is committed to the repository, not generated at build time.
```

```bash
# Generate command (run by maintainer, not build)
gperf --language=ANSI-C \
      --struct-type \
      --readonly-tables \
      --enum \
      --includes \
      keywords.gperf > cosmo_keywords_hash.h
```

### 6.2 Hash Table Selection

| Set Size | Set Type | Hash Implementation |
|----------|----------|---------------------|
| < 100 | Static (known at compile) | gperf perfect hash |
| < 1000 | Static | gperf or compile-time FNV |
| Any | Dynamic (runtime) | `cosmo_hash_table` |
| > 10000 | Dynamic | `cosmo_hash_table` with resize |

---

## 7. Error Handling

```
TRUTH: Errors are returned, not thrown. Errno is set for system errors.
```

### 7.1 Return Value Convention

```c
// IMMUTABLE PATTERN: Pointer-returning functions
CosmoBuffer *cosmo_buffer_create(void);  // Returns NULL on failure

// IMMUTABLE PATTERN: Integer-returning functions
int cosmo_file_read(CosmoFile *f, void *buf, size_t len);
// Returns: bytes read (>= 0), or -1 on error with errno set

// IMMUTABLE PATTERN: Status-returning functions
CosmoStatus cosmo_parse(const char *input, CosmoAST **out);
// Returns: COSMO_OK or COSMO_ERR_*
```

### 7.2 Error Codes (Immutable Set)

```c
typedef enum {
    COSMO_OK = 0,
    COSMO_ERR_NOMEM,        // Out of memory
    COSMO_ERR_INVALID,      // Invalid argument
    COSMO_ERR_OVERFLOW,     // Buffer/integer overflow
    COSMO_ERR_IO,           // I/O error (check errno)
    COSMO_ERR_EOF,          // End of file/stream
    COSMO_ERR_NOTFOUND,     // Item not found
    COSMO_ERR_EXISTS,       // Item already exists
    COSMO_ERR_PERMISSION,   // Permission denied
    COSMO_ERR_BUSY,         // Resource busy
    COSMO_ERR_TIMEOUT,      // Operation timed out
    COSMO_ERR_UNSUPPORTED,  // Operation not supported
} CosmoStatus;
```

---

## 8. Platform Abstraction

```
TRUTH: Platform detection uses Cosmopolitan macros. Direct OS checks are forbidden.
```

### 8.1 Platform Detection (Immutable)

```c
// CORRECT: Use Cosmopolitan abstractions
#ifdef __COSMOPOLITAN__
    // Portable code path (most code)
#endif

#ifdef IsLinux()
    // Linux-specific (runtime check)
#endif

// FORBIDDEN: Direct OS checks
#ifdef __linux__     // NO - not portable
#ifdef _WIN32        // NO - not portable
#ifdef __APPLE__     // NO - not portable
```

### 8.2 Architecture Detection

```c
// IMMUTABLE: Architecture checks
#if defined(__x86_64__)
    // x86-64 specific optimizations
#elif defined(__aarch64__)
    // ARM64 specific optimizations
#else
    // Generic fallback
#endif
```

---

## 9. Build System Requirements

```
TRUTH: cosmocc is the primary compiler. GCC/Clang are fallbacks with reduced portability.
```

### 9.1 Compiler Flags (Immutable Baseline)

```makefile
# Required flags - NEVER remove these
CFLAGS_REQUIRED := -Wall -Wextra -Werror
CFLAGS_REQUIRED += -Wno-unused-parameter  # Callbacks often ignore params
CFLAGS_REQUIRED += -fno-strict-aliasing   # For type punning patterns

# Debug flags
CFLAGS_DEBUG := -g -O0 -DCOSMO_DEBUG=1 -fsanitize=undefined

# Release flags
CFLAGS_RELEASE := -O2 -DNDEBUG

# Tiny flags
CFLAGS_TINY := -Os -mtiny -DNDEBUG
```

### 9.2 Required Build Targets

```
TRUTH: Every project MUST have these make targets.
```

| Target | Purpose | Required |
|--------|---------|----------|
| `all` | Build default configuration | Yes |
| `debug` | Build with assertions, sanitizers | Yes |
| `release` | Build optimized, no assertions | Yes |
| `tiny` | Build size-optimized | Yes |
| `test` | Run all tests | Yes |
| `clean` | Remove build artifacts | Yes |
| `check` | Static analysis | Yes |

---

## 10. Testing Requirements

```
TRUTH: Every module has unit tests. Every public function is tested.
```

### 10.1 Test File Convention

```
TRUTH: Tests mirror source structure with _test suffix.
```

```
src/arena/cosmo_arena.c     -> tests/unit/arena/cosmo_arena_test.c
src/hash/cosmo_hash.c       -> tests/unit/hash/cosmo_hash_test.c
```

### 10.2 Test Macro Set (Immutable)

```c
COSMO_TEST(name)                        // Define test function
COSMO_TEST_ASSERT(expr)                 // Test assertion
COSMO_TEST_ASSERT_EQ(a, b)              // Equality check
COSMO_TEST_ASSERT_STR_EQ(a, b)          // String equality
COSMO_TEST_ASSERT_MEM_EQ(a, b, len)     // Memory equality
COSMO_TEST_EXPECT_SIGNAL(sig, expr)     // Expect signal (for death tests)
COSMO_TEST_SKIP(reason)                 // Skip test with reason
COSMO_TEST_SUITE(name)                  // Group tests
COSMO_RUN_TESTS()                       // Execute all tests
```

---

## 11. Documentation Requirements

```
TRUTH: Public APIs have doc comments. Internal code has rationale comments.
```

### 11.1 Doc Comment Format

```c
/**
 * @brief Create a new arena allocator.
 *
 * @param initial_size Initial capacity in bytes (will be rounded up to page size)
 * @return New arena, or NULL if allocation fails
 *
 * @pre initial_size > 0
 * @post Returned arena has capacity >= initial_size
 *
 * @note Arena memory is not zeroed. Use cosmo_arena_calloc for zeroed memory.
 *
 * @example
 *   CosmoArena *a = cosmo_arena_create(4096);
 *   void *p = cosmo_arena_alloc(a, 100);
 *   cosmo_arena_destroy(a);
 */
CosmoArena *cosmo_arena_create(size_t initial_size);
```

---

## Appendix: Immutable Principles Summary

1. **C11 base, C23 optional** - Maximum compatibility
2. **COSMO_ prefix** - Clear namespace ownership
3. **Assertions are mandatory** - 1:20 ratio minimum
4. **Explicit ownership** - No hidden allocations
5. **Branchless for unpredictable** - Measurable benefit only
6. **gperf for static sets** - O(1) guaranteed
7. **Return errors, don't throw** - Predictable control flow
8. **cosmocc primary** - Portable by default
9. **Test everything public** - No untested APIs
10. **Document the why** - Code explains what

---

*This document is IMMUTABLE. Framework version changes require a new major version.*
*Document version: 1.0.0*
