# Kebash

A two-player stone game for Flutter, in Arabic and English. The rules are in [spec.md](spec.md).

- `packages/kebash_engine`: rules engine and AI in pure Dart.
- `lib`: the Flutter app, which animates the events the engine produces.

## Run

```sh
flutter run
```

## Test

```sh
flutter test
(cd packages/kebash_engine && dart test)
```

`dart run tool/bench.dart` in the engine package plays the AI levels against each other and reports win rates and thinking time.
