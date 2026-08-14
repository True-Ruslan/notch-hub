import NotchHubMediaCore

@MainActor
protocol MediaRuntimeSession: AnyObject {
    func start()
    func stop()
    func togglePlayPause()
    func goPrevious()
    func goNext()
}

extension ShippingMediaRuntime: MediaRuntimeSession {}
