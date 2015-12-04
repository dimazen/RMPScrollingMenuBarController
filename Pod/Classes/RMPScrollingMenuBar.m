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

#import "RMPScrollingMenuBar.h"

@interface RMPScrollingMenuBarScrollView : UIScrollView

@end

@implementation RMPScrollingMenuBarScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view) {
        return view;
    }

    for (UIView *v in self.subviews) {
        CGPoint convertedPoint = [self convertPoint:point toView:v];
        if (CGRectContainsPoint(v.bounds, convertedPoint)) {
            view = v;
            break;
        }
    }
    return view;
}

@end

@interface RMPScrollingMenuBar () <UIScrollViewDelegate>

@end

@implementation RMPScrollingMenuBar {
    RMPScrollingMenuBarScrollView *_scrollView;
    UIView *_indicatorView;
    UIView *_border;

    CGFloat _indicatorHeight;

    NSMutableArray <RMPScrollingMenuBarButton *>*_views;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled) return nil;

    // Expands ScrollView's tachable area
    UIView *view = [_scrollView hitTest:[self convertPoint:point toView:_scrollView] withEvent:event];
    if (!view && CGRectContainsPoint(self.bounds, point)) {
        view = _scrollView;
    }
    return view;
}

#pragma mark -

- (void)setup {
    _showsIndicator = YES;
    _showsSeparatorLine = YES;
    _indicatorHeight = 4;
    _itemInsets = UIEdgeInsetsMake(2.f, 10.f, 0, 10.f);
    _indicatorColor = [UIColor colorWithRed:0.988 green:0.224 blue:0.129 alpha:1.0];

    _itemsFont = [UIFont systemFontOfSize:16.f];
    _itemsDefaultColor = [UIColor colorWithRed:0.647 green:0.631 blue:0.604 alpha:1.000];
    _itemsSelectedColor = [UIColor colorWithRed:0.988 green:0.224 blue:0.129 alpha:1.000];

    _views = [[NSMutableArray alloc] init];

    RMPScrollingMenuBarScrollView *scrollView = [[RMPScrollingMenuBarScrollView alloc] initWithFrame:self.bounds];
    _scrollView = scrollView;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.contentOffset = CGPointZero;
    _scrollView.scrollsToTop = NO;
    _scrollView.pagingEnabled = NO;
    _scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    _scrollView.clipsToBounds = YES;
    _scrollView.backgroundColor = [UIColor clearColor];

    [self addSubview:_scrollView];

    UIView *indicator = [[UIView alloc] init];
    _indicatorView = indicator;
    _indicatorView.backgroundColor = self.indicatorColor;
    [_scrollView addSubview:_indicatorView];

    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 0.25f, self.bounds.size.width, 0.25f)];
    _border = border;
    _border.backgroundColor = [UIColor colorWithWhite:0.698 alpha:1.000];
    [self addSubview:_border];
}

- (void)setStyle:(RMPScrollingMenuBarStyle)style {
    _style = style;
    if (_items.count > 0) {
        [self setItems:_items animated:YES];
    }
}

#pragma mark - Reload

- (void)reloadItems {
    [_views makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_views removeAllObjects];

    if (_items.count == 0) {
        return;
    }

    for (RMPScrollingMenuBarItem *item in _items) {
        RMPScrollingMenuBarButton *view = [self newViewForItem:item];

        [_scrollView addSubview:view];
        [_views addObject:view];
    }

    [self layoutIfNeeded];
}

#pragma mark - Items

- (void)setItems:(NSArray *)items {
    [self setItems:items animated:NO];
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated {
    _selectedIndex = 0;
    _items = [items copy];

    [self reloadItems];
}

- (void)layoutItemsViews {
    const CGFloat viewHeight = _scrollView.bounds.size.height - _itemInsets.top + _itemInsets.bottom;
    __block CGFloat offset = _itemInsets.left;
    [_views enumerateObjectsUsingBlock:^(RMPScrollingMenuBarButton *view, NSUInteger idx, BOOL *_) {
        RMPScrollingMenuBarItem *item = _items[idx];
        CGRect frame = CGRectMake(
            offset,
            _itemInsets.top,
            [self contentWidthForItem:item view:view fittingHeight:viewHeight],
            viewHeight
        );
        view.frame = frame;
        offset += frame.size.width + _itemInsets.right + _itemInsets.left;
    }];

    CGFloat contentWidth = offset - _itemInsets.left;
    if (contentWidth < _scrollView.bounds.size.width) {
        CGFloat delta = _scrollView.bounds.size.width - contentWidth;
        CGFloat space = floorf(delta / (_views.count + 1));

        [_views enumerateObjectsUsingBlock:^(UIButton *view, NSUInteger idx, BOOL *stop) {
            CGRect frame = CGRectOffset(view.frame, (idx + 1) * space, 0.f);
            view.frame = frame;
        }];

        contentWidth = _scrollView.bounds.size.width;
    }

    const CGFloat contentHeight = _scrollView.bounds.size.height;
    _scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _scrollView.frame = self.bounds;
    _scrollView.contentInset = UIEdgeInsetsZero;

    CGFloat lineWidth = 1.0f / [[UIScreen mainScreen] scale];
    _border.frame = CGRectMake(0, self.bounds.size.height - lineWidth, self.bounds.size.width, lineWidth);

    CGRect indicatorFrame = _indicatorView.frame;
    indicatorFrame.origin.y = self.bounds.size.height - _indicatorHeight;
    indicatorFrame.size.height = _indicatorHeight;
    _indicatorView.frame = indicatorFrame;

    [self layoutItemsViews];

    if (self.items.count > 0) {
        [self layoutIndexSelection:self.selectedIndex animated:NO];
    }
}

- (CGFloat)scrollOffsetX {
    return _scrollView.contentOffset.x;
}

- (void)scrollByRatio:(CGFloat)ratio from:(CGFloat)from {
    if (_style == RMPScrollingMenuBarStyleNormal) {
        NSInteger index = self.selectedIndex;
        NSInteger ignoreCount = (NSInteger)(_scrollView.frame.size.width * 0.5 / (_scrollView.contentSize.width / _items.count));
        for (NSInteger i = 0; i < ignoreCount; i++) {
            if (index == i) {
                return;
            } else if (index == _items.count - 1 - i) {
                return;
            }
        }

        if (index == ignoreCount && ratio < 0.0) {
            return;
        } else if (index == _items.count - 1 - ignoreCount && ratio > 0.0) {
            return;
        }
    }

    _scrollView.contentOffset = CGPointMake(from + _scrollView.contentSize.width / _items.count * ratio, 0);
}

#pragma mark - Selection

- (RMPScrollingMenuBarItem *)selectedItem {
    if (self.items.count > 0) {
        return self.items[self.selectedIndex];
    }

    return nil;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (_selectedIndex == selectedIndex) { return; }

    [self deselectViewAtIndex:_selectedIndex];
    _selectedIndex = selectedIndex;
    [self selectViewAtIndex:_selectedIndex];

    [self layoutIndexSelection:_selectedIndex animated:animated];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:YES];
}

- (void)layoutIndexSelection:(NSInteger)index animated:(BOOL)animated {
    UIView *view = _views[index];
    // Selected item want to be displayed to center as possible.
    CGPoint offset = CGPointZero;
    CGPoint newPosition = CGPointZero;
    if (_style == RMPScrollingMenuBarStyleNormal) {
        if (view.center.x > _scrollView.bounds.size.width * 0.5
            && (NSInteger) (_scrollView.contentSize.width - view.center.x) >= (NSInteger) (_scrollView.bounds.size.width * 0.5)) {
            offset = CGPointMake(view.center.x - _scrollView.frame.size.width * 0.5, 0);
        } else if (view.center.x < _scrollView.bounds.size.width * 0.5) {
            offset = CGPointMake(0, 0);
        } else if ((NSInteger) (_scrollView.contentSize.width - view.center.x) < (NSInteger) (_scrollView.bounds.size.width * 0.5)) {
            offset = CGPointMake(_scrollView.contentSize.width - _scrollView.bounds.size.width, 0);
        }
        [_scrollView setContentOffset:offset animated:animated];

        newPosition = [_scrollView convertPoint:CGPointZero fromView:view];
    }

    if (_indicatorView.frame.origin.x == 0.0 && _indicatorView.frame.size.width == 0.0) {
        CGRect f = _indicatorView.frame;
        f.origin.x = newPosition.x - 3;
        f.size.width = view.frame.size.width + 6;
        _indicatorView.frame = f;
    } else if (_style == RMPScrollingMenuBarStyleNormal) {
        NSTimeInterval dur = fabs(newPosition.x - _indicatorView.frame.origin.x) / 160.0 * 0.4 * 0.8;
        if (dur < 0.38) {
            dur = 0.38;
        } else if (dur > 0.6) {
            dur = 0.6;
        }

        void (^adjust)(void) = ^{
            CGRect f = _indicatorView.frame;
            f.origin.x = newPosition.x - 3;
            f.size.width = view.frame.size.width + 6;
            _indicatorView.frame = f;
        };

        if (animated) {
            UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut;
            [UIView animateWithDuration:dur
                                  delay:0.16
                 usingSpringWithDamping:0.8
                  initialSpringVelocity:0.1
                                options:options
                             animations:adjust
                             completion:NULL];
        } else {
            adjust();
        }
    }
}

- (void)selectViewAtIndex:(NSInteger)index {
    UIButton *view = _views[index];
    view.selected = YES;
}

- (void)deselectViewAtIndex:(NSInteger)index {
    UIButton *view = _views[index];
    view.selected = NO;
}

#pragma mark - Settings

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    if (_indicatorView) {
        _indicatorView.backgroundColor = _indicatorColor;
    }
}

- (void)setShowsIndicator:(BOOL)showsIndicator {
    _showsIndicator = showsIndicator;
    _indicatorView.hidden = !_showsIndicator;
}

- (void)setShowsSeparatorLine:(BOOL)showsSeparatorLine {
    _showsSeparatorLine = showsSeparatorLine;
    _border.hidden = !_showsSeparatorLine;
}

- (void)setItemsFont:(UIFont *)itemsFont {
    _itemsFont = itemsFont;

    [self updateViewsAppearance];
}

- (void)setItemsDefaultColor:(UIColor *)itemsDefaultColor {
    _itemsDefaultColor = itemsDefaultColor;

    [self updateViewsAppearance];
}

- (void)setItemsSelectedColor:(UIColor *)itemsSelectedColor {
    _itemsSelectedColor = itemsSelectedColor;

    [self updateViewsAppearance];
}

- (void)applyAppearanceToView:(RMPScrollingMenuBarButton *)view {
    view.titleLabel.font = self.itemsFont;
    [view setTitleColor:self.itemsDefaultColor forState:UIControlStateNormal];
    [view setTitleColor:self.itemsSelectedColor forState:UIControlStateSelected];
}

- (void)updateViewsAppearance {
    for (RMPScrollingMenuBarButton *view in _views) {
        [self applyAppearanceToView:view];
    }
}

#pragma mark - Views

- (RMPScrollingMenuBarButton *)newViewForItem:(RMPScrollingMenuBarItem *)item {
    RMPScrollingMenuBarButton *view = [[RMPScrollingMenuBarButton alloc] init];

    [self applyAppearanceToView:view];
    [view setTitle:item.title forState:UIControlStateNormal];
    view.exclusiveTouch = NO;

    [view addTarget:self action:@selector(didTapMenuButton:) forControlEvents:UIControlEventTouchUpInside];

    return view;
}

- (CGFloat)contentWidthForItem:(RMPScrollingMenuBarItem *)item view:(RMPScrollingMenuBarButton *)view fittingHeight:(CGFloat)height {
    if (item.width == RMPScrollingMenuBarItemWidthAutomatic) {
        [view setNeedsLayout];
        [view layoutIfNeeded];
        CGSize fittingSize = [view systemLayoutSizeFittingSize:CGSizeMake(UILayoutFittingCompressedSize.height, height)
                                 withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
                                       verticalFittingPriority:UILayoutPriorityRequired];
        return fittingSize.width;
    }

    return item.width;
}

#pragma mark - Selection Handling

- (void)didTapMenuButton:(UIButton *)sender {
    NSInteger index = [_views indexOfObject:sender];
    if (index != NSNotFound) {
        [self setSelectedIndex:index animated:YES];

        if ([_delegate respondsToSelector:@selector(menuBar:didSelectItem:direction:)]) {
            [_delegate menuBar:self didSelectItem:self.selectedItem direction:RMPScrollingMenuBarDirectionNone];
        }
    }
}

@end
