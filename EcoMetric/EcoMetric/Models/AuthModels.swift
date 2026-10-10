import Foundation

enum AccountRole: String, Codable, CaseIterable, Identifiable {
    case owner
    case admin
    case member

    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Chủ sở hữu"
        case .admin: return "Quản trị viên"
        case .member: return "Nhân viên"
        }
    }

    var description: String {
        switch self {
        case .owner:
            return "Toàn quyền và có thể cấp hoặc thu hồi quyền admin."
        case .admin:
            return "Quản lý nhân viên và dữ liệu doanh nghiệp."
        case .member:
            return "Sử dụng các tính năng được doanh nghiệp cấp."
        }
    }
}

struct OrganizationAccount: Codable, Identifiable {
    let id: UUID
    let name: String
    let planCode: String
    let subscriptionStatus: String
    let seatLimit: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case planCode = "plan_code"
        case subscriptionStatus = "subscription_status"
        case seatLimit = "seat_limit"
    }
}

struct AppUser: Codable, Identifiable {
    let id: UUID
    let organizationID: UUID
    let email: String
    let fullName: String
    let role: AccountRole
    let isActive: Bool
    let mustChangePassword: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case organizationID = "organization_id"
        case fullName = "full_name"
        case isActive = "is_active"
        case mustChangePassword = "must_change_password"
        case createdAt = "created_at"
    }
}

struct AuthenticationResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: AppUser
    let organization: OrganizationAccount

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user, organization
    }
}

struct AccountContextResponse: Codable {
    let user: AppUser
    let organization: OrganizationAccount
}

struct CompanyRegistrationRequest: Encodable {
    let companyName: String
    let ownerName: String
    let email: String
    let password: String
    let otp: String

    enum CodingKeys: String, CodingKey {
        case companyName = "company_name"
        case ownerName = "owner_name"
        case email, password, otp
    }
}

struct RegistrationOTPRequest: Encodable {
    let email: String
}

struct RegistrationOTPResponse: Decodable {
    let message: String
    let expiresInSeconds: Int
    let resendAfterSeconds: Int
    let developmentCode: String?

    enum CodingKeys: String, CodingKey {
        case message
        case expiresInSeconds = "expires_in_seconds"
        case resendAfterSeconds = "resend_after_seconds"
        case developmentCode = "development_code"
    }
}

struct LoginAccountRequest: Encodable {
    let email: String
    let password: String
}

struct MemberCreateRequest: Encodable {
    let email: String
    let fullName: String
    let password: String
    let role: AccountRole

    enum CodingKeys: String, CodingKey {
        case email, password, role
        case fullName = "full_name"
    }
}

struct MemberUpdateRequest: Encodable {
    let role: AccountRole?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case role
        case isActive = "is_active"
    }
}

struct PasswordChangeRequest: Encodable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

struct AccountMessageResponse: Decodable {
    let message: String
}
