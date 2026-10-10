import SwiftUI

struct MemberManagementView: View {
    @EnvironmentObject private var session: AccountSession
    @State private var showAddMember = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                planSummary
                if let error = session.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let notice = session.noticeMessage {
                    Label(notice, systemImage: "envelope.badge.fill")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.darkGreen)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(EcoTheme.lightGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                ForEach(session.members) { member in
                    memberCard(member)
                }
            }
            .padding(16)
        }
        .background(EcoTheme.background.ignoresSafeArea())
        .navigationTitle("Quản lý thành viên")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddMember = true } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberView(isPresented: $showAddMember)
                .environmentObject(session)
        }
        .task { await session.loadMembers() }
        .refreshable { await session.loadMembers() }
    }

    private var planSummary: some View {
        HStack(spacing: 13) {
            Image(systemName: "person.3.fill")
                .font(.title2)
                .foregroundStyle(EcoTheme.green)
                .frame(width: 46, height: 46)
                .background(EcoTheme.lightGreen)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text("Nhân sự doanh nghiệp")
                    .font(.headline)
                    .foregroundStyle(EcoTheme.textPrimary)
                Text("\(session.members.filter(\.isActive).count)/\(session.organization?.seatLimit ?? 0) tài khoản đang hoạt động")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }
        }
        .memberCardStyle()
    }

    private func memberCard(_ member: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(member.fullName.prefix(1).uppercased())
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(roleColor(member.role))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.fullName)
                        .font(.headline)
                        .foregroundStyle(EcoTheme.textPrimary)
                    Text(member.email)
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
                Spacer()
                Text(member.role.title)
                    .font(.caption2.bold())
                    .foregroundStyle(roleColor(member.role))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(roleColor(member.role).opacity(0.10))
                    .clipShape(Capsule())
            }

            if member.mustChangePassword {
                Label("Chờ đổi mật khẩu tạm", systemImage: "clock.badge.exclamationmark")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            if canEdit(member) {
                Divider()
                HStack {
                    if session.user?.role == .owner {
                        Menu {
                            Button("Quản trị viên") {
                                Task { await session.updateMember(member, role: .admin) }
                            }
                            Button("Nhân viên") {
                                Task { await session.updateMember(member, role: .member) }
                            }
                        } label: {
                            Label("Đổi quyền", systemImage: "person.badge.key.fill")
                                .font(.caption.bold())
                        }
                    }
                    Spacer()
                    Button(role: member.isActive ? .destructive : nil) {
                        Task {
                            await session.updateMember(member, isActive: !member.isActive)
                        }
                    } label: {
                        Text(member.isActive ? "Vô hiệu hóa" : "Kích hoạt")
                            .font(.caption.bold())
                    }
                }
            }
        }
        .memberCardStyle()
        .opacity(member.isActive ? 1 : 0.58)
    }

    private func canEdit(_ member: AppUser) -> Bool {
        guard member.role != .owner, member.id != session.user?.id else { return false }
        if session.user?.role == .owner { return true }
        return session.user?.role == .admin && member.role == .member
    }

    private func roleColor(_ role: AccountRole) -> Color {
        switch role {
        case .owner: return .purple
        case .admin: return EcoTheme.blue
        case .member: return EcoTheme.green
        }
    }
}

private struct AddMemberView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var session: AccountSession
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role: AccountRole = .member

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin nhân viên") {
                    TextField("Họ tên", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Mật khẩu tạm (tối thiểu 8 ký tự)", text: $password)
                }
                Section("Vai trò") {
                    Picker("Quyền sử dụng", selection: $role) {
                        Text(AccountRole.member.title).tag(AccountRole.member)
                        if session.user?.role == .owner {
                            Text(AccountRole.admin.title).tag(AccountRole.admin)
                        }
                    }
                    Text(role.description)
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
                Section {
                    Text(
                        "EcoMetric sẽ gửi email gồm công ty, vai trò và mật khẩu tạm. "
                        + "Mật khẩu hết hạn sau 24 giờ và phải đổi ngay lần đăng nhập đầu tiên."
                    )
                        .font(.caption)
                }
            }
            .navigationTitle("Thêm thành viên")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tạo") {
                        Task {
                            let created = await session.createMember(
                                name: name,
                                email: email,
                                password: password,
                                role: role
                            )
                            if created { isPresented = false }
                        }
                    }
                    .disabled(name.count < 2 || !email.contains("@") || password.count < 8)
                }
            }
        }
    }
}

private extension View {
    func memberCardStyle() -> some View {
        padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 17))
    }
}
