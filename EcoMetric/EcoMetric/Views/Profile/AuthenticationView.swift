import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var session: AccountSession

    @State private var isRegistering = false
    @State private var companyName = ""
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var otp = ""
    @State private var otpSent = false
    @State private var verifiedEmail = ""
    @State private var resendSecondsRemaining = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 34)
                brand
                Picker("Chế độ", selection: $isRegistering) {
                    Text("Đăng nhập").tag(false)
                    Text("Tạo công ty").tag(true)
                }
                .pickerStyle(.segmented)
                form
                submitButton

                if isRegistering && otpSent {
                    resendControls
                }

                if let error = session.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let notice = session.noticeMessage {
                    Label(notice, systemImage: "envelope.badge.fill")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.darkGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(EcoTheme.lightGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Label(
                    isRegistering
                        ? "Tài khoản đầu tiên sẽ là Chủ doanh nghiệp."
                        : "Phiên đăng nhập được bảo vệ trong Keychain.",
                    systemImage: "checkmark.shield.fill"
                )
                .font(.caption)
                .foregroundStyle(EcoTheme.textSecondary)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
        .background(EcoTheme.background.ignoresSafeArea())
        .onChange(of: isRegistering) { _, _ in resetOTP() }
    }

    private var brand: some View {
        VStack(spacing: 13) {
            EcoLogo()
                .scaleEffect(1.25)
                .frame(height: 54)
            Text("EcoMetric Business")
                .font(.largeTitle.bold())
                .foregroundStyle(EcoTheme.navy)
            Text("Dữ liệu và AI dành riêng cho doanh nghiệp của bạn")
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            if isRegistering {
                accountField(
                    title: "Tên doanh nghiệp",
                    placeholder: "Công ty TNHH Xanh",
                    icon: "building.2.fill",
                    text: $companyName
                )
                accountField(
                    title: "Họ tên chủ tài khoản",
                    placeholder: "Nguyễn Văn A",
                    icon: "person.fill",
                    text: $fullName
                )
            }

            accountField(
                title: "Email",
                placeholder: "admin@congty.vn",
                icon: "envelope.fill",
                text: $email,
                keyboard: .emailAddress
            )
            .disabled(isRegistering && otpSent)
            .opacity(isRegistering && otpSent ? 0.72 : 1)

            VStack(alignment: .leading, spacing: 7) {
                Text("Mật khẩu")
                    .font(.caption.bold())
                    .foregroundStyle(EcoTheme.textSecondary)
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(EcoTheme.green)
                        .frame(width: 22)
                    SecureField("Tối thiểu 8 ký tự", text: $password)
                        // `.newPassword` có thể hiển thị lớp phủ Strong Password
                        // bị lỗi trên một số bản iOS Simulator.
                        .textContentType(.password)
                }
                .padding(13)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            }

            if isRegistering && otpSent {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Mã xác minh email")
                            .font(.caption.bold())
                            .foregroundStyle(EcoTheme.textSecondary)
                        Spacer()
                        Button("Dùng email khác") { resetOTP() }
                            .font(.caption.bold())
                    }
                    HStack {
                        Image(systemName: "number.square.fill")
                            .foregroundStyle(EcoTheme.green)
                            .frame(width: 22)
                        TextField("Nhập 6 số", text: $otp)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .onChange(of: otp) { _, newValue in
                                otp = String(newValue.filter(\.isNumber).prefix(6))
                            }
                    }
                    .padding(13)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    Text("Mã đã gửi tới \(verifiedEmail) và có hiệu lực trong 10 phút.")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                if isRegistering {
                    if otpSent {
                        await session.register(
                            companyName: companyName,
                            ownerName: fullName,
                            email: verifiedEmail,
                            password: password,
                            otp: otp
                        )
                    } else {
                        await sendOTP()
                    }
                } else {
                    await session.login(email: email, password: password)
                }
            }
        } label: {
            HStack {
                if session.isWorking { ProgressView().tint(.white) }
                Text(submitTitle)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(EcoTheme.green)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(session.isWorking || !isFormValid)
        .opacity(isFormValid ? 1 : 0.55)
    }

    private var isFormValid: Bool {
        let base = email.contains("@") && password.count >= 8
        return isRegistering
            ? base && companyName.count >= 2 && fullName.count >= 2
                && (!otpSent || otp.count == 6)
            : base
    }

    private var submitTitle: String {
        if !isRegistering { return "Đăng nhập" }
        return otpSent ? "Xác minh và tạo công ty" : "Gửi mã xác minh"
    }

    private var resendControls: some View {
        HStack {
            Text(
                resendSecondsRemaining > 0
                    ? "Có thể gửi lại sau \(resendSecondsRemaining) giây"
                    : "Bạn chưa nhận được mã?"
            )
            .font(.caption)
            .foregroundStyle(EcoTheme.textSecondary)
            Spacer()
            Button("Gửi lại") { Task { await sendOTP() } }
                .font(.caption.bold())
                .disabled(resendSecondsRemaining > 0 || session.isWorking)
        }
    }

    private func sendOTP() async {
        guard let response = await session.requestRegistrationOTP(email: email) else {
            return
        }
        verifiedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        otpSent = true
        otp = response.developmentCode ?? ""
        resendSecondsRemaining = response.resendAfterSeconds
        while resendSecondsRemaining > 0 && otpSent {
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled { resendSecondsRemaining -= 1 }
        }
    }

    private func resetOTP() {
        otp = ""
        otpSent = false
        verifiedEmail = ""
        resendSecondsRemaining = 0
        session.noticeMessage = nil
        session.errorMessage = nil
    }

    private func accountField(
        title: String,
        placeholder: String,
        icon: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(EcoTheme.textSecondary)
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(EcoTheme.green)
                    .frame(width: 22)
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                    .autocorrectionDisabled(keyboard == .emailAddress)
            }
            .padding(13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
    }
}
