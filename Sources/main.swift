import Foundation
import CCurl
import Cryptor
import Swawsh
import Clibxml

func getIAMCredentialsFromFile() -> (String?, String?) {
    let fileManager = FileManager.default.currentDirectoryPath + "/credentials.conf"
    if let fileData = try? Data(contentsOf: URL(string: fileManager)!),
        let jsonCredentials = try? JSONSerialization.jsonObject(with: fileData, options: .allowFragments) as? [String: String] {
        return (jsonCredentials?["accessKey"], jsonCredentials?["secret"])
    }
    return (nil, nil)
}

_ = CommandLine.arguments.map {
    if $0 == "--help" {
        let helpText = "Usage: SwawshBuckle [method] [service] [bucket] [options]"
        print(helpText)
    }
}

let swawsh = SwawshCredential.sharedInstance

let credentials: (accessKey: String?, secret: String?) = (
    ProcessInfo.processInfo.environment["SBACCESSKEY"],
    ProcessInfo.processInfo.environment["SBSECRET"]
)

//let fileUrl = URL(fileURLWithPath:"/Users/pivotal/Downloads/testImage.jpeg")
//let imageData = try! Data(contentsOf: fileUrl)

//let sha256 = Digest(using: .sha256)
//let digest = sha256.update(data: imageData)?.final()
//let digestHexString = CryptoUtils.hexString(from: digest!)

let authorization = swawsh.generateCredential(
    method: .GET,
    path: "/",
    endPoint: "ec2.amazonaws.com",
    queryParameters: "Action=DescribeRegions&Version=2013-10-15",
    payloadDigest: SwawshCredential.emptyStringHash,
    region: "us-east-1",
    service: "ec2",
    accessKeyId: credentials.accessKey!,
    secretKey: credentials.secret!
)

let urlString = "http://ec2.amazonaws.com/?Action=DescribeRegions&Version=2013-10-15"

let headers = [
    "x-amz-content-sha256: \(SwawshCredential.emptyStringHash)",
    "Authorization: \(authorization!)",
    "x-amz-date: \(swawsh.getDate())",
    "Accept-Encoding: gzip, deflate",
]

let swawshCurl = SwawshCurl(url: urlString, method: "GET", headers: headers)
swawshCurl.setVerbose(verbose: true)
let responseCode = swawshCurl.invoke()

let responseString = String(data: swawshCurl.delegate.responseBuffer, encoding: .utf8)
//print("HEADER \(String(data: swawshCurl.delegate.headerBuffer, encoding: .utf8))")
//print("RESPONSE: \(responseString))")


if let cur = responseString?.cString(using: .utf8) {
    let encoding = String.Encoding.utf8.rawValue
    let cfenc : CFStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
    let cfencstr = CFStringConvertEncodingToIANACharSetName(cfenc)
    let docPtr = xmlReadDoc(UnsafeRawPointer(cur).assumingMemoryBound(to: xmlChar.self), "", (cfencstr as? String) ?? "", 0)
    let rootNode = xmlDocGetRootElement(docPtr)
    let firstChildNode = xmlFirstElementChild(rootNode)
    let responseInfoNode = xmlNextElementSibling(firstChildNode)
    if let responseContent = xmlNodeGetContent(responseInfoNode) {
//        let name = String(validatingUTF8: UnsafeRawPointer((responseInfoNode?.pointee.parent.pointee.content)!).assumingMemoryBound(to: CChar.self))
        let content = String(validatingUTF8: UnsafeRawPointer(responseContent).assumingMemoryBound(to: CChar.self))
        print("\(content!)")
        print(responseString)
    }
}
