import NotchHubMediaCore

@MainActor
protocol MediaRuntimeSession: AnyObject {
    func start()
    func stop()
    func togglePlayPause()
    func goPrevious()
    func goNext()
    func seek(to positionSeconds: Double)
}

extension ShippingMediaRuntime: MediaRuntimeSession {}
