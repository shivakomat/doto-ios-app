import SwiftUI

struct LandingView: View {
    @State private var showClaimSheet = false
    @State private var showPrivacyNotice = !UserDefaults.standard.bool(forKey: "doto.privacyNoticeShown")

    var body: some View {
        NavigationStack {
            ZStack {
                DotoLogoMark.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 14) {
                        DotoLogoMark(size: 220, framed: false)
                        Text("Doto")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.dashNavy)
                        Text("Family life. Done.")
                            .font(.system(size: 17).italic())
                            .foregroundColor(.dashSubtle)
                    }
                    .offset(y: 24)

                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink(destination: RegisterView(path: .createFamily)) {
                            Text("Create a family")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        NavigationLink(destination: SignInView()) {
                            Text("Sign in")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        HStack(spacing: 18) {
                            NavigationLink(destination: FamilyCodeEntryView()) {
                                Text("Join a family")
                            }
                            Circle().fill(Color.dashSubtle.opacity(0.4)).frame(width: 4, height: 4)
                            Button("I was added as a child") { showClaimSheet = true }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.dashBlue)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                }
            }
            .sheet(isPresented: $showClaimSheet) {
                ClaimStep1View()
            }
            .sheet(isPresented: $showPrivacyNotice) {
                PrivacyNoticeView()
            }
        }
        .tint(.dashBlue)
    }
}
