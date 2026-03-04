//
//  DocumentScannerView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-03-03.
//

import SwiftUI
import VisionKit

// MARK: - Public SwiftUI Interface

/// Presents the system `VNDocumentCameraViewController` as a full-screen cover.
/// Calls `onScan([UIImage])` with the captured pages on success,
/// `onCancel` when the user dismisses without scanning, or
/// `onError` when the camera encounters a hardware/permission failure.
struct DocumentScannerView: UIViewControllerRepresentable {

    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void
    var onError: ((Error) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel, onError: onError)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No dynamic updates needed
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScan: ([UIImage]) -> Void
        var onCancel: () -> Void
        var onError: ((Error) -> Void)?

        init(
            onScan: @escaping ([UIImage]) -> Void,
            onCancel: @escaping () -> Void,
            onError: ((Error) -> Void)?
        ) {
            self.onScan = onScan
            self.onCancel = onCancel
            self.onError = onError
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for pageIndex in 0 ..< scan.pageCount {
                images.append(scan.imageOfPage(at: pageIndex))
            }
            onScan(images)
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            if let onError {
                onError(error)
            } else {
                onCancel()
            }
        }
    }
}
