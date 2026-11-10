# Release artifacts

The macOS universal executable is published as a GitHub Release asset. To rebuild from source on macOS 12 or later with Swift 5.9+:

```sh
swift build -c release
```

The checked-in release asset was built for both Apple Silicon (arm64) and Intel (x86_64) macOS.
