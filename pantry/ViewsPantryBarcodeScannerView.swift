//
//  BarcodeScannerView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import AVFoundation

// MARK: - Public SwiftUI Interface

/// Presents a full-screen camera sheet that calls `onScan` when a barcode is detected.
/// Dismiss the sheet after receiving the result.
struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called with the raw barcode string on a successful scan.
    var onScan: (String) -> Void

    @State private var isFlashlightOn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera feed
                CameraPreview(
                    isFlashlightOn: $isFlashlightOn,
                    errorMessage: $errorMessage,
                    onScan: { barcode in
                        onScan(barcode)
                        dismiss()
                    }
                )
                .ignoresSafeArea()

                // Viewfinder overlay
                ScannerOverlay()

                // Error banner
                if let errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding()
                    }
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black.opacity(0.6), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(.white)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isFlashlightOn.toggle()
                    } label: {
                        Image(systemName: isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    }
                    .tint(.white)
                }
            }
        }
    }
}

// MARK: - Viewfinder Overlay

private struct ScannerOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let frameSize = min(geometry.size.width, geometry.size.height) * 0.65
            let frameOriginX = (geometry.size.width - frameSize) / 2
            let frameOriginY = (geometry.size.height - frameSize) / 2

            ZStack {
                // Dimmed surround
                Color.black.opacity(0.5)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: frameSize, height: frameSize)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )

                // Corner brackets
                CornerBrackets(size: frameSize)
                    .position(x: frameOriginX + frameSize / 2, y: frameOriginY + frameSize / 2)

                // Instruction label
                VStack {
                    Spacer()
                        .frame(height: frameOriginY + frameSize + 24)
                    Text("Point camera at a barcode")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 4)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct CornerBrackets: View {
    let size: CGFloat
    private let length: CGFloat = 24
    private let lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Top-left
            Path { path in
                path.move(to: CGPoint(x: -size/2, y: -size/2 + length))
                path.addLine(to: CGPoint(x: -size/2, y: -size/2))
                path.addLine(to: CGPoint(x: -size/2 + length, y: -size/2))
            }
            // Top-right
            Path { path in
                path.move(to: CGPoint(x: size/2 - length, y: -size/2))
                path.addLine(to: CGPoint(x: size/2, y: -size/2))
                path.addLine(to: CGPoint(x: size/2, y: -size/2 + length))
            }
            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: size/2, y: size/2 - length))
                path.addLine(to: CGPoint(x: size/2, y: size/2))
                path.addLine(to: CGPoint(x: size/2 - length, y: size/2))
            }
            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: -size/2 + length, y: size/2))
                path.addLine(to: CGPoint(x: -size/2, y: size/2))
                path.addLine(to: CGPoint(x: -size/2, y: size/2 - length))
            }
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

// MARK: - UIKit Camera Preview (UIViewRepresentable)

private struct CameraPreview: UIViewRepresentable {
    @Binding var isFlashlightOn: Bool
    @Binding var errorMessage: String?
    var onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, errorMessage: $errorMessage)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.setup(view: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.setFlashlight(on: isFlashlightOn)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onScan: (String) -> Void
        @Binding var errorMessage: String?

        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void, errorMessage: Binding<String?>) {
            self.onScan = onScan
            self._errorMessage = errorMessage
        }

        func setup(view: PreviewView) {
            // Request camera permission then configure session
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                configureSession(view: view)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.configureSession(view: view)
                        } else {
                            self?.errorMessage = "Camera access is required to scan barcodes. Enable it in Settings."
                        }
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.errorMessage = "Camera access denied. Enable it in Settings > Pantry."
                }
            }
        }

        private func configureSession(view: PreviewView) {
            session.beginConfiguration()

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                DispatchQueue.main.async { self.errorMessage = "Unable to access the camera." }
                return
            }
            session.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            guard session.canAddOutput(metadataOutput) else { return }
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            // Support common 1-D and 2-D barcode formats
            metadataOutput.metadataObjectTypes = [
                .ean13, .ean8, .upce, .code128, .code39, .code93,
                .pdf417, .qr, .aztec, .dataMatrix, .itf14
            ]

            session.commitConfiguration()

            // Attach preview layer
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer

            DispatchQueue.main.async {
                view.setPreviewLayer(layer)
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        func setFlashlight(on: Bool) {
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch,
                  (try? device.lockForConfiguration()) != nil else { return }
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }

        // MARK: AVCaptureMetadataOutputObjectsDelegate

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = object.stringValue else { return }

            hasScanned = true
            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
            onScan(stringValue)
        }
    }
}

// MARK: - Custom UIView for Preview

final class PreviewView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer?.removeFromSuperlayer()
        layer.frame = bounds
        self.layer.addSublayer(layer)
        previewLayer = layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
