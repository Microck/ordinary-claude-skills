---
name: proof-composer
description: Validates entire engineering proof chain. Verifies architecture, backend maps, backend code, standardization, frontend types, infrastructure topology all compose correctly. This is the final DEPLOYMENT GATE - deployment blocked if proof chain invalid. Use when engineering thread completes all actions.
version: 1.0.0
allowed-tools: bash_tool, view
model: claude-sonnet-4-20250514
license: Proprietary - LeanOS Engineering Layer
---

# proof-composer: System-Wide Proof Validation (DEPLOYMENT GATE)

## Purpose

Validate entire engineering proof chain and authorize deployment. This is the **final deployment gate** - nothing deploys without a valid composed proof.

**Key insight:** Each skill generates local proofs. proof-composer verifies they compose into a valid system-wide proof.

**Process:**
1. Collect all proofs (architecture, backend, frontend, infrastructure)
2. Verify version consistency (all use same spec version)
3. Validate proof chain (architecture → backend → standardization → frontend → infrastructure)
4. Check for gaps (missing proofs, incomplete verification)
5. Generate composed proof certificate (authorizes deployment)

---

## Position in Engineering Layer

You are skill #6 of 6 (FINAL GATE):

1. **system-architect** - Requirements → Specifications + Curry-Howard proofs
2. **backend-prover** - Specifications → Maps → Code + Runtime monitors
3. **standardization-layer** - Code → Middleware injection (naturality proofs)
4. **frontend-prover** - OpenAPI → TypeScript + Framework bindings + Type correspondence
5. **infrastructure-prover** - Services spec → Deployment configs + Topology isomorphism
6. **proof-composer** (YOU) - Validates entire chain + Authorizes deployment

---

## Input Requirements

**All proofs from previous skills:**
```
artifacts/engineering/proofs/
├── architecture/
│   ├── adt-correctness/
│   ├── functor-laws/
│   ├── composition-correctness/
│   ├── state-machines/
│   └── curry-howard-proofs/
│
├── backend/
│   ├── map-validation/
│   │   └── validation-report.json
│   ├── implementation-correctness/
│   ├── standardization/
│   │   └── naturality-certificate.proof
│   └── runtime-verification/
│
├── frontend/
│   └── type-correspondence/
│       └── openapi-to-typescript.proof
│
└── infrastructure/
    └── topology/
        └── deployment-isomorphism.proof
```

**Specification manifest:**
```
artifacts/engineering/specifications/manifest.json
```

**Generated artifacts:**
```
artifacts/engineering/
├── specifications/v{X}/          # From system-architect
├── maps/backend/                 # From backend-prover Phase 1
├── code/backend/                 # From backend-prover Phase 2
├── code/frontend/                # From frontend-prover
└── configs/                      # From infrastructure-prover
```

---

## Validation Process

### Step 1: Collect All Proofs

```python
def collect_proofs():
    """
    Collect all proof files from engineering artifacts
    
    Returns dict of proofs by category
    """
    
    proofs = {
        'architecture': collect_architecture_proofs(),
        'backend': collect_backend_proofs(),
        'frontend': collect_frontend_proofs(),
        'infrastructure': collect_infrastructure_proofs()
    }
    
    return proofs

def collect_architecture_proofs():
    """Collect from system-architect"""
    return {
        'adt_correctness': load_proof('architecture/adt-correctness/'),
        'functor_laws': load_proof('architecture/functor-laws/'),
        'composition': load_proof('architecture/composition-correctness/'),
        'state_machines': load_proof('architecture/state-machines/'),
        'curry_howard': load_proof('architecture/curry-howard-proofs/')
    }

def collect_backend_proofs():
    """Collect from backend-prover + standardization-layer"""
    return {
        'map_validation': load_json('backend/map-validation/validation-report.json'),
        'implementation': load_proof('backend/implementation-correctness/'),
        'standardization': load_json('backend/standardization/naturality-certificate.proof'),
        'runtime': load_proof('backend/runtime-verification/')
    }

def collect_frontend_proofs():
    """Collect from frontend-prover"""
    return {
        'type_correspondence': load_json('frontend/type-correspondence/openapi-to-typescript.proof')
    }

def collect_infrastructure_proofs():
    """Collect from infrastructure-prover"""
    return {
        'topology': load_json('infrastructure/topology/deployment-isomorphism.proof')
    }
```

---

### Step 2: Verify Version Consistency

```python
def verify_version_consistency(proofs, manifest):
    """
    Verify all proofs reference same specification version
    
    Critical: Prevents race conditions where different skills
    used different versions of the spec
    """
    
    errors = []
    
    # Get spec version from manifest
    spec_version = manifest['version']
    spec_hash = manifest['hash']
    
    # Check architecture proofs
    arch_version = proofs['architecture'].get('specification_version')
    if arch_version != spec_version:
        errors.append({
            "type": "version_mismatch",
            "skill": "system-architect",
            "expected": spec_version,
            "actual": arch_version
        })
    
    # Check backend proofs
    backend_version = proofs['backend']['map_validation'].get('specification_version')
    if backend_version != spec_version:
        errors.append({
            "type": "version_mismatch",
            "skill": "backend-prover",
            "expected": spec_version,
            "actual": backend_version
        })
    
    # Check frontend proofs
    frontend_version = proofs['frontend']['type_correspondence'].get('specification_version')
    if frontend_version != spec_version:
        errors.append({
            "type": "version_mismatch",
            "skill": "frontend-prover",
            "expected": spec_version,
            "actual": frontend_version
        })
    
    # Check infrastructure proofs
    infra_version = proofs['infrastructure']['topology'].get('specification_version')
    if infra_version != spec_version:
        errors.append({
            "type": "version_mismatch",
            "skill": "infrastructure-prover",
            "expected": spec_version,
            "actual": infra_version
        })
    
    return {
        "consistent": len(errors) == 0,
        "specification_version": spec_version,
        "specification_hash": spec_hash,
        "errors": errors
    }
```

---

### Step 3: Validate Proof Chain

```python
def validate_proof_chain(proofs):
    """
    Verify proof chain composes correctly:
    
    Requirements → Architecture (system-architect) ✓
        ↓
    Backend Maps (backend-prover Phase 1) ✓
        ↓
    Backend Code (backend-prover Phase 2) ✓
        ↓
    Standardization (standardization-layer) ✓
        ↓
    Frontend (frontend-prover) ✓
        ↓
    Infrastructure (infrastructure-prover) ✓
    """
    
    errors = []
    
    # 1. Architecture proofs valid
    if not architecture_proofs_valid(proofs['architecture']):
        errors.append({
            "type": "invalid_architecture_proof",
            "details": "Architecture proofs failed validation"
        })
    
    # 2. Backend maps validated
    if proofs['backend']['map_validation']['status'] != 'valid':
        errors.append({
            "type": "invalid_backend_maps",
            "details": "Backend maps not validated"
        })
    
    # 3. Backend code matches maps
    if not backend_code_matches_maps(proofs['backend']['implementation']):
        errors.append({
            "type": "code_map_mismatch",
            "details": "Backend code doesn't match verified maps"
        })
    
    # 4. Standardization preserves composition
    if not standardization_preserves_composition(proofs['backend']['standardization']):
        errors.append({
            "type": "standardization_broken",
            "details": "Standardization doesn't preserve composition laws"
        })
    
    # 5. Frontend types correspond to backend API
    if not proofs['frontend']['type_correspondence']['bijection']:
        errors.append({
            "type": "type_correspondence_failed",
            "details": "Frontend types don't match backend API"
        })
    
    # 6. Infrastructure topology matches architecture
    if not proofs['infrastructure']['topology']['isomorphism']:
        errors.append({
            "type": "topology_isomorphism_failed",
            "details": "Deployed topology doesn't match architecture"
        })
    
    return {
        "chain_valid": len(errors) == 0,
        "errors": errors
    }
```

---

### Step 4: Check for Gaps

```python
def check_for_gaps(proofs, artifacts):
    """
    Check for missing proofs or incomplete verification
    """
    
    gaps = []
    
    # Check all services in architecture have backend maps
    arch_services = extract_services_from_architecture(proofs['architecture'])
    backend_maps = list_backend_maps(artifacts['maps/backend'])
    
    for service in arch_services:
        if service not in backend_maps:
            gaps.append({
                "type": "missing_backend_map",
                "service": service,
                "fix": "Run backend-prover to generate map"
            })
    
    # Check all backend maps have implementations
    for map_file in backend_maps:
        service = extract_service_name(map_file)
        if not backend_implementation_exists(service, artifacts['code/backend']):
            gaps.append({
                "type": "missing_implementation",
                "service": service,
                "fix": "Run backend-prover Phase 2"
            })
    
    # Check all backend services have deployment configs
    backend_services = list_backend_services(artifacts['code/backend'])
    for service in backend_services:
        if not deployment_config_exists(service, artifacts['configs']):
            gaps.append({
                "type": "missing_deployment_config",
                "service": service,
                "fix": "Run infrastructure-prover"
            })
    
    # Check frontend consumes all public APIs
    public_apis = extract_public_apis(proofs['architecture'])
    frontend_types = list_frontend_types(artifacts['code/frontend'])
    
    for api in public_apis:
        if not frontend_type_exists(api, frontend_types):
            gaps.append({
                "type": "missing_frontend_type",
                "api": api,
                "fix": "Run frontend-prover"
            })
    
    return {
        "complete": len(gaps) == 0,
        "gaps": gaps
    }
```

---

### Step 5: Validate Composition End-to-End

```python
def validate_end_to_end_composition(proofs):
    """
    Verify composition laws hold across entire system
    """
    
    errors = []
    
    # Architecture composition valid
    if not proofs['architecture']['composition']['valid']:
        errors.append({
            "type": "architecture_composition_invalid",
            "details": "Architecture-level composition laws violated"
        })
    
    # Maps preserve architecture composition
    if not maps_preserve_architecture(proofs['backend']['map_validation']):
        errors.append({
            "type": "maps_dont_preserve_architecture",
            "details": "Backend maps don't preserve architecture composition"
        })
    
    # Code preserves map composition
    if not code_preserves_maps(proofs['backend']['implementation']):
        errors.append({
            "type": "code_doesnt_preserve_maps",
            "details": "Backend code doesn't preserve map composition"
        })
    
    # Standardization preserves composition (naturality)
    if not proofs['backend']['standardization']['composition_preserved']:
        errors.append({
            "type": "standardization_breaks_composition",
            "details": "Middleware breaks composition laws"
        })
    
    # Frontend types compose
    if not frontend_types_compose(proofs['frontend']['type_correspondence']):
        errors.append({
            "type": "frontend_types_dont_compose",
            "details": "Frontend type definitions don't compose"
        })
    
    # Infrastructure topology correct
    if not proofs['infrastructure']['topology']['isomorphism']:
        errors.append({
            "type": "topology_incorrect",
            "details": "Infrastructure doesn't match architecture"
        })
    
    return {
        "composition_valid": len(errors) == 0,
        "errors": errors
    }
```

---

## Generate Composed Proof

```python
def generate_composed_proof(validation_results, proofs, manifest):
    """
    Generate final composed proof certificate
    
    This certificate authorizes deployment
    """
    
    all_checks_passed = (
        validation_results['version_consistency']['consistent'] and
        validation_results['proof_chain']['chain_valid'] and
        validation_results['gaps']['complete'] and
        validation_results['composition']['composition_valid']
    )
    
    certificate = {
        "status": "valid" if all_checks_passed else "invalid",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        
        "specification": {
            "version": manifest['version'],
            "hash": manifest['hash']
        },
        
        "composition_chain": [
            "architecture → backend_maps",
            "backend_maps → backend_code",
            "backend_code → standardization",
            "backend_code → frontend",
            "backend_code → infrastructure"
        ],
        
        "verification_summary": {
            "version_consistency": validation_results['version_consistency']['consistent'],
            "proof_chain_valid": validation_results['proof_chain']['chain_valid'],
            "no_gaps": validation_results['gaps']['complete'],
            "composition_valid": validation_results['composition']['composition_valid']
        },
        
        "individual_proofs": {
            "architecture": {
                "adt_correct": True,
                "functors_valid": True,
                "composition_correct": True,
                "state_machines_complete": True
            },
            "backend": {
                "maps_validated": proofs['backend']['map_validation']['status'] == 'valid',
                "code_correct": True,
                "standardization_natural": proofs['backend']['standardization']['composition_preserved']
            },
            "frontend": {
                "type_correspondence": proofs['frontend']['type_correspondence']['bijection']
            },
            "infrastructure": {
                "topology_isomorphism": proofs['infrastructure']['topology']['isomorphism']
            }
        },
        
        "gaps_detected": validation_results['gaps']['gaps'],
        
        "deploy_authorized": all_checks_passed,
        
        "errors": (
            validation_results['version_consistency']['errors'] +
            validation_results['proof_chain']['errors'] +
            validation_results['composition']['errors']
        )
    }
    
    return certificate
```

---

## Output: System Proof Certificate

**Success case:**
```json
{
  "status": "valid",
  "timestamp": "2025-01-15T10:30:00Z",
  
  "specification": {
    "version": "v1.2.0",
    "hash": "sha256:abc123..."
  },
  
  "composition_chain": [
    "architecture → backend_maps",
    "backend_maps → backend_code",
    "backend_code → standardization",
    "backend_code → frontend",
    "backend_code → infrastructure"
  ],
  
  "verification_summary": {
    "version_consistency": true,
    "proof_chain_valid": true,
    "no_gaps": true,
    "composition_valid": true
  },
  
  "individual_proofs": {
    "architecture": {
      "adt_correct": true,
      "functors_valid": true,
      "composition_correct": true,
      "state_machines_complete": true
    },
    "backend": {
      "maps_validated": true,
      "code_correct": true,
      "standardization_natural": true
    },
    "frontend": {
      "type_correspondence": true
    },
    "infrastructure": {
      "topology_isomorphism": true
    }
  },
  
  "gaps_detected": [],
  
  "deploy_authorized": true,
  
  "errors": []
}
```

**Failure case:**
```json
{
  "status": "invalid",
  "timestamp": "2025-01-15T10:30:00Z",
  
  "verification_summary": {
    "version_consistency": false,
    "proof_chain_valid": true,
    "no_gaps": false,
    "composition_valid": true
  },
  
  "gaps_detected": [
    {
      "type": "missing_deployment_config",
      "service": "BillingService",
      "fix": "Run infrastructure-prover"
    }
  ],
  
  "deploy_authorized": false,
  
  "errors": [
    {
      "type": "version_mismatch",
      "skill": "frontend-prover",
      "expected": "v1.2.0",
      "actual": "v1.1.0"
    }
  ]
}
```

---

## Output Location

```
artifacts/engineering/proofs/composed/
├── system-proof.certificate
├── composition-graph.dot
└── verification-report.md
```

---

## Integration with Build Pipeline

**Build pipeline final gate:**

```bash
# build-pipeline/13-compose-proofs.sh ⭐ DEPLOYMENT GATE

echo "Validating system-wide proof chain..."

# Run proof-composer
proof-composer validate-all

# Check certificate
status=$(jq -r '.status' artifacts/engineering/proofs/composed/system-proof.certificate)
deploy_authorized=$(jq -r '.deploy_authorized' artifacts/engineering/proofs/composed/system-proof.certificate)

if [ "$status" != "valid" ] || [ "$deploy_authorized" != "true" ]; then
    echo "❌ DEPLOYMENT BLOCKED: Proof chain invalid"
    echo ""
    echo "Errors:"
    jq '.errors' artifacts/engineering/proofs/composed/system-proof.certificate
    echo ""
    echo "Gaps:"
    jq '.gaps_detected' artifacts/engineering/proofs/composed/system-proof.certificate
    exit 1
fi

echo "✅ Proof chain valid - deployment authorized"

# build-pipeline/14-deploy.sh can now proceed
```

---

## Success Criteria

✓ All proofs collected
✓ Version consistency verified
✓ Proof chain validated
✓ No gaps detected
✓ Composition laws hold end-to-end
✓ System proof certificate generated
✓ **Deployment authorized ✓**

---

## Error Handling

**Version mismatch:**
```
ERROR: Version inconsistency detected
Frontend-prover used v1.1.0, but current spec is v1.2.0
Action: Re-run frontend-prover with correct version
```

**Broken proof chain:**
```
ERROR: Proof chain broken
Backend maps not validated (map-validation/validation-report.json status != 'valid')
Action: Re-run backend-prover Phase 1 (map validation)
```

**Gap detected:**
```
ERROR: Missing deployment config
Service: BillingService
Has backend implementation but no deployment config
Action: Run infrastructure-prover
```

**Composition broken:**
```
ERROR: Composition doesn't hold end-to-end
Standardization broke composition laws (naturality failed)
Action: Re-run standardization-layer with correct naturality proof
```

---

## Critical Reminders

1. **This is the final gate** - Nothing deploys without valid certificate
2. **Version consistency mandatory** - All skills must use same spec version
3. **No gaps allowed** - Every service needs full proof chain
4. **Composition must hold** - Laws verified at every layer
5. **Certificate authorizes deployment** - Build pipeline checks this

---

## When You (proof-composer) Finish

1. **Log results** in thread:
   ```
   threads/engineering/{requirement}/5-actions/action-5-proof-composition.md
   
   Status: Complete
   Proof status: valid
   Deploy authorized: true
   Certificate: artifacts/engineering/proofs/composed/system-proof.certificate
   Specification: v1.2.0 (hash: abc123...)
   All proofs verified: ✓
   No gaps detected: ✓
   Composition valid: ✓
   ```

2. **Update engineering thread Stage 5**:
   - Action 5 complete ✓
   - ALL engineering actions complete ✓
   - Ready for Stage 6 (Learning)

3. **Engineering thread → Business thread**:
   - Report technical success
   - Provide deployment certificate
   - Document any learnings

---

## Proof Composition Visualization

```
System-Architect
      ↓
  [Architecture Proofs: ADT, Functors, Composition, State Machines] ✓
      ↓
Backend-Prover Phase 1
      ↓
  [Backend Maps Validated: Composition laws verified] ✓
      ↓
Backend-Prover Phase 2
      ↓
  [Backend Code Matches Maps: Generated from verified maps] ✓
      ↓
Standardization-Layer
      ↓
  [Naturality Proven: Middleware preserves composition] ✓
      ↓
Frontend-Prover
      ↓
  [Type Correspondence: Frontend ≅ Backend API] ✓
      ↓
Infrastructure-Prover
      ↓
  [Topology Isomorphism: Deployed ≅ Architecture] ✓
      ↓
Proof-Composer (YOU)
      ↓
  [System Proof: All proofs compose ✓]
      ↓
DEPLOYMENT AUTHORIZED ✅
```

---

**You are the final gatekeeper. Verify the entire proof chain. Authorize deployment only when mathematically verified.**
