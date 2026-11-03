# Universal File & Code Organization Rules

Universal architectural rules and principles governing codebase organization, module boundaries, separation of concerns, and file hygiene. Applicable to any project, framework, or tech stack.

---

## 1. Single Responsibility & Dedicated File Principle

- **One Concern per File**: Every class, module, component, view, dialog, service, and data contract must reside in its own dedicated, standalone file. Never combine multiple unrelated entities into a single file.
- **No Monolithic / Catch-All Files**: Avoid large files that attempt to handle presentation, business logic, state management, and persistence all in one place. Once a file exceeds its primary role, decompose it immediately.
- **Dedicated Interactive Units**: Every popup, dialog, modal, drawer, or standalone interactive sheet must exist as an independent file, never defined inline inside a parent view.
- **Dedicated Presentation Atoms**: Every reusable visual element, card, form input, or custom layout unit must be isolated in its own file to maximize reusability and maintainability.
- **No Shared Component Dumping**: Never maintain a single massive file that dumps dozens of unrelated components together. Each component must be independently importable.

---

## 2. Separation of Concerns & Boundary Isolation

- **Data Definition Layer**:
  - Focuses strictly on data contracts, type schemas, immutability, and serialization / deserialization.
  - Must remain completely agnostic of UI rendering, external APIs, and persistence mechanisms.

- **Business Logic & Service Layer**:
  - Dedicated exclusively to external interactions, network requests, data stores, platform APIs, caching, and domain logic.
  - Must remain strictly independent of the presentation layer. It must never reference UI contexts, render trees, or trigger visual dialogs directly.
  - Must communicate outcomes using pure return values, events, streams, or typed errors.

- **Presentation & Screen Layer**:
  - Responsible strictly for visual composition, layout hierarchy, and listening to user interactions.
  - Must delegate all complex business computations, network operations, and persistence tasks to the underlying logic layer.
  - Must not embed hundreds of lines of input forms or dialog definitions.

- **Interactive Overlay Layer (Modals / Dialogs)**:
  - Focuses solely on collecting user input, executing local validation, and passing data back to the calling interface.
  - Must not implement persistent business logic or direct infrastructure-level operations.

- **Reusable Component Layer**:
  - Pure presentation units driven strictly by their input properties, props, or constructor parameters.
  - Must avoid hardcoded side-effects or direct global state mutation.

---

## 3. Dependency Management & Architecture Integrity

- **Unidirectional Dependency Flow**: Dependencies must flow strictly in one direction:
  Presentation Layer -> Logic / Service Layer -> Data / Core Layer.
  Lower-level domain and data layers must never import or depend on presentation layers.
- **Zero Circular Dependencies**: Modules and files must never depend on each other cyclically. If two entities require each other, extract their shared contract into an independent file.
- **Domain-Driven Cohesion**: Group related files by their feature or domain responsibility so that all logic, presentation, and data contracts for a specific feature are cleanly modularized.
- **Dead Code Hygiene**: When a component or module is split or replaced, immediately eliminate unused files, orphan imports, and redundant implementations.

---

## 4. Consistent Naming Conventions

- **Clear, Intention-Revealing Names**: File and module names must clearly describe their single responsibility without ambiguity.
- **Standardized Casing**: Consistently apply the framework's accepted naming standard across the entire project (e.g., lowercase with delimiters for file paths, matching casing conventions for exported classes/types).
- **Explicit Role Identifiers**: Suffix or prefix files according to their architectural layer so their purpose is immediately identifiable without opening the file (e.g., separate identifiers for views, components, modals, services, and models).
