import SwiftUI

struct TemporaryPasswordChangeView: View {
    @EnvironmentObject private var session: AccountSession
    @State private var temporaryPassword = ""
    @State private var newPassword = ""
    @State private var confirmation = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 42)
                Image(systemName: "key.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(EcoTheme.green)
                    .frame(width: 76, height: 76)
                    .background(EcoTheme.lightGreen)
                    .clipShape(Circle())

                VStack(spacing: 8) {
                    Text("Đổi mật khẩu tạm")
                        .font(.title.bold())
                        .foregroundStyle(EcoTheme.navy)
                    Text(
                        "Tài khoản của bạn đã được doanh nghiệp cấp. "
                        + "Hãy tạo mật khẩu riêng trước khi sử dụng EcoMetric."
                    )
                    .font(.subheadline)
                    .foregroundStyle(EcoTheme.textSecondary)
                    .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    passwordField("Mật khẩu tạm trong email", text: $temporaryPassword)
                    passwordField("Mật khẩu mới", text: $newPassword)
                    passwordField("Nhập lại mật khẩu mới", text: $confirmation)
                }

                if let error = validationMessage ?? session.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        await session.changeTemporaryPassword(
                            currentPassword: temporaryPassword,
                            newPassword: newPassword
                        )
                    }
                } label: {
                    HStack {
                        if session.isWorking { ProgressView().tint(.white) }
                        Text("Đổi mật khẩu và tiếp tục")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(EcoTheme.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(validationMessage != nil || session.isWorking)
                .opacity(validationMessage == nil ? 1 : 0.55)

                Button("Đăng xuất") { Task { await session.logout() } }
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 24)
        }
        .background(EcoTheme.background.ignoresSafeArea())
    }

    private var validationMessage: String? {
        if temporaryPassword.count < 8 { return "Nhập mật khẩu tạm từ email." }
        if newPassword.count < 8 { return "Mật khẩu mới cần tối thiểu 8 ký tự." }
        if newPassword != confirmation { return "Hai mật khẩu mới chưa khớp." }
        if newPassword == temporaryPassword { return "Mật khẩu mới phải khác mật khẩu tạm." }
        return nil
    }

    private func passwordField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textContentType(.password)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}
