import PackageDescription

let package = Package(
    name: "SwawshBuckle",
    dependencies: [
        .Package(url: "https://github.com/scottORLY/Swawsh.git", majorVersion:0, minor: 1),
        .Package(url: "https://github.com/scottORLY/CCurl.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/scottORLY/Clibxml2.git", majorVersion: 0, minor: 1)
    ]
)
