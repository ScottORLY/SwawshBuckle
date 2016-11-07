import Foundation
import CCurl

class SwawshCurl {
    
    var delegate = CurlDelegate()
    var headersList: UnsafeMutablePointer<curl_slist>?
    let handle: UnsafeMutableRawPointer
    var url: String
    var method: String
    
    init(url: String, method: String, headers: [String]) {
        curl_global_init(Int(CURL_GLOBAL_SSL))
        self.handle = curl_easy_init()
        curlHelperSetOptString(handle, CURLOPT_URL, url.cString(using: .utf8))
        self.url = url
        self.method = method
        setMethod(method: method)
        addHeaders(headers: headers)
        setOpts()
    }
    
    public func setMethod(method: String) {
        if method == "PUT" {
            curlHelperSetOptBool(handle, CURLOPT_PUT, CURL_TRUE)
        }
        if method == "GET" {
            curlHelperSetOptBool(handle, CURLOPT_HTTPGET, CURL_TRUE)
        }
    }
    
    func setVerbose(verbose: Bool) {
        if verbose {
            curlHelperSetOptInt(handle, CURLOPT_VERBOSE, 1)
        } else {
            curlHelperSetOptInt(handle, CURLOPT_VERBOSE, 0)
        }
    }
    
    func setOpts() {
        curlHelperSetOptInt(handle, CURLOPT_NOPROGRESS, 0)
        curlHelperSetOptString(handle, CURLOPT_ACCEPT_ENCODING, "")
        curlHelperSetOptBool(handle, CURLOPT_FOLLOWLOCATION, CURL_TRUE)
        curlHelperSetOptInt(handle, CURLOPT_REDIR_PROTOCOLS, Int(CURLPROTO_HTTP) | Int(CURLPROTO_HTTPS))
    }
    
    public func addHeaders(headers: [String]) {
        _ = headers.map {
            addHeader(header: $0)
        }
        curlHelperSetOptList(handle, CURLOPT_HTTPHEADER, headersList)
    }
    
    public func addHeader(header: String) {
        let cstring = header.cString(using: .utf8)
        let headerPointer = UnsafePointer(cstring)
        headersList = curl_slist_append(headersList, headerPointer)
    }
    
    public func invoke() -> CURLcode {
        var responseCode: CURLcode = CURLE_FAILED_INIT
        
        withUnsafeMutablePointer(to: &delegate) {
            pointer in
            
            curlHelperSetOptReadFunc(handle, pointer) { (buffer: UnsafeMutablePointer<Int8>?, size: Int, nitems: Int, privateData: UnsafeMutableRawPointer?) -> Int in
                let p = privateData?.assumingMemoryBound(to: CurlDelegate.self).pointee
                let b = UnsafeMutableBufferPointer(start: buffer, count: size*nitems)
                return (p?.curlRead(b, size: size*nitems))!
            }
            
            curlHelperSetOptWriteFunc(handle, pointer) { (buffer: UnsafeMutablePointer<Int8>?, size: Int, nMemb: Int, privateData: UnsafeMutableRawPointer?) -> Int in
                let p = privateData?.assumingMemoryBound(to: CurlDelegate.self).pointee
                return (p?.curlWrite(buffer!, size: size*nMemb))!
            }
            curlHelperSetOptHeaderFunc(handle, pointer) { (buffer: UnsafeMutablePointer<Int8>?, size: Int, nMemb: Int, privateData: UnsafeMutableRawPointer?) -> Int in
                let p = privateData?.assumingMemoryBound(to: CurlDelegate.self).pointee
                return (p?.curlWriteHeader(buffer!, size: size*nMemb))!
            }
            
            responseCode = curl_easy_perform(handle)
        }
        return responseCode
    }
    
    public func writeFile(fileName: String) {
        let currentDirectory = FileManager.default.currentDirectoryPath
        let fileUrl = URL(fileURLWithPath: currentDirectory + "/response.txt")
        try! delegate.responseBuffer.write(to: fileUrl)

    }
}

class CurlDelegate {
    
    var writeBuffer = Data()
    
    var responseBuffer = Data()
    var headerBuffer = Data()
    
    func curlWrite(_ buffer: UnsafeMutablePointer<Int8>, size: Int) -> Int {
        responseBuffer.append(UnsafeRawPointer(buffer).assumingMemoryBound(to: UInt8.self), count: size)
        return size
    }
    
    func curlWriteHeader(_ buffer: UnsafeMutablePointer<Int8>, size: Int) -> Int {
        headerBuffer.append(UnsafeRawPointer(buffer).assumingMemoryBound(to: UInt8.self), count: size)
        return size
    }
    
    func curlRead(_ buffer: UnsafeMutableBufferPointer<Int8>, size: Int) -> Int {
        print("READING")
        return writeBuffer.copyBytes(to: buffer)
    }
}
