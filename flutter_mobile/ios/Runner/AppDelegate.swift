import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let memoryChannel = FlutterMethodChannel(
        name: "com.captionary.captionary/system_memory",
        binaryMessenger: controller.binaryMessenger
      )
      memoryChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getMemoryInfo" {
          let totalMem = ProcessInfo.processInfo.physicalMemory
          var vmStats = vm_statistics64()
          var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
          let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
              host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
          }
          let pageSize = UInt64(vm_kernel_page_size)
          let availMem: UInt64
          if kerr == KERN_SUCCESS {
            availMem = UInt64(vmStats.free_count + vmStats.inactive_count) * pageSize
          } else {
            availMem = totalMem / 2
          }
          let threshold = UInt64(500 * 1024 * 1024)
          let lowMemory = availMem < threshold
          result([
            "totalMem": Int64(totalMem),
            "availMem": Int64(availMem),
            "lowMemory": lowMemory,
            "threshold": Int64(threshold)
          ])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
