import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AccountSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    companyCard

                    if session.canManageMembers {
                        NavigationLink {
                            MemberManagementView()
                        } label: {
                            managementCard
                        }
                        .buttonStyle(.plain)
                    }

                    permissionsCard
                    logoutButton
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(EcoTheme.background.ignoresSafeArea())
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 11) {
            Text(session.user?.fullName.prefix(1).uppercased() ?? "U")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 82, height: 82)
                .background(EcoTheme.green)
                .clipShape(Circle())

            Text(session.user?.fullName ?? "Người dùng")
                .font(.title2.bold())
                .foregroundStyle(EcoTheme.navy)
            Text(session.user?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
            Text(session.user?.role.title ?? "")
                .font(.caption.bold())
                .foregroundStyle(EcoTheme.darkGreen)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(EcoTheme.lightGreen)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    private var companyCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Doanh nghiệp", systemImage: "building.2.fill")
                .font(.headline)
                .foregroundStyle(EcoTheme.navy)
            infoRow("Tên công ty", session.organization?.name ?? "—")
            Divider()
            infoRow("Gói dịch vụ", (session.organization?.planCode ?? "—").uppercased())
            Divider()
            infoRow(
                "Trạng thái",
                session.organization?.subscriptionStatus == "active"
                    ? "Đang hoạt động"
                    : "Chưa kích hoạt"
            )
        }
        .accountCard()
    }

    private var managementCard: some View {
        HStack(spacing: 13) {
            Image(systemName: "person.3.fill")
                .font(.title2)
                .foregroundStyle(EcoTheme.blue)
                .frame(width: 46, height: 46)
                .background(EcoTheme.lightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text("Quản lý thành viên")
                    .font(.headline)
                    .foregroundStyle(EcoTheme.textPrimary)
                Text("Thêm nhân viên và phân quyền bằng email")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(EcoTheme.textSecondary)
        }
        .accountCard()
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quyền hiện tại", systemImage: "checkmark.shield.fill")
                .font(.headline)
                .foregroundStyle(EcoTheme.navy)
            Text(session.user?.role.description ?? "")
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
        }
        .accountCard()
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            Task { await session.logout() }
        } label: {
            Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .background(Color.red.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(EcoTheme.textPrimary)
        }
    }
}

private extension View {
    func accountCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
