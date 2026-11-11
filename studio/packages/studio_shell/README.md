# studio_shell

Desktop shell of Studio. It is the only package with a platform runner and the
only one that imports `devtools_app` (see section 6.1 of the coding standard).

The inherited DevTools code loads its assets and fonts as if it were the root
application. The `inherited_assets` library resolves those requests inside the
shell bundle (ADR-0015).

Build and run with the Flutter version pinned in `studio/flutter-version.txt`:

```sh
flutter run -d linux
```
