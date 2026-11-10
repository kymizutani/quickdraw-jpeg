# quickdraw-jpeg

[日本語の説明はこちら](README-JP.md)。

Version: **0.1.1** (experimental)

Created in 2026 by Kimihiko Mizutani (Kyoto University).

`quickdraw-jpeg` is a macOS command-line tool that converts QuickDraw Pictures (`.pict` / `.pic`) into JPEG images.

It uses the QuickDraw parser and Core Graphics renderer from QuickDrawViewer 1.8, with a command-line JPEG output layer.

## Build

Requires macOS and Swift 5.9 or later.

```sh
swift build -c release
```

The executable is created at `.build/release/quickdraw-jpeg`.

## Usage

```sh
.build/release/quickdraw-jpeg input.pict
.build/release/quickdraw-jpeg --version
.build/release/quickdraw-jpeg input.pict output.jpg
.build/release/quickdraw-jpeg --quality 0.95 --scale 2 input.pict output.jpg
.build/release/quickdraw-jpeg --recursive pictures --output-directory converted
```

If no output path is specified, a `.jpg` file is created next to the input file.

- `--quality` / `-q`: JPEG quality from `0.0` to `1.0`. Default: `0.92`.
- `--scale`: rendering scale. Default: `1`.

Transparent areas are rendered against a white background.

For recursive conversion, all `.pict` and `.pic` files below the input directory are converted. The directory structure is preserved below the output directory:

```text
pictures/sub/example.pict -> converted/sub/example.jpg
```

## Platform support

The current renderer depends on macOS Core Graphics, Core Text, and AppKit, so this release targets macOS.

Linux support would require replacing the rendering backend with Cairo, Skia, or a similar library.

## License and attribution

This project includes portions derived from QuickDrawViewer by Matthias Wiesmann.
Those portions are licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

When redistributing this project, include the `LICENSE` file and retain the applicable copyright and attribution notices.

## 日本語

`quickdraw-jpeg`は、クラシックMacのQuickDraw PICTファイル（`.pict` / `.pic`）をJPEG画像に変換するmacOS向けコマンドラインツールです。JPEG品質や描画倍率を指定でき、フォルダ内のファイルをまとめて再帰変換することもできます。

macOS 12以降とSwift 5.9以降に対応しています。ビルド方法や使い方の詳細は[日本語README](README-JP.md)をご覧ください。
