import Foundation
import NetworkExtension

autoreleasepool {
    // This instructs the OS that this binary services NEFilterDataProvider
    NEProvider.startSystemExtensionMode()
}
dispatchMain()
