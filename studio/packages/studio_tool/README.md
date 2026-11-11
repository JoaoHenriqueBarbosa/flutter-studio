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
