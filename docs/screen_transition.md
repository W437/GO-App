Here’s a spec you can give Codex for implementing this transition (iOS / UIKit, navigation-style “card tilt” with interactive swipe-to-close).

---

### Concept (for Codex)

* Use a custom `UINavigationControllerDelegate` + `UIViewControllerAnimatedTransitioning`.
* New screen is presented as a “card” that:

  * Starts slightly scaled down, shifted right, and with a subtle 3D tilt (left side higher, right side lower).
  * Animates to `identity` (no transform) on push.
* When swiping from the left edge to go back:

  * Reverse the transform: the current screen tilts and moves right while scaling down.
  * The previous screen underneath scales up slightly / comes forward.
* Use `CATransform3D` with perspective (`m34`) for the tilt, plus scale and translation tweens.
* Hook up an interactive transition using `UIPanGestureRecognizer` + `UIPercentDrivenInteractiveTransition`.

---

### Example Implementation (Swift, UIKit)

```swift
import UIKit

// MARK: - Transition Type

enum CardTransitionType {
    case push
    case pop
}

// MARK: - Animator

final class CardLikeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let type: CardTransitionType
    private let duration: TimeInterval = 0.45

    init(type: CardTransitionType) {
        self.type = type
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let fromView = fromVC.view!
        let toView = toVC.view!

        let bounds = container.bounds

        // Perspective transform
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 900.0

        switch type {
        case .push:
            container.addSubview(toView)
            toView.frame = bounds

            // Initial state of incoming "card"
            // Slightly to the right, scaled down, left side raised
            let translateX: CGFloat = bounds.width * 0.25
            let translateY: CGFloat = 10
            let scale: CGFloat = 0.9
            let tiltAngle: CGFloat = -6 * .pi / 180 // negative => left higher

            var startTransform = CATransform3DScale(perspective, scale, scale, 1)
            startTransform = CATransform3DTranslate(startTransform, translateX, translateY, 0)
            startTransform = CATransform3DRotate(startTransform, tiltAngle, 0, 0, 1)

            toView.layer.transform = startTransform
            toView.layer.cornerRadius = 24
            toView.layer.masksToBounds = true

            // Slightly dim & scale the background (fromView)
            let backgroundScale: CGFloat = 0.96
            let backgroundTransform = CATransform3DScale(perspective, backgroundScale, backgroundScale, 1)

            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.8,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                fromView.layer.transform = backgroundTransform
                fromView.layer.cornerRadius = 20

                toView.layer.transform = CATransform3DIdentity
                toView.layer.cornerRadius = 0
            } completion: { finished in
                fromView.layer.transform = CATransform3DIdentity
                fromView.layer.cornerRadius = 0

                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }

        case .pop:
            container.insertSubview(toView, belowSubview: fromView)
            toView.frame = bounds

            // Prepare background (toView) slightly scaled down
            let backgroundScale: CGFloat = 0.96
            let backgroundTransform = CATransform3DScale(perspective, backgroundScale, backgroundScale, 1)
            toView.layer.transform = backgroundTransform
            toView.layer.cornerRadius = 20

            // Final state of outgoing card (same as push initial)
            let translateX: CGFloat = bounds.width * 0.25
            let translateY: CGFloat = 10
            let scale: CGFloat = 0.9
            let tiltAngle: CGFloat = -6 * .pi / 180

            var endTransform = CATransform3DScale(perspective, scale, scale, 1)
            endTransform = CATransform3DTranslate(endTransform, translateX, translateY, 0)
            endTransform = CATransform3DRotate(endTransform, tiltAngle, 0, 0, 1)

            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.7,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                fromView.layer.transform = endTransform
                fromView.layer.cornerRadius = 24

                toView.layer.transform = CATransform3DIdentity
                toView.layer.cornerRadius = 0
            } completion: { finished in
                let cancelled = transitionContext.transitionWasCancelled

                if cancelled {
                    toView.removeFromSuperview()
                    fromView.layer.transform = CATransform3DIdentity
                    fromView.layer.cornerRadius = 0
                } else {
                    fromView.removeFromSuperview()
                    toView.layer.transform = CATransform3DIdentity
                    toView.layer.cornerRadius = 0
                }

                transitionContext.completeTransition(!cancelled)
            }
        }
    }
}
```

---

### Navigation Controller Delegate + Interactive Swipe

```swift
final class CardNavigationDelegate: NSObject, UINavigationControllerDelegate {
    weak var navigationController: UINavigationController?
    var interactionController: UIPercentDrivenInteractiveTransition?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        navigationController.delegate = self

        // Add pan gesture for interactive pop
        let pan = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        pan.edges = .left
        navigationController.view.addGestureRecognizer(pan)
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard let nav = navigationController else { return }

        let translation = gesture.translation(in: nav.view)
        let progress = max(0, min(1, translation.x / nav.view.bounds.width))

        switch gesture.state {
        case .began:
            interactionController = UIPercentDrivenInteractiveTransition()
            nav.popViewController(animated: true)

        case .changed:
            interactionController?.update(progress)

        case .ended, .cancelled:
            // Threshold for completing
            if progress > 0.35 {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }
            interactionController = nil

        default:
            break
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        switch operation {
        case .push:
            return CardLikeAnimator(type: .push)
        case .pop:
            return CardLikeAnimator(type: .pop)
        default:
            return nil
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}
```

---

### Usage Example

In your scene/flow setup (e.g. in `SceneDelegate`, `AppCoordinator`, or wherever you create the root navigation controller):

```swift
class AppCoordinator {
    let window: UIWindow
    let navigationController: UINavigationController
    let cardNavDelegate: CardNavigationDelegate

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController(rootViewController: RootViewController())
        self.cardNavDelegate = CardNavigationDelegate(navigationController: navigationController)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
```

That’s it: pushing/popping on this `UINavigationController` will now use the “card tilt” transition, and the left-edge swipe will perform the same animation interactively, similar to the behavior in your screenshots.
