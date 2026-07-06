# Diagram Guide

Examples of each Mermaid diagram type for requirements.

## Use Case
```mermaid
flowchart LR
    Actor([User/Role])
    subgraph System
        Action1[Action 1]
        Action2[Action 2]
    end
    Actor --> Action1
    Actor --> Action2
```

## Flowchart
```mermaid
flowchart TD
    Start([Start]) --> Decision{Condition?}
    Decision -- Yes --> ActionA[Action A]
    Decision -- No --> ActionB[Action B]
    ActionA --> End([End])
    ActionB --> End
```

## Sequence
```mermaid
sequenceDiagram
    actor User
    participant UI as Frontend
    participant API as Backend
    User->>UI: Action
    UI->>API: Request
    API-->>UI: Response
    UI-->>User: Result
```

## Conceptual ER
```mermaid
erDiagram
    ENTITY_A ||--o{ ENTITY_B : has
    ENTITY_B }|--|| ENTITY_C : belongs_to
```

## State Machine
```mermaid
stateDiagram-v2
    [*] --> Initial
    Initial --> Processing : event
    Processing --> Completed : success
    Processing --> Failed : error
    Failed --> Processing : retry
```

## Rules
- Use Case: ALWAYS include. Defines scope visually.
- Flowchart: if REQs have IF/ELSE logic, validation, or multi-step calculation.
- Sequence: if ≥2 components interact (frontend→backend, service→service).
- Conceptual ER: if data is persisted (DB, files, state). NO column details — that's design.
- State Machine: if entity has lifecycle states (orders, tickets, processes).
