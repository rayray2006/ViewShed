import SwiftUI

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @State private var showError = false

    var body: some View {
        ZStack {
            // MapBox map view
            MapBoxView(viewModel: mapViewModel)
                .ignoresSafeArea()

            // Map controls overlay
            MapControlsView(viewModel: mapViewModel)

            // Error alert
            if let errorMessage = mapViewModel.errorMessage {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                        Spacer()
                        Button(action: {
                            mapViewModel.clearError()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding()

                    Spacer()
                }
            }
        }
        .onAppear {
            // Request location permissions
            mapViewModel.isTrackingLocation = true
            // Center on user location (Half Dome test location)
            mapViewModel.moveToUserLocation()
        }
    }
}

#Preview {
    ContentView()
}
