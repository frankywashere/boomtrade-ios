import SwiftUI

struct ContentView: View {
    @StateObject private var api = TradingAPI.shared
    @State private var selectedTab = 0
    @State private var showingLogin = true
    
    var body: some View {
        if showingLogin && !api.isGatewayReady {
            LoginView(showingLogin: $showingLogin)
        } else {
            TabView(selection: $selectedTab) {
                TradingView()
                    .tabItem {
                        Label("Trade", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)
                
                OptionsView()
                    .tabItem {
                        Label("Options", systemImage: "list.bullet.rectangle")
                    }
                    .tag(1)
                
                PositionsView()
                    .tabItem {
                        Label("Positions", systemImage: "briefcase")
                    }
                    .tag(2)
                
                ChartsView()
                    .tabItem {
                        Label("Charts", systemImage: "chart.xyaxis.line")
                    }
                    .tag(3)
            }
        }
    }
}
