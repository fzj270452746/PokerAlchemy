import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureTabBarAppearance()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.08, green: 0.11, blue: 0.18, alpha: 1.0)

        let normalAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.5, alpha: 1)
        ]
        let selectedAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.5, alpha: 1)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
