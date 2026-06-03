import SwiftUI
import AVFoundation

// MARK: - Coordinator (owns the session — survives struct redraws)

final class BarcodeScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    var onBarcodeFound: (String) -> Void
    private(set) var hasFired = false

    let session = AVCaptureSession()
    private let scanQueue = DispatchQueue(label: "com.imli.barcode.scan", qos: .userInitiated)

    init(onBarcodeFound: @escaping (String) -> Void) {
        self.onBarcodeFound = onBarcodeFound
        super.init()
        configureSession()
    }

    // MARK: - Session setup

    private func configureSession() {
        scanQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high  // sharp image for barcode detection

            guard let device = self.bestCamera(),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.session.commitConfiguration()
                return
            }

            // Continuous autofocus — critical fix for blur at close range
            try? device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .none  // allow macro focus
            }
            device.unlockForConfiguration()

            if self.session.canAddInput(input) { self.session.addInput(input) }

            let output = AVCaptureMetadataOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                // Use dedicated background queue — not main — for faster detection
                output.setMetadataObjectsDelegate(self, queue: self.scanQueue)
                output.metadataObjectTypes = [
                    .ean13, .ean8, .upce,
                    .code128, .code39, .code93,
                    .qr, .dataMatrix, .pdf417, .interleaved2of5
                ]
            }

            self.session.commitConfiguration()
        }
    }

    private func bestCamera() -> AVCaptureDevice? {
        // Wide-angle back camera is best for barcode scanning
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
    }

    // MARK: - Start / Stop

    func startRunning() {
        guard !session.isRunning else { return }
        scanQueue.async { [weak self] in self?.session.startRunning() }
    }

    func stopRunning() {
        guard session.isRunning else { return }
        scanQueue.async { [weak self] in self?.session.stopRunning() }
    }

    // MARK: - Reset (called when result sheet closes, ready for next scan)

    func resetScan() {
        hasFired = false
    }

    // MARK: - Torch

    func setTorch(_ on: Bool) {
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device,
              device.hasTorch else { return }
        scanQueue.async {
            try? device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasFired,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = object.stringValue, !barcode.isEmpty else { return }
        hasFired = true
        DispatchQueue.main.async { [weak self] in
            self?.onBarcodeFound(barcode)
        }
    }
}

// MARK: - Preview UIView (layer-backed)

final class BarcodeScannerPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - SwiftUI wrapper

struct BarcodeScannerView: UIViewRepresentable {
    let onBarcodeFound: (String) -> Void
    @Binding var torchOn: Bool
    /// Flip to true to re-arm the scanner after a successful scan.
    var scanEnabled: Bool

    func makeCoordinator() -> BarcodeScannerCoordinator {
        BarcodeScannerCoordinator(onBarcodeFound: onBarcodeFound)
    }

    func makeUIView(context: Context) -> BarcodeScannerPreviewView {
        let view = BarcodeScannerPreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        context.coordinator.startRunning()
        return view
    }

    func updateUIView(_ uiView: BarcodeScannerPreviewView, context: Context) {
        context.coordinator.onBarcodeFound = onBarcodeFound
        context.coordinator.setTorch(torchOn)
        // Re-arm the scanner whenever the caller signals readiness
        if scanEnabled && context.coordinator.hasFired {
            context.coordinator.resetScan()
        }
    }

    static func dismantleUIView(_ uiView: BarcodeScannerPreviewView,
                                coordinator: BarcodeScannerCoordinator) {
        coordinator.stopRunning()
    }
}
