# studio_tool

Development tool of Studio. It provides the `st` command and stays out of the
delivered product (see section 6.1 of the coding standard).

`st verify` runs the quality gate of section 9.1 of the coding standard. A step
that cannot run, because its tool is not installed or because the step is not
built yet, rejects the change the same way a failed step does.

Run it from the `studio/` directory:

```sh
dart run studio_tool:st verify
```

`st generate` writes the Dart code of `studio_protocol` from
`studio.openrpc.json` (ADR-0013). With `--check` it writes nothing and fails
when a generated file is stale, which is step QG-09 of the gate.

```sh
dart run studio_tool:st generate
```

`st trace` prints which test files verify each requirement of the SRS, from the
`// Verifies:` comments. With `--check` it fails when a test cites an
identifier that no document defines, or when a requirement of the increment in
`current-increment.txt` has no test, which is step QG-12 of the gate.
