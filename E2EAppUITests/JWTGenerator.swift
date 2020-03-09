import SwiftyJWT
import SwiftyCrypto

struct Acl: Codable {
    let paths: Paths

    struct Paths: Codable {
        let users: EmptyObj
        let conversations: EmptyObj
        let sessions: EmptyObj
        let devices: EmptyObj
        let image: EmptyObj
        let media: EmptyObj
        let applications: EmptyObj
        let push: EmptyObj
        let knocking: EmptyObj
        let calls: EmptyObj
        let legs: EmptyObj

        struct EmptyObj: Codable { }

        enum CodingKeys: String, CodingKey {
            case users = "/*/users/**"
            case conversations = "/*/conversations/**"
            case sessions = "/*/sessions/**"
            case devices = "/*/devices/**"
            case image = "/*/image/**"
            case media = "/*/media/**"
            case applications = "/*/applications/**"
            case push = "/*/push/**"
            case knocking = "/*/knocking/**"
            case calls = "/*/calls/**"
            case legs = "/*/legs/**"
        }
    }
}

final class JWTGenerator: NSObject {

    @objc static func generateToken(privateKey: String, applicationId: String, username: String?) -> String {
        var payload = JWTPayload()
        let emptyObject = Acl.Paths.EmptyObj()
        let aclPaths = Acl.Paths(
                users: emptyObject,
                conversations: emptyObject,
                sessions: emptyObject,
                devices: emptyObject,
                image: emptyObject,
                media: emptyObject,
                applications: emptyObject,
                push: emptyObject,
                knocking: emptyObject,
                calls: emptyObject,
                legs: emptyObject
        )
        let acl = Acl(paths: aclPaths)

        let now = Int(Date().timeIntervalSince1970)
        let thirtyMinutes = 30 * 60;
        let exp = Int(Date(timeIntervalSinceNow:TimeInterval(thirtyMinutes)).timeIntervalSince1970)

        payload.expiration = exp
        payload.issueAt = now
        payload.notBefore = now
        payload.jwtId = UUID.init().uuidString.lowercased()
        payload.issuer = "Max NPE app"
        payload.subject = username
        payload.customFields = ["acl": EncodableValue(value: acl), "application_id": EncodableValue(value: applicationId)]

        let privateKey = try! RSAKey(base64String: privateKey, keyType: .PRIVATE)
        let alg = JWTAlgorithm.rs256(privateKey)
        let jwtWithKeyId = try? JWT(payload: payload, algorithm: alg)

        return jwtWithKeyId!.rawString
    }

}
