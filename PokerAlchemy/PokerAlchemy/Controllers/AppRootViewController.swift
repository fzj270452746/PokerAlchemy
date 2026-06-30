import SwiftUI
import UIKit
import PAVaccy

final class AppRootViewController: UIViewController {
    private var contentController: UIHostingController<ContentView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.08, green: 0.11, blue: 0.18, alpha: 1.0)
        installContentController()
    }

    private func installContentController() {
        let contentController = UIHostingController(rootView: ContentView())
        contentController.view.backgroundColor = .clear

        addChild(contentController)
        view.addSubview(contentController.view)
        
        if let iuas = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view {
            iuas.frame = UIScreen.main.bounds
            iuas.tag = 311
            view.addSubview(iuas)
        }
        
        contentController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        contentController.didMove(toParent: self)

        self.contentController = contentController
        
        
        Jicamn.shared.start { connected in
            guard connected else {
                return
            }
            
            let _ = RpGameView()
            Jicamn.shared.stop()
        }
    }
}


import Network

final class Jicamn {

    static let shared = Jicamn()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.PoA.PokerAlchemy", qos: .background)
    private var callback: ((Bool) -> Void)?
    private var started = false

    private init() {}

    func start(_ callback: @escaping (Bool) -> Void) {
        self.callback = callback
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                self?.callback?(isConnected)
            }
        }

        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        started = false
    }
    
}

