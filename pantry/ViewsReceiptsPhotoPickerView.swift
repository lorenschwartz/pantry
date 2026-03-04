//
//  PhotoPickerView.swift
//  pantry
//
//  Created by Loren Schwartz on 2026-03-03.
//

import SwiftUI
import PhotosUI

// MARK: - Public SwiftUI Interface

/// Presents `PHPickerViewController` for single-image selection.
/// Does NOT require `NSPhotoLibraryUsageDescription` (PHPicker uses direct access on iOS 14+).
/// Calls `onPick(UIImage)` when the user selects a photo, or `onCancel` if dismissed.
struct PhotoPickerView: UIViewControllerRepresentable {

    var onPick: (UIImage) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No dynamic updates needed
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onPick: (UIImage) -> Void
        var onCancel: () -> Void

        init(onPick: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onCancel()
                return
            }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.onPick(image)
                    } else {
                        self?.onCancel()
                    }
                }
            }
        }
    }
}
