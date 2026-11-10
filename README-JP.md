# quickdraw-jpeg

バージョン: **0.1.1**（試験公開版）

2026年に Kimihiko Mizutani（Kyoto University）が作成しました。

QuickDraw Picture（`.pict` / `.pic`）をJPEG画像へ変換するmacOS向けコマンドラインツールです。

QuickDrawViewer 1.8のQuickDrawパーサーとCore Graphicsレンダラーを利用し、変換結果をJPEGとして保存します。

## ビルド

macOSとSwift 5.9以降が必要です。

```sh
swift build -c release
```

ビルド後の実行ファイルは次の場所に作られます。

```text
.build/release/quickdraw-jpeg
```

## 使い方

入力ファイルだけを指定すると、入力ファイルと同じ場所に`.jpg`を作成します。

```sh
.build/release/quickdraw-jpeg input.pict
.build/release/quickdraw-jpeg --version
```

出力先を指定することもできます。

```sh
.build/release/quickdraw-jpeg input.pict output.jpg
```

JPEG品質と描画倍率はオプションで指定できます。

```sh
.build/release/quickdraw-jpeg --quality 0.95 --scale 2 input.pict output.jpg
.build/release/quickdraw-jpeg --recursive pictures --output-directory converted
```

- `--quality` / `-q`: JPEG品質。`0.0`〜`1.0`。既定値は`0.92`。
- `--scale`: 描画倍率。既定値は`1`。

透明部分は白色の背景として出力されます。

再帰変換では、入力フォルダ以下にある`.pict`と`.pic`をすべて変換します。拡張子のないファイルもPICTのバイナリヘッダーを解析し、PICTと判定された場合は変換します。入力フォルダからの相対ディレクトリ構造は出力先でも維持されます。

```text
pictures/sub/example.pict → converted/sub/example.jpg
```

## 対応環境

現在の描画処理はmacOSのCore Graphics、Core Text、AppKitに依存しているため、macOSを対象としています。

QuickDrawの解析部分はLinuxでも利用できる可能性がありますが、Linux対応には描画バックエンドをCairoやSkiaなどへ置き換える作業が必要です。

## ライセンスと著作権表示

このプロジェクトには、Matthias Wiesmann氏によるQuickDrawViewerのコードを元にした部分が含まれています。

QuickDrawViewer由来の部分はApache License 2.0でライセンスされています。詳細は[LICENSE](LICENSE)を参照してください。

配布時には、`LICENSE`ファイルを削除せず同梱してください。
