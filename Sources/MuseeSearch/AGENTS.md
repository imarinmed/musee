# MuseeSearch

**Target**: Faceted search engine with persistence for museum collections.

## STRUCTURE

| File | Purpose | Lines |
|------|---------|-------|
| `Collection.swift` | Collection type | ~50 |
| `FacetedSearch.swift` | Core search engine | **14,024** |
| `PersistenceService.swift` | Persistence layer | ~200 |
| `PersistentModels.swift` | Persisted model types | ~150 |
| `SmartCollection.swift` | Smart collection type | ~70 |

## WHERE TO LOOK

| Task | File | Notes |
|------|------|-------|
| Core search logic | `FacetedSearch.swift` | **Complexity hotspot** |
| Persistence | `PersistenceService.swift` | Disk I/O |

## CONVENTIONS

- Heavy use of filters and predicates
- Search criteria composition
- Persistent storage integration

## ANTI-PATTERNS (THIS MODULE)

- **Do NOT modify FacetedSearch.swift without understanding persistence layer**
- Do NOT add new filters without tests
- Do NOT bypass PersistenceService for disk operations
