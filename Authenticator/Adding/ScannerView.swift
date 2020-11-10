import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
        enum ScanError: Error {
                case badInput, badOutput
        }

        class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
                var parent: ScannerView
                var codeFound = false

                init(parent: ScannerView) {
                        self.parent = parent
                }
                
                private var feedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
                func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
                        defer {
                                codeFound = true
                                feedbackGenerator = nil
                        }
                        feedbackGenerator?.prepare()
                        guard !codeFound else { return }
                        guard let metadataObject: AVMetadataObject = metadataObjects.first else { return }
                        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                        guard let stringValue: String = readableObject.stringValue else { return }
                        feedbackGenerator?.notificationOccurred(.success)
                        found(code: stringValue)
                }

                func found(code: String) {
                        parent.completion(.success(code))
                }

                func didFail(reason: ScanError) {
                        parent.completion(.failure(reason))
                }
        }
        #if targetEnvironment(simulator)
        class ScannerViewController: UIViewController {
                var delegate: ScannerCoordinator?
                override func loadView() {
                        view = UIView()
                        let label = UILabel()
                        label.translatesAutoresizingMaskIntoConstraints = false
                        label.numberOfLines = 0
                        label.text = "Running in simulator"
                        view.addSubview(label)
                        NSLayoutConstraint.activate([
                                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                        ])
                }
        }
        #else
        class ScannerViewController: UIViewController {
                private let captureSession: AVCaptureSession = AVCaptureSession()
                private var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
                var delegate: ScannerCoordinator?
                
                override func viewDidLoad() {
                        super.viewDidLoad()
                        
                        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
                        guard let videoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
                        guard captureSession.canAddInput(videoInput) else {
                                delegate?.didFail(reason: .badInput)
                                return
                        }
                        captureSession.addInput(videoInput)
                        
                        let metadataOutput = AVCaptureMetadataOutput()
                        guard captureSession.canAddOutput(metadataOutput) else {
                                delegate?.didFail(reason: .badOutput)
                                return
                        }
                        captureSession.addOutput(metadataOutput)
                        metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = delegate?.parent.codeTypes
                }
                
                override func viewWillLayoutSubviews() {
                        previewLayer.frame = view.layer.bounds
                }

                override func viewDidAppear(_ animated: Bool) {
                        super.viewDidAppear(animated)
                        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                        previewLayer.frame = view.layer.bounds
                        previewLayer.videoGravity = .resizeAspectFill
                        view.layer.addSublayer(previewLayer)
                        if !captureSession.isRunning {
                                captureSession.startRunning()
                        }
                }
                
                override func viewWillAppear(_ animated: Bool) {
                        super.viewWillAppear(animated)
                        if !captureSession.isRunning {
                                captureSession.startRunning()
                        }
                }
                override func viewWillDisappear(_ animated: Bool) {
                        super.viewWillDisappear(animated)
                        if captureSession.isRunning {
                                captureSession.stopRunning()
                        }
                }
        }
        #endif
        
        let codeTypes: [AVMetadataObject.ObjectType]
        let completion: (Result<String, ScanError>) -> Void
        
        init(codeTypes: [AVMetadataObject.ObjectType], completion: @escaping (Result<String, ScanError>) -> Void) {
                self.codeTypes = codeTypes
                self.completion = completion
        }
        func makeCoordinator() -> ScannerCoordinator {
                return ScannerCoordinator(parent: self)
        }
        func makeUIViewController(context: Context) -> ScannerViewController {
                let viewController = ScannerViewController()
                viewController.delegate = context.coordinator
                return viewController
        }
        func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

struct Scanner: View {
        
        @Binding var isPresented: Bool
        let codeTypes: [AVMetadataObject.ObjectType]
        let completion: (Result<String, ScannerView.ScanError>) -> Void
        
        var body: some View {
                NavigationView {
                        ScannerView(codeTypes: codeTypes, completion: completion)
                                .navigationTitle("Scanning")
                                .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading) {
                                                Button(action: {
                                                        isPresented = false
                                                }) {
                                                        Text("Cancel")
                                                }
                                        }
                                }
                }
        }
}
