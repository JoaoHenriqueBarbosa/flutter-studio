# Changelog

## 0.1.0

- Opens a Flutter project and locates its SDK (FR-PRJ-001 to FR-PRJ-003).
- `DocumentStore`, which applies workspace edits with atomic writes.
- Clients of the analysis server, of the debug adapter and of the Dart
  Tooling Daemon, and the supervisor that keeps the tools running.
- `ProjectSession`, which ties the tools, the documents and the run of the
  app together.
