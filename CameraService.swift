import Foundation
import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var lastErrorMessage: String? = nil

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false

    private var onPhotoCaptured: ((UIImage) -> Void)?

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        default:
            isAuthorized = false
        }
    }

    func configureIfNeeded() {
        guard isAuthorized else { return }
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .photo

        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            lastErrorMessage = "No back camera available."
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            lastErrorMessage = "Failed to create camera input."
            session.commitConfiguration()
            return
        }

        // Output
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        photoOutput.isHighResolutionCaptureEnabled = true

        session.commitConfiguration()
    }

    func start() {
        guard isAuthorized else { return }
        configureIfNeeded()
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        onPhotoCaptured = completion
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let _ = error {
            DispatchQueue.main.async {
                self.lastErrorMessage = "Failed to capture photo."
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.lastErrorMessage = "Failed to decode photo."
            }
            return
        }

        DispatchQueue.main.async {
            self.onPhotoCaptured?(image)
            self.onPhotoCaptured = nil
        }
    }
}
