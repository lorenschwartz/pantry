//
//  ReceiptScannerView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-02-27.
//

import SwiftUI
import VisionKit
import Vision

/// Presents the system document camera (VisionKit) and runs Vision OCR on the
/// captured page.  Calls `onScan` with the JPEG image data and extracted text,
/// then dismisses itself.
struct ReceiptScannerView: UIViewControllerRepresentable {

    /// Called on the main thread when scanning and OCR are complete.
    /// - Parameters:
    ///   - imageData: JPEG representation of the first captured page.
    ///   - ocrText:   Raw text extracted by Vision, one observation per line.
    var onScan: (Data, String) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, dismiss: { dismiss() })
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        var onScan: (Data, String) -> Void
        var dismiss: () -> Void

        init(onScan: @escaping (Data, String) -> Void, dismiss: @escaping () -> Void) {
            self.onScan = onScan
            self.dismiss = dismiss
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { dismiss(); return }

            let image = scan.imageOfPage(at: 0)
            guard let jpegData = image.jpegData(compressionQuality: 0.8),
                  let cgImage = image.cgImage
            else { dismiss(); return }

            recogniseText(in: cgImage) { [weak self] text in
                self?.onScan(jpegData, text)
                self?.dismiss()
            }
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            dismiss()
        }

        // MARK: - OCR

        private func recogniseText(in cgImage: CGImage, completion: @escaping (String) -> Void) {
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                DispatchQueue.main.async { completion(text) }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }
}
