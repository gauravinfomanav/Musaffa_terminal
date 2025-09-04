import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let minSize = NSSize(width: 1400, height: 800)
    self.minSize = minSize
    let initialSize = NSSize(width: 1400, height: 800)
    let initialFrame = NSRect(origin: NSPoint(x: 100, y: 100), size: initialSize)
    self.setFrame(initialFrame, display: true)
    
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
