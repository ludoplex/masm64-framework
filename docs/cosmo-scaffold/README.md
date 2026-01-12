# Cosmo-Scaffold Documentation

Universal C framework scaffolding for [Cosmopolitan Libc](https://github.com/jart/cosmopolitan) portable executables.

## Documentation Structure

```
cosmo-scaffold/
├── PRD.md                          # Product Requirements Document
├── bible/
│   ├── BIBLE_IMMUTABLE.md          # Framework conventions (never changes)
│   └── BIBLE_PROJECT.md            # Project conventions (user-editable)
└── state/
    ├── STATE_IMMUTABLE.md          # Required application properties
    └── STATE_PROJECT.md            # Current project state (mutable)
```

## Document Purposes

### PRD.md
The Product Requirements Document defining the vision, architecture, and implementation plan for cosmo-scaffold. Includes upstream dependencies, success criteria, and phased rollout.

### Bible Files

| File | Mutability | Purpose |
|------|------------|---------|
| `BIBLE_IMMUTABLE.md` | **NEVER CHANGE** | Eternal truths about the framework: naming, assertions, memory, branchless patterns, error handling |
| `BIBLE_PROJECT.md` | User-editable | Project-specific conventions: style choices, targets, testing config |

### State Files

| File | Mutability | Purpose |
|------|------------|---------|
| `STATE_IMMUTABLE.md` | **NEVER CHANGE** | What every cosmo-scaffold app MUST have: init sequence, platform state, crash handling |
| `STATE_PROJECT.md` | Frequently updated | Current project status: features, tests, builds, performance, debt |

## Upstream Repositories

### To Fork (ludoplex)

| Upstream | Purpose | Status |
|----------|---------|--------|
| [jart/cosmopolitan](https://github.com/jart/cosmopolitan) | Core libc + cosmocc | **Not yet forked** |

### Reference Only (No Fork Needed)

| Repository | Purpose |
|------------|---------|
| [shmup/awesome-cosmopolitan](https://github.com/shmup/awesome-cosmopolitan) | Resource list |
| [matt-dunleavy/cosmo-project](https://github.com/matt-dunleavy/cosmo-project) | Build system reference |
| [TimonLukas/action-static-redbean](https://github.com/TimonLukas/action-static-redbean) | CI/CD patterns |
| [Welding-Torch/superconfigure](https://github.com/Welding-Torch/superconfigure) | Autoconf patterns |

## Quick Reference

### Key Principles (from BIBLE_IMMUTABLE)

1. **C11 base, C23 optional** - Maximum compatibility
2. **COSMO_ prefix** - Clear namespace
3. **1:20 assertion ratio** - Mandatory in debug
4. **Explicit ownership** - No hidden allocations
5. **Branchless for unpredictable** - Measure first
6. **gperf for static sets** - O(1) lookups
7. **Return errors, don't throw** - Predictable flow
8. **cosmocc primary** - Portable by default

### Core Patterns

```c
// Assertions everywhere
COSMO_PRECONDITION(buf != NULL);
COSMO_INVARIANT(arena->pos <= arena->cap);
COSMO_POSTCONDITION(written <= len);

// Arena allocation
CosmoArena *a = cosmo_arena_create(4096);
void *p = cosmo_arena_alloc(a, size);
cosmo_arena_reset(a);

// Branchless selection
int result = COSMO_SELECT(condition, value_if_true, value_if_false);

// Perfect hash (gperf)
const struct keyword *kw = in_word_set(str, len);
```

## Next Steps

1. Fork `jart/cosmopolitan` to `ludoplex/cosmopolitan`
2. Implement core headers (`cosmo_assert.h`, `cosmo_arena.h`, `cosmo_branchless.h`)
3. Create Copier template structure
4. Add gperf integration workflow
5. Build LLM prompt library with validators

---

*See individual documents for full details.*
