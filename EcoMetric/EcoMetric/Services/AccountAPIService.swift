import Foundation

struct AccountAPIService {
    private let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        let configuredURL = ProcessInfo.processInfo.environment[
            "ECOMETRIC_API_BASE_URL"
        ].flatMap(URL.init(string:))
        self.baseURL = baseURL
            ?? configuredURL
            ?? URL(string: "http://127.0.0.1:8000")!
        self.session = session
    }

    func register(_ request: CompanyRegistrationRequest) async throws -> AuthenticationResponse {
        try await send(
            path: "v1/auth/register-company",
            method: "POST",
            payload: request,
            token: nil,
            responseType: AuthenticationResponse.self
        )
    }

    func requestRegistrationOTP(email: String) async throws -> RegistrationOTPResponse {
        try await send(
            path: "v1/auth/registration-otp",
            method: "POST",
            payload: RegistrationOTPRequest(email: email),
            token: nil,
            responseType: RegistrationOTPResponse.self
        )
    }

    func login(_ request: LoginAccountRequest) async throws -> AuthenticationResponse {
        try await send(
            path: "v1/auth/login",
            method: "POST",
            payload: request,
            token: nil,
            responseType: AuthenticationResponse.self
        )
    }

    func context(token: String) async throws -> AccountContextResponse {
        try await send(
            path: "v1/auth/me",
            method: "GET",
            body: nil,
            token: token,
            responseType: AccountContextResponse.self
        )
    }

    func logout(token: String) async throws {
        let _: EmptyResponse = try await send(
            path: "v1/auth/logout",
            method: "POST",
            body: nil,
            token: token,
            responseType: EmptyResponse.self
        )
    }

    func changePassword(
        currentPassword: String,
        newPassword: String,
        token: String
    ) async throws -> AccountMessageResponse {
        try await send(
            path: "v1/auth/change-password",
            method: "POST",
            payload: PasswordChangeRequest(
                currentPassword: currentPassword,
                newPassword: newPassword
            ),
            token: token,
            responseType: AccountMessageResponse.self
        )
    }

    func members(token: String) async throws -> [AppUser] {
        try await send(
            path: "v1/organization/members",
            method: "GET",
            body: nil,
            token: token,
            responseType: [AppUser].self
        )
    }

    func createMember(
        _ request: MemberCreateRequest,
        token: String
    ) async throws -> AppUser {
        try await send(
            path: "v1/organization/members",
            method: "POST",
            payload: request,
            token: token,
            responseType: AppUser.self
        )
    }

    func updateMember(
        id: UUID,
        request: MemberUpdateRequest,
        token: String
    ) async throws -> AppUser {
        try await send(
            path: "v1/organization/members/\(id.uuidString)",
            method: "PATCH",
            payload: request,
            token: token,
            responseType: AppUser.self
        )
    }

    private func send<Payload: Encodable, Response: Decodable>(
        path: String,
        method: String,
        payload: Payload,
        token: String?,
        responseType: Response.Type
    ) async throws -> Response {
        try await send(
            path: path,
            method: method,
            body: try encoder.encode(payload),
            token: token,
            responseType: responseType
        )
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        body: Data?,
        token: String?,
        responseType: Response.Type
    ) async throws -> Response {
        let url = path.split(separator: "/").reduce(baseURL) {
            $0.appendingPathComponent(String($1))
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIRecommendationAPIError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            let message = try? decoder.decode(APIErrorResponse.self, from: data).detail
            throw AIRecommendationAPIError.server(
                statusCode: http.statusCode,
                message: message
            )
        }
        if Response.self == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! Response
        }
        return try decoder.decode(Response.self, from: data)
    }
}

private struct EmptyResponse: Codable {}
