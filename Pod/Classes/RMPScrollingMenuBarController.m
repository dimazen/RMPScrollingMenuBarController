//  Copyright (c) 2015 Recruit Marketing Partners Co.,Ltd. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RMPScrollingMenuBarController.h"
#import "RMPScrollingMenuBarControllerTransition.h"

const CGFloat RMPMenuBarDefaultBarHeight = 64.f;

@interface RMPScrollingMenuBarController () <RMPScrollingMenuBarDelegate>

@property (nonatomic, strong) NSLayoutConstraint *barHeightConstraint;

@end

@implementation RMPScrollingMenuBarController {
    NSArray *_items;
    RMPScrollingMenuBarControllerTransition *_transition;
    RMPScrollingMenuBarDirection _menuBarDirection;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _barHeight = RMPMenuBarDefaultBarHeight;
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _barHeight = RMPMenuBarDefaultBarHeight;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _menuBar = [[RMPScrollingMenuBar alloc] initWithFrame:self.view.bounds];
    self.menuBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuBar.backgroundColor = [UIColor whiteColor];
    self.menuBar.delegate = self;
    [self.view addSubview:self.menuBar];

    _containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.backgroundColor = [UIColor yellowColor];
    [self.view insertSubview:self.containerView belowSubview:self.menuBar];

    [self instantiateConstraints];
    [self updateViewConstraints];

    _transition = [[RMPScrollingMenuBarControllerTransition alloc] initWithMenuBarController:self];
    self.transitionDelegate = _transition;

    if ([_viewControllers count] > 0) {
        [self updateMenuBarWithViewControllers:_viewControllers animated:NO];
        [self setSelectedViewController:_viewControllers[0]];
    }
}

#pragma mark - Layout

- (void)instantiateConstraints {
    NSDictionary *views = @{@"view": _menuBar, @"container": self.containerView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:views]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.menuBar
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.f
                                                           constant:0.f]];

    self.barHeightConstraint = [NSLayoutConstraint constraintWithItem:self.menuBar
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1.f
                                                             constant:self.barHeight];

    [self.menuBar addConstraint:self.barHeightConstraint];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view][container]|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:views]];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];

    self.barHeightConstraint.constant = self.barHeight;
}

- (void)setBarHeight:(CGFloat)barHeight {
    _barHeight = barHeight;

    [self updateViewConstraints];
}

#pragma mark -

- (void)setViewControllers:(NSArray *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    _viewControllers = [viewControllers copy];

    if ([self isViewLoaded]) {
        [self updateMenuBarWithViewControllers:_viewControllers animated:animated];
    }

    if ([_viewControllers count] > 0) {
        [self setSelectedViewController:_viewControllers[0]];
    }
}

- (void)updateMenuBarWithViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    NSMutableArray *items = [NSMutableArray new];
    NSInteger index = 0;

    for (UIViewController *vc in viewControllers) {
        RMPScrollingMenuBarItem *item = nil;
        if ([_delegate respondsToSelector:@selector(menuBarController:menuBarItemAtIndex:)]) {
            item = [_delegate menuBarController:self menuBarItemAtIndex:index];
        } else {
            item = [RMPScrollingMenuBarItem item];
            item.title = vc.title;
        }
        [items addObject:item];

        index++;
    }

    _items = [items copy];
    [_menuBar setItems:_items animated:animated];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    if ([_viewControllers containsObject:selectedViewController]) {
        [self transitionToViewController:selectedViewController];
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex >= 0
        && selectedIndex < [_viewControllers count]
        && selectedIndex != _selectedIndex) {
        [self setSelectedViewController:_viewControllers[selectedIndex]];
    }
}

#pragma mark - Private

- (void)transitionToViewController:(UIViewController *)toViewController {
    UIViewController *fromViewController = _selectedViewController;
    // Do nothing if toViewController equals to fromViewController.
    if (toViewController == fromViewController || !_containerView) {
        return;
    }

    // Disabled the interaction of menu bar.
    _menuBar.userInteractionEnabled = NO;

    UIView *toView = toViewController.view;
    toView.frame = _containerView.bounds;
    [toView setTranslatesAutoresizingMaskIntoConstraints:YES];
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];

    if ([_delegate respondsToSelector:@selector(menuBarController:willSelectViewController:)]) {
        [_delegate menuBarController:self willSelectViewController:toViewController];
    }

    // Present toViewController if not exist fromViewController.
    if (!fromViewController) {
        [_containerView addSubview:toViewController.view];
        [toViewController didMoveToParentViewController:self];

        // Reflect selection state.
        [self finishTransitionWithViewController:toViewController cancelViewController:nil];

        return;
    }

    // Switch views with animation
    NSInteger fromIndex = [_viewControllers indexOfObject:fromViewController];
    NSInteger toIndex = [_viewControllers indexOfObject:toViewController];
    RMPMenuBarControllerDirection direction = RMPScrollingMenuBarControllerDirectionLeft;
    if (toIndex > fromIndex) {
        direction = RMPScrollingMenuBarControllerDirectionRight;
    }

    id <UIViewControllerAnimatedTransitioning> animator = nil;
    if ([_transitionDelegate respondsToSelector:@selector(menuBarController:animationControllerForDirection:fromViewController:toViewController:)]) {
        animator = [_transitionDelegate menuBarController:self
                          animationControllerForDirection:direction
                                       fromViewController:fromViewController
                                         toViewController:toViewController];
    }
    animator = (animator ?: [[RMPScrollingMenuBarControllerAnimator alloc] init]);

    UIPercentDrivenInteractiveTransition *interactionController = nil;
    if ([_transitionDelegate respondsToSelector:@selector(menuBarController:interactionControllerForAnimationController:)]) {
        interactionController = [_transitionDelegate menuBarController:self
                           interactionControllerForAnimationController:animator];
    }

    RMPScrollingMenuBarControllerTransitionContextCompletionBlock completion = ^(BOOL didComplete) {
        if (didComplete) {
            [fromViewController.view removeFromSuperview];
            [fromViewController removeFromParentViewController];
            [toViewController didMoveToParentViewController:self];

            // Reflect selection state.
            [self finishTransitionWithViewController:toViewController cancelViewController:nil];
        } else {
            // Remove toViewController from parent view controller by cancelled.
            [toViewController.view removeFromSuperview];
            [toViewController removeFromParentViewController];
            [toViewController didMoveToParentViewController:nil];

            // Reflect selection state.
            [self finishTransitionWithViewController:fromViewController cancelViewController:toViewController];
        }


    };

    RMPScrollingMenuBarControllerTransitionContext *transitionContext = nil;
    transitionContext = [[RMPScrollingMenuBarControllerTransitionContext alloc] initWithMenuBarController:self
                                                                                       fromViewController:fromViewController
                                                                                         toViewController:toViewController
                                                                                                direction:direction
                                                                                                 animator:animator
                                                                                    interactionController:interactionController
                                                                                               completion:completion];


    if (transitionContext.isInteractive) {
        [interactionController startInteractiveTransition:transitionContext];
    } else {
        [animator animateTransition:transitionContext];
    }
}

- (void)finishTransitionWithViewController:(UIViewController *)viewController cancelViewController:(UIViewController *)cancelViewController {
    NSInteger lastIndex = _selectedIndex;
    UIViewController *lastViewController = _selectedViewController;

    // Reflect selection state.
    _selectedViewController = viewController;
    _selectedIndex = [_viewControllers indexOfObject:viewController];

    _menuBar.selectedIndex = _selectedIndex;

    // Call delegate method.
    if (lastIndex != _selectedIndex || lastViewController != _selectedViewController) {
        if ([_delegate respondsToSelector:@selector(menuBarController:didSelectViewController:)]) {
            [_delegate menuBarController:self didSelectViewController:_selectedViewController];
        }
    } else {
        if ([_delegate respondsToSelector:@selector(menuBarController:didCancelViewController:)]) {
            [_delegate menuBarController:self didCancelViewController:cancelViewController];
        }
    }

    _menuBar.userInteractionEnabled = YES;
}

#pragma mark - RMPScrollingMenuBarDelegate

- (void)menuBar:(RMPScrollingMenuBar *)menuBar didSelectItemAtIndex:(NSInteger)index direction:(RMPScrollingMenuBarDirection)direction {
    if (index != NSNotFound && index != self.selectedIndex) {
        // Switch view controller.
        _menuBarDirection = direction;
        [self setSelectedIndex:index];
    }
}
@end
