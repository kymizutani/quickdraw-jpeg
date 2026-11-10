// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickDrawJPEG",
    platforms: [.macOS(.v12)],
    products: [.executable(name: "quickdraw-jpeg", targets: ["QuickDrawJPEG"])],
    targets: [
        .executableTarget(
            name: "QuickDrawJPEG",
            path: "Sources/QuickDrawJPEG"
        )
    ]
)
