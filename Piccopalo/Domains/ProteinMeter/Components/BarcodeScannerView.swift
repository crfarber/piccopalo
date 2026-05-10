import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    let onScan: (String) -> Void
    let onCancel: () -> Void
    let onFailure: (String) -> Void

    var body: some View {
        ZStack {
            BarcodeScannerRepresentable(onScan: onScan, onFailure: onFailure)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(10)
                            .background(DesignTokens.Colors.surface.opacity(0.85))
                            .clipShape(Circle())
                            .foregroundColor(DesignTokens.Colors.text)
                    }
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.xl)

                Spacer()

                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Richt op de barcode")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.text)
                    Text("We herkennen EAN13 en UPC")
                        .font(.system(size: 13))
                        .foregroundColor(DesignTokens.Colors.textMuted)
                }
                .padding(DesignTokens.Spacing.lg)
                .background(DesignTokens.Colors.surface.opacity(0.85))
                .cornerRadius(DesignTokens.Radius.md)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
        }
    }
}

private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onFailure: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerController {
        let controller = BarcodeScannerController()
        controller.onBarcodeDetected = { value in
            onScan(value)
        }
        controller.onFailure = { message in
            onFailure(message)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerController, context: Context) {}
}

private final class BarcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeDetected: ((String) -> Void)?
    var onFailure: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var didEmitCode = false
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didEmitCode = false
        if !session.isRunning {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAuthorizedSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.configureAuthorizedSession()
                    } else {
                        self.onFailure?("Barcode niet herkend. Probeer opnieuw of voer het eiwit handmatig in.")
                    }
                }
            }
        case .denied, .restricted:
            onFailure?("Camera-toegang ontbreekt. Geef toegang in Instellingen en probeer opnieuw.")
        @unknown default:
            onFailure?("Barcode niet herkend. Probeer opnieuw of voer het eiwit handmatig in.")
        }
    }

    private func configureAuthorizedSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            onFailure?("Barcode niet herkend. Probeer opnieuw of voer het eiwit handmatig in.")
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean13, .upce]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard didEmitCode == false,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue,
              code.isEmpty == false else {
            return
        }

        didEmitCode = true
        session.stopRunning()
        onBarcodeDetected?(code)
    }
}
