import SwiftUI
import AVFoundation

// MARK: - Camera Coordinator
class BarcodeScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeFound: (String) -> Void
    var hasFired = false

    init(onBarcodeFound: @escaping (String) -> Void) {
        self.onBarcodeFound = onBarcodeFound
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasFired,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = object.stringValue else { return }
        hasFired = true
        DispatchQueue.main.async { self.onBarcodeFound(barcode) }
    }
}

// MARK: - Preview UIView backed by AVCaptureVideoPreviewLayer
final class BarcodeScannerPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Camera Preview UIViewRepresentable
struct BarcodeScannerView: UIViewRepresentable {
    let onBarcodeFound: (String) -> Void
    @Binding var torchOn: Bool

    private let session = AVCaptureSession()

    func makeCoordinator() -> BarcodeScannerCoordinator {
        BarcodeScannerCoordinator(onBarcodeFound: onBarcodeFound)
    }

    func makeUIView(context: Context) -> BarcodeScannerPreviewView {
        let view = BarcodeScannerPreviewView(frame: .zero)
        view.backgroundColor = .black

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }

        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [
                .ean13, .ean8, .upce, .code128, .code39, .qr, .dataMatrix
            ]
        }
        session.commitConfiguration()

        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        return view
    }

    func updateUIView(_ uiView: BarcodeScannerPreviewView, context: Context) {
        // Toggle torch
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = torchOn ? .on : .off
        device.unlockForConfiguration()
    }

    static func dismantleUIView(_ uiView: BarcodeScannerPreviewView, coordinator: BarcodeScannerCoordinator) {
        // Session cleanup happens automatically
    }
}
