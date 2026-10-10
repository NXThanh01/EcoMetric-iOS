import Combine
import Foundation

@MainActor
final class AccountSession: ObservableObject {
    @Published private(set) var user: AppUser?
    @Published private(set) var organization: OrganizationAccount?
    @Published private(set) var token: String?
    @Published var members: [AppUser] = []
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    private let service: AccountAPIService

    init(service: AccountAPIService? = nil) {
        self.service = service ?? AccountAPIService()
        self.token = AuthTokenStore.load()
    }

    var isAuthenticated: Bool { user != nil && token != nil }
    var canManageMembers: Bool { user?.role == .owner || user?.role == .admin }

    func restore() async {
        guard let token else { return }
        do {
            let context = try await service.context(token: token)
            user = context.user
            organization = context.organization
        } catch {
            clearLocalSession()
        }
    }

    func login(email: String, password: String) async {
        await authenticate {
            try await service.login(
                LoginAccountRequest(email: email, password: password)
            )
        }
    }

    func register(
        companyName: String,
        ownerName: String,
        email: String,
        password: String,
        otp: String
    ) async {
        await authenticate {
            try await service.register(
                CompanyRegistrationRequest(
                    companyName: companyName,
                    ownerName: ownerName,
                    email: email,
                    password: password,
                    otp: otp
                )
            )
        }
    }

    func requestRegistrationOTP(email: String) async -> RegistrationOTPResponse? {
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            let response = try await service.requestRegistrationOTP(email: email)
            noticeMessage = response.message
            return response
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func logout() async {
        if let token {
            try? await service.logout(token: token)
        }
        clearLocalSession()
    }

    func changeTemporaryPassword(
        currentPassword: String,
        newPassword: String
    ) async -> Bool {
        guard let token else { return false }
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            let response = try await service.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                token: token
            )
            let context = try await service.context(token: token)
            user = context.user
            organization = context.organization
            noticeMessage = response.message
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadMembers() async {
        guard let token, canManageMembers else { return }
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            members = try await service.members(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createMember(
        name: String,
        email: String,
        password: String,
        role: AccountRole
    ) async -> Bool {
        guard let token else { return false }
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            _ = try await service.createMember(
                MemberCreateRequest(
                    email: email,
                    fullName: name,
                    password: password,
                    role: role
                ),
                token: token
            )
            await loadMembers()
            noticeMessage = "Đã tạo tài khoản và gửi thông tin đăng nhập tới email nhân viên."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateMember(
        _ member: AppUser,
        role: AccountRole? = nil,
        isActive: Bool? = nil
    ) async {
        guard let token else { return }
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            _ = try await service.updateMember(
                id: member.id,
                request: MemberUpdateRequest(role: role, isActive: isActive),
                token: token
            )
            await loadMembers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func authenticate(
        operation: () async throws -> AuthenticationResponse
    ) async {
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            let response = try await operation()
            token = response.accessToken
            user = response.user
            organization = response.organization
            AuthTokenStore.save(response.accessToken)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearLocalSession() {
        token = nil
        user = nil
        organization = nil
        members = []
        AuthTokenStore.delete()
    }
}
