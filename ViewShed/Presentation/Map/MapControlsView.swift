import SwiftUI

/// Controls overlay for the map view
struct MapControlsView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack {
            HStack {
                Spacer()

                VStack(spacing: 12) {
                    // Download Offline Area button
                    Button(action: {
                        viewModel.downloadOfflineArea()
                    }) {
                        ZStack {
                            if viewModel.isDownloading {
                                // Progress ring
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .trim(from: 0, to: viewModel.downloadProgress)
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 38, height: 38)
                                    .rotationEffect(.degrees(-90))
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(viewModel.isDownloading ? Color.orange : Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                    }
                    .disabled(viewModel.isDownloading)
                    .accessibilityLabel("Download offline area")
                    
                    // Simulation button
                    Button(action: {
                        viewModel.toggleSimulation()
                    }) {
                        Image(systemName: viewModel.isSimulating ? "stop.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(viewModel.isSimulating ? Color.red : Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel(viewModel.isSimulating ? "Stop simulation" : "Start simulation")
                    
                    // Calculate viewshed button
                    Button(action: {
                        viewModel.calculateViewshed()
                    }) {
                        ZStack {
                            if viewModel.isCalculatingViewshed {
                                // Progress ring
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .trim(from: 0, to: viewModel.viewshedProgress)
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 38, height: 38)
                                    .rotationEffect(.degrees(-90))
                            } else {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(viewModel.isCalculatingViewshed ? Color.orange : Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                    }
                    .disabled(viewModel.isCalculatingViewshed)
                    .accessibilityLabel("Calculate viewshed")

                    // User location button
                    Button(action: {
                        viewModel.moveToUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel("Move to current location")

                    // Toggle viewed areas
                    Button(action: {
                        viewModel.toggleViewedAreas()
                    }) {
                        Image(systemName: viewModel.showViewedAreas ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(viewModel.showViewedAreas ? Color.green : Color.gray)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel(viewModel.showViewedAreas ? "Hide viewed areas" : "Show viewed areas")

                    // Reset camera
                    Button(action: {
                        viewModel.resetCamera()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel("Reset camera")
                }
                .padding(.trailing, 16)
            }

            Spacer()

            // Status bar at bottom
            VStack(spacing: 8) {
                // Calculation status
                if viewModel.isCalculatingViewshed {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Calculating viewshed... \(Int(viewModel.viewshedProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                } else if let time = viewModel.lastCalculationTime {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(String(format: "Viewshed calculated in %.1fs", time))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }

                // Location info
                if let location = viewModel.userLocation {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        Text(String(format: "%.6f, %.6f", location.latitude, location.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if viewModel.isTrackingLocation {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Tracking")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    MapControlsView(viewModel: MapViewModel())
}
