# STATE_PROJECT.md - Project Application State

> **MUTABLE**: This document tracks the current state of YOUR application.
> Update it as your project evolves.
> For required framework state, see `STATE_IMMUTABLE.md`.

---

## Project Metadata

| Field | Value | Last Updated |
|-------|-------|--------------|
| Project Name | `{{project_name}}` | {{current_date}} |
| Current Version | `0.1.0` | {{current_date}} |
| Development Phase | [ ] Planning / [ ] Alpha / [ ] Beta / [ ] Stable | |
| Last Build | _Never_ | |
| Last Test Run | _Never_ | |
| Last Release | _None_ | |

---

## 1. Feature State

### 1.1 Implemented Features

| Feature | Status | Since | Notes |
|---------|--------|-------|-------|
| _Example: CLI parsing_ | Complete | v0.1.0 | Uses getopt_long |
| | | | |
| | | | |

### 1.2 In-Progress Features

| Feature | Progress | Target | Blockers |
|---------|----------|--------|----------|
| | | | |
| | | | |

### 1.3 Planned Features

| Feature | Priority | Target Version | Dependencies |
|---------|----------|----------------|--------------|
| | | | |
| | | | |

---

## 2. Memory State

### 2.1 Arena Instances

| Arena Name | Purpose | Size | Lifetime |
|------------|---------|------|----------|
| `g_request_arena` | Per-request data | 64KB | Request |
| `g_parse_arena` | Parser temporaries | 256KB | Parse |
| _(add yours)_ | | | |

### 2.2 Current Memory Usage

| Metric | Debug | Release | Tiny |
|--------|-------|---------|------|
| Binary size | _TBD_ | _TBD_ | _TBD_ |
| Heap at startup | _TBD_ | _TBD_ | _TBD_ |
| Peak heap | _TBD_ | _TBD_ | _TBD_ |
| Arena high water | _TBD_ | _TBD_ | _TBD_ |

### 2.3 Allocation Hot Spots

| Location | Count/sec | Size | Strategy |
|----------|-----------|------|----------|
| | | | |
| | | | |

---

## 3. Assertion State

### 3.1 Assertion Coverage

| Module | LOC | Assertions | Ratio | Status |
|--------|-----|------------|-------|--------|
| `src/main.c` | | | | [ ] Pass / [ ] Needs work |
| | | | | |
| **Total** | | | | |

### 3.2 Recent Assertion Failures

| Date | Location | Expression | Resolution |
|------|----------|------------|------------|
| | | | |
| | | | |

### 3.3 Disabled Assertions

| Location | Reason | Ticket | Re-enable By |
|----------|--------|--------|--------------|
| | | | |

---

## 4. Error Handling State

### 4.1 Error Code Usage

| Error Code | Occurrences | Handler Locations |
|------------|-------------|-------------------|
| `{{PROJECT}}_OK` | | All success paths |
| `{{PROJECT}}_ERR_NOMEM` | | |
| | | |

### 4.2 Unhandled Error Paths

| Location | Error Type | Status | Owner |
|----------|------------|--------|-------|
| | | [ ] TODO / [ ] Won't Fix | |
| | | | |

---

## 5. Test State

### 5.1 Test Coverage Summary

| Metric | Current | Target | Delta |
|--------|---------|--------|-------|
| Line coverage | _%_ | 80% | |
| Branch coverage | _%_ | 70% | |
| Function coverage | _%_ | 100% | |

### 5.2 Test Suites

| Suite | Tests | Pass | Fail | Skip | Duration |
|-------|-------|------|------|------|----------|
| `unit/arena` | | | | | |
| `unit/hash` | | | | | |
| `integration` | | | | | |
| **Total** | | | | | |

### 5.3 Flaky Tests

| Test Name | Failure Rate | Last Investigated | Status |
|-----------|--------------|-------------------|--------|
| | | | |

### 5.4 Missing Tests

| Function/Module | Reason | Priority | Ticket |
|-----------------|--------|----------|--------|
| | | | |
| | | | |

---

## 6. Build State

### 6.1 Build Matrix Status

| OS | Arch | Mode | Status | Last Build | Notes |
|----|------|------|--------|------------|-------|
| Linux | x86_64 | debug | [ ] Pass | | |
| Linux | x86_64 | release | [ ] Pass | | |
| Linux | x86_64 | tiny | [ ] Pass | | |
| Linux | aarch64 | debug | [ ] Pass | | |
| Linux | aarch64 | release | [ ] Pass | | |
| macOS | x86_64 | release | [ ] Pass | | |
| macOS | aarch64 | release | [ ] Pass | | |
| Windows | x86_64 | release | [ ] Pass | | |
| FreeBSD | x86_64 | release | [ ] Pass | | |

### 6.2 Build Warnings

| Warning | Count | Location(s) | Status |
|---------|-------|-------------|--------|
| `-Wunused-variable` | | | [ ] Fix / [ ] Suppress |
| | | | |

### 6.3 Static Analysis Results

| Tool | Issues | Critical | Last Run |
|------|--------|----------|----------|
| `clang-tidy` | | | |
| `cppcheck` | | | |
| `cosmo lint` | | | |

---

## 7. Performance State

### 7.1 Benchmark Results

| Benchmark | Current | Previous | Delta | Target |
|-----------|---------|----------|-------|--------|
| _Example: requests/sec_ | | | | |
| | | | | |

### 7.2 Branchless Optimizations

| Location | Before | After | Speedup | Verified |
|----------|--------|-------|---------|----------|
| | | | | [ ] Yes |
| | | | | |

### 7.3 Performance Regressions

| Version | Benchmark | Regression | Cause | Status |
|---------|-----------|------------|-------|--------|
| | | | | |

---

## 8. Hash Table State

### 8.1 gperf Tables

| Table Name | Keywords | Size | Generated | Verified |
|------------|----------|------|-----------|----------|
| | | | | [ ] Yes |
| | | | | |

### 8.2 Runtime Tables

| Table Name | Avg Size | Load Factor | Resizes/hour |
|------------|----------|-------------|--------------|
| | | | |
| | | | |

---

## 9. Platform-Specific State

### 9.1 Platform-Specific Code

| Code Path | Platforms | Tested | Notes |
|-----------|-----------|--------|-------|
| | | | |
| | | | |

### 9.2 Platform Bugs/Workarounds

| Platform | Issue | Workaround | Status |
|----------|-------|------------|--------|
| | | | |
| | | | |

---

## 10. CI/CD State

### 10.1 Pipeline Status

| Workflow | Last Run | Status | Duration | Notes |
|----------|----------|--------|----------|-------|
| `build.yml` | | [ ] Pass | | |
| `test.yml` | | [ ] Pass | | |
| `release.yml` | | [ ] Pass | | |

### 10.2 CI Failures (Last 30 Days)

| Date | Workflow | Failure | Root Cause | Fixed |
|------|----------|---------|------------|-------|
| | | | | |
| | | | | |

### 10.3 Deployment State

| Environment | Version | Deployed | By | Status |
|-------------|---------|----------|-----|--------|
| Production | | | | |
| Staging | | | | |
| Development | | | | |

---

## 11. Documentation State

### 11.1 Documentation Coverage

| Document | Status | Last Updated | Owner |
|----------|--------|--------------|-------|
| README.md | [ ] Current | | |
| API Reference | [ ] Current | | |
| Architecture | [ ] Current | | |
| CHANGELOG | [ ] Current | | |

### 11.2 Documentation Debt

| Item | Priority | Ticket | Notes |
|------|----------|--------|-------|
| | | | |
| | | | |

---

## 12. Security State

### 12.1 Vulnerability Status

| CVE/Issue | Severity | Status | Mitigated | Notes |
|-----------|----------|--------|-----------|-------|
| | | | | |
| | | | | |

### 12.2 Security Audit History

| Date | Auditor | Scope | Findings | Status |
|------|---------|-------|----------|--------|
| | | | | |

### 12.3 Fuzzing State

| Fuzzer | Corpus Size | Crashes Found | Coverage | Last Run |
|--------|-------------|---------------|----------|----------|
| | | | | |
| | | | | |

---

## 13. Dependency State

### 13.1 Direct Dependencies

| Dependency | Current | Latest | Update Status |
|------------|---------|--------|---------------|
| Cosmopolitan | | | [ ] Current |
| | | | |

### 13.2 Dependency Updates Needed

| Dependency | Current | Target | Reason | Blockers |
|------------|---------|--------|--------|----------|
| | | | | |
| | | | | |

---

## 14. Technical Debt

### 14.1 Known Issues

| Issue | Severity | Location | Workaround | Ticket |
|-------|----------|----------|------------|--------|
| | | | | |
| | | | | |

### 14.2 Refactoring Queue

| Area | Reason | Effort | Priority | Ticket |
|------|--------|--------|----------|--------|
| | | | | |
| | | | | |

### 14.3 Cleanup Tasks

| Task | Status | Owner | Due |
|------|--------|-------|-----|
| | [ ] TODO | | |
| | | | |

---

## Changelog

| Date | Section | Change | Author |
|------|---------|--------|--------|
| {{current_date}} | All | Initial creation | {{maintainer}} |
| | | | |
| | | | |

---

*This document is MUTABLE. Update it whenever project state changes.*
*Keep it current - stale state documentation is worse than none.*
*Template version: 1.0.0*
