---
name: design-by-contract
description: Automated contract verification, detection, and remediation across multiple languages using formal preconditions, postconditions, and invariants. This skill provides both reference documentation AND execution capabilities for the full PLAN -> CREATE -> VERIFY -> REMEDIATE workflow.
---

# Design-by-Contract Development Skill

## Capability

Design-by-Contract (DbC) is a programming methodology that uses formal specifications (contracts) to define component behavior. This skill enables:

- **Contract Design**: Plan preconditions, postconditions, and invariants before implementation
- **Artifact Generation**: Create contract annotations across 8+ languages
- **Verification**: Run contract validation with appropriate runtime flags
- **Remediation**: Fix contract violations with targeted debugging

**Core Contract Types:**
- **Preconditions**: What must be true before a function executes (caller's duty)
- **Postconditions**: What must be true after a function executes (callee's promise)
- **Invariants**: What must always be true about object state

---

## When to Use

Design-by-Contract is ideal for:

- **Public API boundaries**: Validate inputs at module boundaries
- **Critical business logic**: Ensure computation correctness
- **State management**: Maintain object consistency
- **Integration points**: Verify data crossing system boundaries
- **Team collaboration**: Document expected behavior formally

---

## Workflow Overview

```nomnoml
[<start>Requirements] -> [Phase 1: PLAN]
[Phase 1: PLAN|
  Identify contracts
  Design predicates
  Map obligations
] -> [Phase 2: CREATE]
[Phase 2: CREATE|
  Generate annotations
  Add to .outline/contracts/
  Wire dependencies
] -> [Phase 3: VERIFY]
[Phase 3: VERIFY|
  Enable runtime flags
  Run test suite
  Check violations
] -> [Phase 4: REMEDIATE]
[Phase 4: REMEDIATE|
  Diagnose violation type
  Fix caller/callee/state
  Re-verify
] -> [<end>Success]
```

---

## Verification Hierarchy

**Principle**: Use compile-time verification before runtime contracts. If a property can be verified statically, do NOT add a runtime contract for it.

```
Static Assertions (compile-time) > Test/Debug Contracts > Runtime Contracts
```

### When to Use Each Level

| Property | Static | Test Contract | Debug Contract | Runtime Contract |
|----------|--------|---------------|----------------|------------------|
| Type size/alignment | `static_assert` (C++), `assert_eq_size!` (Rust) | - | - | - |
| Trait/interface bounds | `assert_impl_all!` (Rust), Concepts (C++) | - | - | - |
| Const value bounds | `const_assert!`, `static_assert` | - | - | - |
| Null/type safety | Type checker (tsc/pyright/kotlinc) | - | - | - |
| Exhaustiveness | Pattern matching + `never`/`Never` | - | - | - |
| Expensive O(n)+ checks | - | `test_ensures` | - | - |
| Reference impl equivalence | - | `test_ensures` | - | - |
| Internal state invariants | - | - | `debug_invariant` | - |
| Development preconditions | - | - | `debug_requires` | - |
| Public API input validation | - | - | - | `requires` |
| Safety-critical postconditions | - | - | - | `ensures` |
| External/untrusted data | - | - | - | Required (Zod/icontract) |

**Legend**: `-` = Do not use for this property

### Decision Flow

```
Can type system encode it? ──yes──> Use types (typestate, newtype)
         │no
         v
Verifiable at compile-time? ──yes──> static_assertions / const_assert!
         │no
         v
Expensive O(n)+ check? ──yes──> test_* (test builds only)
         │no
         v
Internal development aid? ──yes──> debug_* (debug builds only)
         │no
         v
Must enforce in production? ──yes──> Runtime contracts
         │no
         v
Consider if check is needed at all
```

---

## Phase 1: PLAN (Contract Design)

### Process

1. **Understand Requirements**
   - Parse user's task/requirement
   - Identify preconditions, postconditions, invariants
   - Use sequential-thinking to decompose contract obligations
   - Map requirements to contract types

2. **Artifact Detection (Conditional)**
   - Check for existing contract artifacts by language:
     ```bash
     # Rust (contracts crate)
     rg '#\[pre\(|#\[post\(|#\[invariant\(' $ARGUMENTS
     # TypeScript (Zod)
     rg 'z\.object|z\.string|\.refine\(' $ARGUMENTS
     # Python (icontract)
     rg '@pre\(|@post\(|@invariant\(' $ARGUMENTS
     # Java/Kotlin
     rg 'checkArgument|checkState|require\s*\{' $ARGUMENTS
     ```
   - If artifacts exist: analyze coverage gaps, plan extensions
   - If no artifacts: proceed to design contract architecture

3. **Design Contract Architecture**
   - Design precondition predicates
   - Plan postcondition guarantees
   - Define class/module invariants
   - Output: Contract design with annotation signatures

4. **Prepare Run Phase**
   - Define target: `.outline/contracts/`
   - Specify verification: language-specific contract checking
   - Create traceability: requirement -> contract -> enforcement

### Thinking Tool Integration

```
Use sequential-thinking for:
- Contract decomposition
- Obligation ordering
- Inheritance chain planning

Use actor-critic-thinking for:
- Contract strength evaluation
- Precondition completeness
- Postcondition sufficiency

Use shannon-thinking for:
- Contract coverage gaps
- Runtime verification costs
- Weakest precondition analysis
```

### Contract Design Templates

#### Rust (contracts crate)
```rust
// Target: .outline/contracts/{module}_contracts.rs

// From requirement: {requirement text}
#[pre(input > 0, "Input must be positive")]
#[post(ret.is_some() => ret.unwrap() > input)]
fn process(input: i32) -> Option<i32> {
    // Implementation in run phase
}

// Class invariant
#[invariant(self.balance >= 0)]
impl Account {
    // Methods maintain invariant
}
```

#### TypeScript (Zod)
```typescript
// Target: .outline/contracts/{module}.contracts.ts

// From requirement: {requirement text}
const InputSchema = z.object({
  value: z.number().positive("Value must be positive"),
}).refine(
  (data) => /* precondition */,
  { message: "Precondition: {description}" }
);

// Postcondition validator
const OutputSchema = z.object({
  result: z.number(),
}).refine(
  (data) => /* postcondition */,
  { message: "Postcondition: {description}" }
);
```

#### Python (icontract)
```python
# Target: .outline/contracts/{module}_contracts.py

# From requirement: {requirement text}
@icontract.require(lambda x: x > 0, "Input must be positive")
@icontract.ensure(lambda result: result is not None)
def process(x: int) -> Optional[int]:
    # Implementation in run phase
    pass
```

### Plan Output

1. **Requirements Analysis**
   - Preconditions identified
   - Postconditions guaranteed
   - Invariants to maintain

2. **Contract Architecture**
   - Contract signatures per function/method
   - Invariant definitions per class/module
   - Inheritance contract chains

3. **Target Artifacts**
   - `.outline/contracts/*` file list
   - Contract library dependencies
   - Runtime flag configuration

4. **Verification Commands**
   - Build with contracts enabled
   - Test suite exercising contracts
   - Success criteria: no contract violations

---

## Phase 2: CREATE (Generate Artifacts)

### Setup

```bash
# Create .outline/contracts directory
mkdir -p .outline/contracts
```

### Generate Contract Files by Language

#### Rust (contracts crate)
```rust
// .outline/contracts/{module}_contracts.rs
// Generated from plan design

use contracts::*;

// Source Requirement: {traceability from plan}

// Precondition: {from plan design}
// Postcondition: {from plan design}
#[pre(input > 0, "Input must be positive")]
#[post(ret.is_some() => ret.unwrap() > input, "Output must exceed input")]
pub fn process(input: i32) -> Option<i32> {
    // Implementation
    Some(input + 1)
}

// Class invariant: {from plan design}
#[invariant(self.balance >= 0, "Balance must be non-negative")]
impl Account {
    #[post(self.balance == old(self.balance) + amount)]
    pub fn deposit(&mut self, amount: u64) {
        self.balance += amount;
    }
}
```

#### TypeScript (Zod)
```typescript
// .outline/contracts/{module}.contracts.ts
// Generated from plan design

import { z } from 'zod';

// Source Requirement: {traceability from plan}

// Precondition schema: {from plan design}
export const InputSchema = z.object({
  value: z.number().positive("Value must be positive"),
  name: z.string().min(1, "Name required"),
}).refine(
  (data) => data.value < 1000,
  { message: "Precondition: value must be under 1000" }
);

// Postcondition schema: {from plan design}
export const OutputSchema = z.object({
  result: z.number(),
  success: z.boolean(),
}).refine(
  (data) => data.success || data.result === 0,
  { message: "Postcondition: failed operations must return 0" }
);

// Validation wrapper
export function withContracts<I, O>(
  inputSchema: z.ZodType<I>,
  outputSchema: z.ZodType<O>,
  fn: (input: I) => O
): (input: I) => O {
  return (input: I) => {
    const validInput = inputSchema.parse(input);
    const output = fn(validInput);
    return outputSchema.parse(output);
  };
}
```

#### Python (icontract)
```python
# .outline/contracts/{module}_contracts.py
# Generated from plan design

import icontract

# Source Requirement: {traceability from plan}

# Precondition: {from plan design}
# Postcondition: {from plan design}
@icontract.require(lambda x: x > 0, "Input must be positive")
@icontract.ensure(lambda result: result is not None, "Must return value")
@icontract.ensure(lambda x, result: result > x, "Output must exceed input")
def process(x: int) -> int:
    return x + 1


# Class invariant: {from plan design}
@icontract.invariant(lambda self: self.balance >= 0)
class Account:
    def __init__(self):
        self.balance = 0

    @icontract.require(lambda amount: amount > 0)
    @icontract.ensure(lambda self, amount, OLD: self.balance == OLD.balance + amount)
    def deposit(self, amount: int) -> None:
        self.balance += amount
```

---

## Phase 3: VERIFY (Contract Validation)

### Rust
```bash
# Ensure contracts are enabled (not disabled)
unset CONTRACTS_DISABLE

# Verify contracts exist
rg '#\[pre\(|#\[post\(|#\[invariant\(' .outline/contracts/ || exit 12

# Run tests with contracts
cargo test || exit 13
```

### TypeScript
```bash
# Verify Zod schemas exist
rg 'z\.object|\.refine\(' .outline/contracts/ || exit 12

# Run tests (Zod validates at runtime)
npx vitest run || exit 13
```

### Python
```bash
# Enable thorough contract checking
export ICONTRACT_SLOW=true

# Verify decorators exist
rg '@icontract\.(require|ensure|invariant)' .outline/contracts/ || exit 12

# Run tests
pytest || exit 13
```

### Java (Guava)
```bash
# Verify Guava preconditions exist
rg 'checkArgument|checkState|checkNotNull' .outline/contracts/ || exit 12

# Run tests
mvn test || exit 13
```

### C++ (GSL/Boost)
```bash
# Ensure NDEBUG is NOT set for contract checking
unset NDEBUG

# Verify contracts exist
rg 'Expects\(|Ensures\(' .outline/contracts/ || exit 12

# Build and test
cmake --build build && ./build/tests || exit 13
```

---

## Phase 4: REMEDIATE (Fix Violations)

### Contract Violation Types

| Violation | Exit Code | Fix Strategy |
|-----------|-----------|--------------|
| Precondition | 1 | Fix caller to meet requirements |
| Postcondition | 2 | Fix implementation to meet guarantee |
| Invariant | 3 | Fix state management logic |

### Debugging by Violation Type

**Precondition Violation (Caller's fault)**
```python
# Error: icontract.ViolationError: Pre: x > 0
# The CALLER passed invalid input

# Debug: Check call site
# Before:
result = process(-5)  # WRONG: violates x > 0

# After:
if x > 0:
    result = process(x)
else:
    handle_invalid_input(x)
```

**Postcondition Violation (Callee's fault)**
```python
# Error: icontract.ViolationError: Post: result > x
# The IMPLEMENTATION doesn't meet its guarantee

# Debug: Fix the function
# Before:
@icontract.ensure(lambda x, result: result > x)
def process(x: int) -> int:
    return x  # WRONG: not > x

# After:
@icontract.ensure(lambda x, result: result > x)
def process(x: int) -> int:
    return x + 1  # Correct
```

**Invariant Violation (State corruption)**
```python
# Error: icontract.ViolationError: Inv: self.balance >= 0
# Object state became invalid after operation

# Debug: Find state mutation that breaks invariant
# Before:
@icontract.invariant(lambda self: self.balance >= 0)
class Account:
    def withdraw(self, amount):
        self.balance -= amount  # WRONG: can go negative

# After:
    @icontract.require(lambda self, amount: amount <= self.balance)
    def withdraw(self, amount):
        self.balance -= amount  # Now protected by precondition
```

### Contract Patterns

**Precondition (Caller's Duty)**
```
INPUT --> VALIDATE --> PROCESS
            |
            v
         FAIL FAST if invalid
```

**Postcondition (Callee's Promise)**
```
PROCESS --> OUTPUT --> VALIDATE
                          |
                          v
                       ASSERT guarantee met
```

**Invariant (Always True)**
```
OPERATION --> STATE CHANGE --> CHECK INVARIANT
                                  |
                                  v
                               ASSERT still valid
```

---

## Commands Reference

### dbc-verify
Verify all contracts satisfied in codebase.

**Usage**: `dbc-verify [--lang LANG] [--path PATH] [--runtime-flags]`

**Algorithm**:
```
1. Detect language(s) in scope (fd file extensions)
2. Check runtime flags enabled per language
3. Scan for contract library usage (rg patterns)
4. Execute language-specific verification
5. Report violations with exit codes
```

### dbc-detect
Detect contract usage and missing contracts.

**Usage**: `dbc-detect [--lang LANG] [--missing] [--violations]`

**Algorithm**:
```
1. Scan for contract library imports (rg)
2. Find functions without contracts (ast-grep negative match)
3. Identify contract violations (pattern analysis)
4. Generate coverage report
```

### dbc-remediate
Auto-fix violations or add missing contracts.

**Usage**: `dbc-remediate [--add-missing] [--fix-violations] [--dry-run]`

**Algorithm**:
```
1. Identify remediation targets (missing/violated contracts)
2. Generate contract code per language
3. Apply fixes via ast-grep or native-patch
4. Verify fixes with dbc-verify
```

---

## Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | All contracts pass | Ready for deployment |
| 1 | Precondition fail | Fix caller to meet requirements |
| 2 | Postcondition fail | Fix implementation |
| 3 | Invariant fail | Fix state management |
| 11 | Library missing | Install contract library |
| 12 | No contracts | Run plan phase, create contracts |
| 13 | Verification failed | Debug and fix violations |

---

## Language-Specific Implementations

### Rust Detection
```bash
# Find contracts
rg '#\[pre\(|#\[post\(|#\[invariant\(|debug_assert!' --type rust

# Find functions without contracts
ast-grep -p 'fn $NAME($$$) { $$$ }' -l rust | \
  rg -v '#\[pre\(|debug_assert!' --files-without-match
```

**Remediation template**:
```rust
#[pre($CONDITION)]
#[post(ret $POSTCONDITION)]
fn $NAME($PARAMS) -> $RET {
    debug_assert!($CONDITION, "$ERROR_MSG");
    $BODY
}
```

**Runtime flags**: Check `CARGO_BUILD_TYPE != release` or `cfg(debug_assertions)`

### TypeScript Detection
```bash
# Find contracts
rg 'z\.object|invariant\(|\.parse\(|\.safeParse\(' --type ts

# Find functions without validation
ast-grep -p 'function $NAME($$$): $$$ { $$$ }' -l typescript | \
  rg -v 'z\.|invariant' --files-without-match
```

**Remediation template**:
```typescript
const ${NAME}Schema = z.object({
  $FIELDS
});

function $NAME(params: unknown): $RET {
  const validated = ${NAME}Schema.parse(params);
  invariant($CONDITION, "$ERROR_MSG");
  $BODY
}
```

**Runtime flags**: Check `process.env.NODE_ENV === 'development'`

### Python Detection
```bash
# Find contracts
rg '@pre\(|@post\(|@invariant|@require|@ensure' --type python

# Find functions without contracts
ast-grep -p 'def $NAME($$$): $$$' -l python | \
  rg -v '@pre|@post|@invariant' --files-without-match
```

**Remediation template**:
```python
@pre(lambda $PARAMS: $CONDITION)
@post(lambda result: $POSTCONDITION)
def $NAME($PARAMS) -> $RET:
    """$DOCSTRING"""
    $BODY
```

**Runtime flags**: Check `__debug__` is True (not `python -O`)

### Java Detection
```bash
# Find contracts
rg 'checkArgument|checkState|validate\(|Preconditions\.' --type java

# Find methods without contracts
ast-grep -p 'public $RET $NAME($$$) { $$$ }' -l java | \
  rg -v 'checkArgument|validate' --files-without-match
```

**Remediation template**:
```java
public $RET $NAME($PARAMS) {
    checkArgument($CONDITION, "$ERROR_MSG");
    $BODY
    validate($POSTCONDITION, "$POST_ERROR");
    return $RESULT;
}
```

**Runtime flags**: Check assertions enabled with `-ea` flag

### Kotlin Detection
```bash
# Find contracts
rg 'contract \{|Either<|Validated|require\(|check\(' --type kotlin

# Find functions without contracts
ast-grep -p 'fun $NAME($$$): $$$ { $$$ }' -l kotlin | \
  rg -v 'contract|require|check' --files-without-match
```

**Remediation template**:
```kotlin
fun $NAME($PARAMS): Either<$ERR, $RET> {
    contract {
        returns() implies ($CONDITION)
    }
    return if (!$CONDITION) "$ERROR".left()
           else { $BODY }.right()
}
```

**Runtime flags**: Check `-ea` for JVM assertions

### C# Detection
```bash
# Find contracts
rg 'Guard\.Against|Contract\.Requires|Contract\.Ensures|Debug\.Assert' --type cs

# Find methods without contracts
ast-grep -p 'public $RET $NAME($$$) { $$$ }' -l csharp | \
  rg -v 'Guard\.|Contract\.' --files-without-match
```

**Remediation template**:
```csharp
public $RET $NAME($PARAMS) {
    Guard.Against.Null($PARAM, nameof($PARAM));
    Contract.Ensures(Contract.Result<$RET>() $POSTCONDITION);
    $BODY
}
```

**Runtime flags**: Check Debug configuration

### C++ Detection
```bash
# Find contracts
rg 'Expects\(|Ensures\(|boost::contract|gsl::' --type cpp

# Find functions without contracts
ast-grep -p '$RET $NAME($$$) { $$$ }' -l cpp | \
  rg -v 'Expects|Ensures' --files-without-match
```

**Remediation template**:
```cpp
$RET $NAME($PARAMS) {
    Expects($PRECONDITION);
    $BODY
    Ensures($POSTCONDITION);
    return $RESULT;
}
```

**Runtime flags**: Check `NDEBUG` not defined

### C Detection
```bash
# Find contracts
rg 'assert\(|static_assert' --type c

# Find functions without asserts
ast-grep -p '$RET $NAME($$$) { $$$ }' -l c | \
  rg -v 'assert\(' --files-without-match
```

**Remediation template**:
```c
$RET $NAME($PARAMS) {
    assert($PRECONDITION && "$ERROR_MSG");
    $BODY
    assert($POSTCONDITION && "$POST_ERROR");
    return $RESULT;
}
```

**Runtime flags**: Check `NDEBUG` not defined

---

## Contract Library Matrix

| Language | Library | Runtime Flag |
|----------|---------|--------------|
| Rust | contracts | CONTRACTS_DISABLE |
| TypeScript | Zod | (always active) |
| Python | icontract | ICONTRACT_SLOW |
| Java | Guava | (always active) |
| Kotlin | native | (always active) |
| C# | Guard | (always active) |
| C++ | GSL/Boost | NDEBUG |

---

## Error Handling Matrix

| Language | Contract Library | Error Type | Error Handling | Recovery Strategy |
|----------|-----------------|------------|----------------|-------------------|
| **Rust** | contracts, prusti | panic! | `catch_unwind` (discouraged) | Result/Option types |
| **TypeScript** | zod, io-ts | ZodError, thrown | try/catch | Either/Result pattern |
| **Python** | dpcontracts, icontract | AssertionError | try/except | Optional/Result |
| **Java** | Guava, Bean Validation | IllegalArgumentException | try/catch | Optional/Either |
| **Kotlin** | Arrow, require/check | IllegalArgumentException | try/catch | Either<E, A> |
| **C#** | Code Contracts, Guard | ArgumentException | try/catch | Result<T> |
| **C++** | GSL, Boost.Contract | std::terminate | noexcept | std::expected |
| **C** | assert.h | abort() | Signal handler | Return codes |

### Error Message Best Practices

```
Contract Type: [PRECONDITION|POSTCONDITION|INVARIANT]
Location: file.rs:42 in function_name()
Condition: x > 0 && x < 100
Actual Value: x = -5
Expected: Positive integer less than 100
Context: Processing user input for order ID
```

---

## Troubleshooting Guide

### Common Issues

| Symptom | Cause | Resolution |
|---------|-------|------------|
| Exit 1 | Precondition violation | Caller must provide valid input (fix call site) |
| Exit 2 | Postcondition violation | Implementation doesn't meet guarantee (fix function) |
| Exit 3 | Invariant violation | Object state became invalid (fix state mutation) |
| Exit 11 | Contract library missing | Install: `pip install icontract`, `cargo add contracts`, `npm i zod` |
| Exit 12 | No contract annotations | Run plan phase first |
| Exit 13 | Tests failed with contracts | Debug violation type |
| `CONTRACTS_DISABLE` set | Contracts silently skipped | `unset CONTRACTS_DISABLE` |
| No error but wrong behavior | Contract too weak | Strengthen pre/post conditions |
| Performance impact | Contracts in hot path | Use `@icontract.require(enabled=DEBUG)` |
| Contract not firing | Debug assertions disabled | Check `NDEBUG`, `-O` flags |
| False positive | Contract too strict | Review expected vs actual |
| False negative | Contract too weak | Add edge case tests |
| Stack overflow | Recursive contract | Check for cycles |
| Flaky failures | Race condition in contract | Add synchronization |

### Quick Diagnostics

```bash
# Check if contracts are enabled (Rust)
cargo build && rg 'debug_assert' target/debug/*.d

# Check if contracts are enabled (Node.js)
node -e "console.log(process.env.NODE_ENV)"

# Check if assertions enabled (Java)
java -ea -version 2>&1 | head -1

# Check if assertions enabled (C/C++)
cpp -dM /dev/null | grep NDEBUG
```

### Debugging Commands

```bash
# Python - Verbose contract errors
ICONTRACT_SLOW=true pytest -v --tb=long

# Python - Find contract decorators
rg '@icontract\.(require|ensure|invariant)' src/

# Rust - Enable backtrace
RUST_BACKTRACE=1 cargo test

# Rust - Find contract attributes
rg '#\[(pre|post|invariant)\(' src/

# TypeScript - Verbose Zod errors
DEBUG=zod:* npm test

# TypeScript - Find Zod schemas
rg 'z\.(object|refine|string|number)' src/

# General - Check contracts not disabled
env | rg -i 'contract|ndebug'
```

### Debugging Contract Violation Workflows

#### Precondition Violation Debugging

1. **Identify the violation location**:
   ```bash
   # Run with debug symbols
   RUST_BACKTRACE=1 cargo run   # Rust
   node --enable-source-maps    # Node.js
   python -c "import traceback" # Python
   ```

2. **Examine the call stack**:
   - Find the caller that provided invalid input
   - Check intermediate transformations that corrupted data

3. **Add tracing at contract boundary**:
   ```rust
   // Rust example
   #[pre(x > 0)]
   fn process(x: i32) {
       tracing::debug!("process called with x = {}", x);
       // ...
   }
   ```

4. **Common causes**:
   - Unvalidated user input
   - Null/None propagation
   - Integer overflow in computation
   - Incorrect API usage

#### Postcondition Violation Debugging

1. **Instrument the function exit**:
   ```typescript
   // TypeScript example
   function calculate(x: number): number {
     const result = /* computation */;
     console.log(`calculate returning: ${result}`);
     invariant(result > 0, `Expected positive, got ${result}`);
     return result;
   }
   ```

2. **Check intermediate state**:
   - Add assertions at each computation step
   - Verify loop invariants maintained

3. **Common causes**:
   - Logic error in computation
   - Incorrect formula
   - Edge case not handled
   - Floating point precision loss

#### Invariant Violation Debugging

1. **Track state transitions**:
   ```python
   # Python example with dpcontracts
   @invariant(lambda self: self.balance >= 0)
   class Account:
       def __init__(self):
           self._log_state("init")

       def withdraw(self, amount):
           self._log_state(f"before withdraw {amount}")
           self.balance -= amount
           self._log_state(f"after withdraw {amount}")
   ```

2. **Find mutation that breaks invariant**:
   - Identify all state-mutating methods
   - Check each mutation point

3. **Common causes**:
   - Missing validation in setter
   - Concurrent modification
   - Deserialization bypassing constructor

---

## Common Pitfalls and Solutions

### Pitfall 1: Contracts with Side Effects

**Problem:** Contract check modifies program state.

**Solution:**
```rust
// WRONG: Contract has side effect
#[pre(counter.increment() > 0)]  // Modifies counter!
fn process() { ... }

// RIGHT: Contract is pure
#[pre(counter.value() > 0)]  // Only reads counter
fn process() { ... }
```

### Pitfall 2: Expensive Contract Checks

**Problem:** Contract check is O(n) or worse, causing performance issues.

**Solution:**
```typescript
// WRONG: O(n) check on every call
function process(items: Item[]) {
  invariant(items.every(i => isValid(i)), "All items must be valid");
  // Called millions of times...
}

// RIGHT: Check once at boundary, trust internally
function publicApi(items: Item[]) {
  const validated = items.filter(isValid);  // Validate at boundary
  processInternal(validated);  // Internal trusts input
}
```

### Pitfall 3: Incomplete Error Context

**Problem:** Contract failure message doesn't help debugging.

**Solution:**
```python
# WRONG: No context
assert x > 0

# RIGHT: Full context
assert x > 0, f"Expected positive x, got {x} (type={type(x).__name__}, caller={inspect.stack()[1].function})"
```

### Pitfall 4: Contracts Disabled in Production

**Problem:** Critical contracts disabled, bugs reach production.

**Solution:**
```rust
// Separate debug-only from critical contracts
#[cfg(debug_assertions)]
debug_assert!(validation_heavy_check());  // Debug only

// Critical contracts always enabled
assert!(user_id.is_valid(), "Invalid user ID");  // Always runs
```

### Pitfall 5: Circular Contract Dependencies

**Problem:** Contract A checks contract B which checks contract A.

**Solution:**
```java
// WRONG: Circular dependency
class A {
    @Requires("b.isValid()")  // Calls B
    void process(B b) { ... }
}
class B {
    @Requires("a.isValid()")  // Calls A, which calls B...
    void validate(A a) { ... }
}

// RIGHT: Break cycle with primitive checks
class A {
    @Requires("b.id != null && b.state == State.READY")
    void process(B b) { ... }
}
```

---

## Contract Strength Guidelines

**Too Weak (misses bugs)**
```python
@icontract.require(lambda x: True)  # Useless
def divide(x, y):
    return x / y  # Will crash on y=0
```

**Appropriate Strength**
```python
@icontract.require(lambda y: y != 0, "Divisor must be non-zero")
@icontract.ensure(lambda x, y, result: abs(result * y - x) < 1e-10)
def divide(x, y):
    return x / y
```

**Too Strong (rejects valid inputs)**
```python
@icontract.require(lambda x: x > 0 and x < 100)  # Overly restrictive
def process(x):
    return x * 2  # Works for any number
```

---

## Contract Composition Patterns

### Layered Contracts

```
Public API Layer:    [Strong Preconditions]
                            |
Service Layer:       [Moderate Preconditions]
                            |
Domain Layer:        [Minimal Preconditions + Strong Invariants]
                            |
Infrastructure:      [Postconditions on I/O]
```

### Contract Inheritance

```java
// Base contract
interface Processor {
    @Requires("input != null")
    @Ensures("result != null")
    Result process(Input input);
}

// Subtype strengthens postcondition (allowed)
// Subtype weakens precondition (allowed)
class SafeProcessor implements Processor {
    @Requires("true")  // Weaker: accepts any input
    @Ensures("result != null && result.isValid()")  // Stronger: guarantees validity
    Result process(Input input) { ... }
}
```

### Contract Refinement

```kotlin
// Start with weak contract, refine as understanding grows
// Version 1: Basic
fun process(x: Int): Int {
    require(true) { "No constraints yet" }
    // ...
}

// Version 2: After discovering constraints
fun process(x: Int): Int {
    require(x > 0) { "x must be positive" }
    // ...
}

// Version 3: After discovering more constraints
fun process(x: Int): Int {
    require(x in 1..1000) { "x must be between 1 and 1000" }
    // ...
}
```

---

## When NOT to Use Design-by-Contract

| Scenario | Better Alternative |
|----------|-------------------|
| Proving mathematical properties | Proof-driven (Lean 4) |
| Compile-time guarantees | Type-driven (Idris 2) |
| Complex state machine correctness | Validation-first (Quint) |
| Performance-critical inner loops | Disable in release, use types |
| Third-party library integration | Wrapper with contracts at boundary |
| Already have strong types | Contracts may be redundant |

---

## Complementary Approaches

- **Contract + Type-driven**: Types encode structure, contracts encode behavior
- **Contract + Test-driven**: Contracts as executable specs, tests for coverage
- **Contract + Property-based**: Contracts define valid space, property tests explore it

---

## Safety Requirements

1. **No side effects**: Contract checks must not modify state
2. **Performance**: Disable expensive checks in release builds
3. **Thread safety**: Contracts must be thread-safe
4. **Memory safety**: No allocations in hot paths
5. **Determinism**: Same inputs produce same contract evaluation

---

## Best Practices

1. **Boundary validation**: Add preconditions at all public API boundaries
2. **Critical postconditions**: Use postconditions for guarantees that affect downstream code
3. **State invariants**: Add invariants at construction and after state mutations
4. **Fail fast**: Include clear error messages with context
5. **Graduated deployment**: Disable expensive contracts in production (when safe)
6. **Type composition**: Combine contracts with type system for compile-time checks
7. **Documentation**: Document contract rationale in comments
8. **Testing**: Test contract violations explicitly in unit tests

---

## Performance Considerations

| Aspect | Development | Production |
|--------|-------------|------------|
| Preconditions | Always enabled | Critical only |
| Postconditions | Always enabled | Disabled |
| Invariants | Full checking | Disabled |
| Logging | Verbose | Minimal |
| Cost per check | O(1) acceptable | O(1) required |

### Optimization Strategies

```rust
// Conditional compilation
#[cfg(debug_assertions)]
fn expensive_check() { ... }

// Feature flags
#[cfg(feature = "contracts")]
fn contract_check() { ... }

// Inline for hot paths
#[inline(always)]
fn fast_precondition() { ... }
```

---

## Integration Workflow

```nomnoml
[<start>Start] -> [dbc-detect]
[dbc-detect] found contracts -> [dbc-verify]
[dbc-detect] no contracts -> [dbc-remediate --add-missing]
[dbc-verify] pass -> [<end>Success]
[dbc-verify] fail -> [dbc-remediate --fix-violations]
[dbc-remediate --add-missing] -> [dbc-verify]
[dbc-remediate --fix-violations] -> [dbc-verify]
```

---

## Resources

- [Design by Contract (Meyer)](https://en.wikipedia.org/wiki/Design_by_contract)
- [Eiffel: Birthplace of DbC](https://www.eiffel.com/values/design-by-contract/)
- [Microsoft Code Contracts](https://docs.microsoft.com/en-us/dotnet/framework/debug-trace-profile/code-contracts)
- [Rust contracts crate](https://crates.io/crates/contracts)
- [Python icontract](https://github.com/Parquery/icontract)
- [TypeScript zod](https://github.com/colinhacks/zod)
