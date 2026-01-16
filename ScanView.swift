import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var store: UserAllergenStore
    @StateObject private var camera = CameraService()

    @State private var isProcessing = false
    @State private var capturedImage: UIImage? = nil
    @State private var recognizedLines: [String] = []
    @State private var matches: [Match] = []

    @State private var showResults = false

    private let ocr = LabelOCR()

    var body: some View {
        NavigationStack {
            ZStack {
                if camera.isAuthorized {
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                } else {
                    PermissionView()
                }

                VStack {
                    Spacer()

                    if isProcessing {
                        ProgressView("Reading label…")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.bottom, 16)
                    }

                    HStack {
                        Button {
                            captureAndProcess()
                        } label: {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 64))
                        }
                        .disabled(!camera.isAuthorized || isProcessing)
                    }
                    .padding(.bottom, 24)
                }
                .padding()
            }
            .navigationTitle("Scan Label")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                camera.checkPermission()
                camera.start()
            }
            .onDisappear {
                camera.stop()
            }
            .sheet(isPresented: $showResults) {
                ResultsView(
                    capturedImage: capturedImage,
                    recognizedLines: recognizedLines,
                    matches: matches
                )
            }
            .alert("Camera Error", isPresented: .constant(camera.lastErrorMessage != nil)) {
                Button("OK") { camera.lastErrorMessage = nil }
            } message: {
                Text(camera.lastErrorMessage ?? "")
            }
        }
    }

    private func captureAndProcess() {
        isProcessing = true

        camera.capturePhoto { image in
            capturedImage = image

            guard let cg = image.cgImage else {
                isProcessing = false
                recognizedLines = []
                matches = []
                showResults = true
                return
            }

            let orientation = image.cgImageOrientation

            ocr.recognizeLines(from: cg, orientation: orientation) { lines in
                DispatchQueue.main.async {
                    recognizedLines = lines

                    let matcher = AllergenMatcher(
                        selectedAllergens: store.compiledSelectedAllergensMap(),
                        customTerms: store.customTerms
                    )

                    matches = matcher.findMatches(in: lines)
                    isProcessing = false
                    showResults = true
                }
            }
        }
    }
}

private struct PermissionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
            Text("Camera access is required to scan labels.")
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
