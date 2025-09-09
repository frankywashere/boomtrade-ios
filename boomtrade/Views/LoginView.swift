import SwiftUI

struct LoginView: View {
    @StateObject private var api = TradingAPI.shared
    @State private var username = ""
    @State private var password = ""
    @State private var account = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Binding var showingLogin: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("BoomTrade")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Connect to IBKR")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("IBKR Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("IBKR Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Account ID", text: $account)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding(.horizontal, 30)
            
            if api.isAuthenticating {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text(api.authenticationMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("This may take 60-90 seconds on first connection")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding()
            } else {
                Button(action: login) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Connect to IBKR")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .disabled(username.isEmpty || password.isEmpty)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("Important: IBKR Gateway will start on connection")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("You may need to approve 2FA in IBKR Mobile")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 30)
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: api.isGatewayReady) { ready in
            if ready {
                showingLogin = false
            }
        }
    }
    
    private func login() {
        Task {
            do {
                try await api.startGateway(
                    username: username,
                    password: password,
                    account: account.isEmpty ? nil : account
                )
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}