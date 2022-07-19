import Foundation
import SwiftSignalKit
import UIKit
import Display
import ComponentFlow
import PagerComponent
import TelegramPresentationData
import TelegramCore
import Postbox
import AnimationCache
import MultiAnimationRenderer
import AccountContext
import MultilineTextComponent
import LottieAnimationComponent

final class EntityKeyboardAnimationTopPanelComponent: Component {
    typealias EnvironmentType = EntityKeyboardTopPanelItemEnvironment
    
    let context: AccountContext
    let file: TelegramMediaFile
    let isFeatured: Bool
    let isPremiumLocked: Bool
    let animationCache: AnimationCache
    let animationRenderer: MultiAnimationRenderer
    let theme: PresentationTheme
    let title: String
    let pressed: () -> Void
    
    init(
        context: AccountContext,
        file: TelegramMediaFile,
        isFeatured: Bool,
        isPremiumLocked: Bool,
        animationCache: AnimationCache,
        animationRenderer: MultiAnimationRenderer,
        theme: PresentationTheme,
        title: String,
        pressed: @escaping () -> Void
    ) {
        self.context = context
        self.file = file
        self.isFeatured = isFeatured
        self.isPremiumLocked = isPremiumLocked
        self.animationCache = animationCache
        self.animationRenderer = animationRenderer
        self.theme = theme
        self.title = title
        self.pressed = pressed
    }
    
    static func ==(lhs: EntityKeyboardAnimationTopPanelComponent, rhs: EntityKeyboardAnimationTopPanelComponent) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.file.fileId != rhs.file.fileId {
            return false
        }
        if lhs.isFeatured != rhs.isFeatured {
            return false
        }
        if lhs.isPremiumLocked != rhs.isPremiumLocked {
            return false
        }
        if lhs.animationCache !== rhs.animationCache {
            return false
        }
        if lhs.animationRenderer !== rhs.animationRenderer {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        
        return true
    }
    
    final class View: UIView {
        var itemLayer: EmojiPagerContentComponent.View.ItemLayer?
        var placeholderView: EmojiPagerContentComponent.View.ItemPlaceholderView?
        var component: EntityKeyboardAnimationTopPanelComponent?
        var titleView: ComponentView<Empty>?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
            if case .ended = recognizer.state {
                self.component?.pressed()
            }
        }
        
        func update(component: EntityKeyboardAnimationTopPanelComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
            self.component = component
            
            let itemEnvironment = environment[EntityKeyboardTopPanelItemEnvironment.self].value
            
            if self.itemLayer == nil {
                let itemLayer = EmojiPagerContentComponent.View.ItemLayer(
                    item: EmojiPagerContentComponent.Item(
                        file: component.file,
                        staticEmoji: nil,
                        subgroupId: nil
                    ),
                    context: component.context,
                    attemptSynchronousLoad: false,
                    file: component.file,
                    staticEmoji: nil,
                    cache: component.animationCache,
                    renderer: component.animationRenderer,
                    placeholderColor: .lightGray,
                    blurredBadgeColor: .clear,
                    pointSize: CGSize(width: 44.0, height: 44.0),
                    onUpdateDisplayPlaceholder: { [weak self] displayPlaceholder, duration in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.updateDisplayPlaceholder(displayPlaceholder: displayPlaceholder, duration: duration)
                    }
                )
                self.itemLayer = itemLayer
                self.layer.addSublayer(itemLayer)
                
                if itemLayer.displayPlaceholder {
                    self.updateDisplayPlaceholder(displayPlaceholder: true, duration: 0.0)
                }
            }
            
            let iconSize: CGSize = itemEnvironment.isExpanded ? CGSize(width: 44.0, height: 44.0) : CGSize(width: 28.0, height: 28.0)
            let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) / 2.0), y: 0.0), size: iconSize)
            
            if let itemLayer = self.itemLayer {
                transition.setPosition(layer: itemLayer, position: CGPoint(x: iconFrame.midX, y: iconFrame.midY))
                transition.setBounds(layer: itemLayer, bounds: CGRect(origin: CGPoint(), size: iconFrame.size))
                
                var badge: EmojiPagerContentComponent.View.ItemLayer.Badge?
                if component.isPremiumLocked {
                    badge = .locked
                } else if component.isFeatured {
                    badge = .featured
                }
                itemLayer.update(transition: transition, size: iconFrame.size, badge: badge, blurredBadgeColor: UIColor(white: 0.0, alpha: 0.1), blurredBadgeBackgroundColor: component.theme.list.plainBackgroundColor)
                
                itemLayer.isVisibleForAnimations = true
            }
            
            if itemEnvironment.isExpanded {
                let titleView: ComponentView<Empty>
                if let current = self.titleView {
                    titleView = current
                } else {
                    titleView = ComponentView<Empty>()
                    self.titleView = titleView
                }
                let titleSize = titleView.update(
                    transition: .immediate,
                    component: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(string: component.title, font: Font.regular(10.0), textColor: component.theme.chat.inputPanel.primaryTextColor)),
                        insets: UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
                    )),
                    environment: {},
                    containerSize: CGSize(width: 62.0, height: 100.0)
                )
                if let view = titleView.view {
                    if view.superview == nil {
                        view.alpha = 0.0
                        self.addSubview(view)
                    }
                    view.frame = CGRect(origin: CGPoint(x: floor((availableSize.width - titleSize.width) / 2.0), y: availableSize.height - titleSize.height - 1.0), size: titleSize)
                    transition.setAlpha(view: view, alpha: 1.0)
                }
            } else if let titleView = self.titleView {
                self.titleView = nil
                if let view = titleView.view {
                    transition.setAlpha(view: view, alpha: 0.0, completion: { [weak view] _ in
                        view?.removeFromSuperview()
                    })
                }
            }
            
            return availableSize
        }
        
        private func updateDisplayPlaceholder(displayPlaceholder: Bool, duration: Double) {
            if displayPlaceholder {
                if self.placeholderView == nil, let component = self.component {
                    let placeholderView = EmojiPagerContentComponent.View.ItemPlaceholderView(
                        context: component.context,
                        file: component.file,
                        shimmerView: nil,
                        color: component.theme.chat.inputPanel.primaryTextColor.withMultipliedAlpha(0.08),
                        size: CGSize(width: 28.0, height: 28.0)
                    )
                    self.placeholderView = placeholderView
                    self.insertSubview(placeholderView, at: 0)
                    placeholderView.frame = CGRect(origin: CGPoint(), size: CGSize(width: 28.0, height: 28.0))
                    placeholderView.update(size: CGSize(width: 28.0, height: 28.0))
                }
            } else {
                if let placeholderView = self.placeholderView {
                    self.placeholderView = nil
                    
                    if duration > 0.0 {
                        placeholderView.alpha = 0.0
                        placeholderView.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration, completion: { [weak placeholderView] _ in
                            placeholderView?.removeFromSuperview()
                        })
                    } else {
                        placeholderView.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

final class EntityKeyboardIconTopPanelComponent: Component {
    typealias EnvironmentType = EntityKeyboardTopPanelItemEnvironment
    
    let imageName: String
    let theme: PresentationTheme
    let title: String
    let pressed: () -> Void
    
    init(
        imageName: String,
        theme: PresentationTheme,
        title: String,
        pressed: @escaping () -> Void
    ) {
        self.imageName = imageName
        self.theme = theme
        self.title = title
        self.pressed = pressed
    }
    
    static func ==(lhs: EntityKeyboardIconTopPanelComponent, rhs: EntityKeyboardIconTopPanelComponent) -> Bool {
        if lhs.imageName != rhs.imageName {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        
        return true
    }
    
    final class View: UIView {
        let iconView: UIImageView
        var component: EntityKeyboardIconTopPanelComponent?
        var titleView: ComponentView<Empty>?
        
        override init(frame: CGRect) {
            self.iconView = UIImageView()
            
            super.init(frame: frame)
            
            self.addSubview(self.iconView)
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
            if case .ended = recognizer.state {
                self.component?.pressed()
            }
        }
        
        func update(component: EntityKeyboardIconTopPanelComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
            let itemEnvironment = environment[EntityKeyboardTopPanelItemEnvironment.self].value
            
            if self.component?.imageName != component.imageName {
                self.iconView.image = generateTintedImage(image: UIImage(bundleImageName: component.imageName), color: component.theme.chat.inputMediaPanel.panelIconColor)
                
                if component.imageName.hasSuffix("PremiumIcon") {
                    self.iconView.image = generateImage(CGSize(width: 44.0, height: 42.0), contextGenerator: { size, context in
                        context.clear(CGRect(origin: CGPoint(), size: size))
                        if let image = UIImage(bundleImageName: "Peer Info/PremiumIcon") {
                            if let cgImage = image.cgImage {
                                context.clip(to: CGRect(origin: .zero, size: size), mask: cgImage)
                            }
                            
                            let colorsArray: [CGColor] = [
                                UIColor(rgb: 0x6B93FF).cgColor,
                                UIColor(rgb: 0x6B93FF).cgColor,
                                UIColor(rgb: 0x976FFF).cgColor,
                                UIColor(rgb: 0xE46ACE).cgColor,
                                UIColor(rgb: 0xE46ACE).cgColor
                            ]
                            var locations: [CGFloat] = [0.0, 0.35, 0.5, 0.65, 1.0]
                            let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: colorsArray as CFArray, locations: &locations)!

                            context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: CGGradientDrawingOptions())
                        }
                    })
                }
            }
                
            self.component = component
            
            let nativeIconSize: CGSize = itemEnvironment.isExpanded ? CGSize(width: 44.0, height: 44.0) : CGSize(width: 28.0, height: 28.0)
            let boundingIconSize: CGSize = itemEnvironment.isExpanded ? CGSize(width: 38.0, height: 38.0) : CGSize(width: 28.0, height: 28.0)
            
            let iconSize = (self.iconView.image?.size ?? nativeIconSize).aspectFitted(boundingIconSize)
            let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) / 2.0), y: floor((nativeIconSize.height - iconSize.height) / 2.0)), size: iconSize)
            
            transition.setFrame(view: self.iconView, frame: iconFrame)
            
            if itemEnvironment.isExpanded {
                let titleView: ComponentView<Empty>
                if let current = self.titleView {
                    titleView = current
                } else {
                    titleView = ComponentView<Empty>()
                    self.titleView = titleView
                }
                let titleSize = titleView.update(
                    transition: .immediate,
                    component: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(string: component.title, font: Font.regular(10.0), textColor: component.theme.chat.inputPanel.primaryTextColor)),
                        insets: UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
                    )),
                    environment: {},
                    containerSize: CGSize(width: 62.0, height: 100.0)
                )
                if let view = titleView.view {
                    if view.superview == nil {
                        view.alpha = 0.0
                        self.addSubview(view)
                    }
                    view.frame = CGRect(origin: CGPoint(x: floor((availableSize.width - titleSize.width) / 2.0), y: availableSize.height - titleSize.height - 1.0), size: titleSize)
                    transition.setAlpha(view: view, alpha: 1.0)
                }
            } else if let titleView = self.titleView {
                self.titleView = nil
                if let view = titleView.view {
                    transition.setAlpha(view: view, alpha: 0.0, completion: { [weak view] _ in
                        view?.removeFromSuperview()
                    })
                }
            }
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

final class EntityKeyboardStaticStickersPanelComponent: Component {
    typealias EnvironmentType = EntityKeyboardTopPanelItemEnvironment
    
    let theme: PresentationTheme
    let title: String
    let pressed: (EmojiPagerContentComponent.StaticEmojiSegment) -> Void
    
    init(
        theme: PresentationTheme,
        title: String,
        pressed: @escaping (EmojiPagerContentComponent.StaticEmojiSegment) -> Void
    ) {
        self.theme = theme
        self.title = title
        self.pressed = pressed
    }
    
    static func ==(lhs: EntityKeyboardStaticStickersPanelComponent, rhs: EntityKeyboardStaticStickersPanelComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        
        return true
    }
    
    final class View: UIView, UIScrollViewDelegate {
        private let scrollViewContainer: UIView
        private let scrollView: UIScrollView
        private var visibleItemViews: [EmojiPagerContentComponent.StaticEmojiSegment: ComponentView<Empty>] = [:]
        
        private var titleView: ComponentView<Empty>?
        
        private var component: EntityKeyboardStaticStickersPanelComponent?
        private var itemEnvironment: EntityKeyboardTopPanelItemEnvironment?
        
        private var ignoreScrolling: Bool = false
        
        override init(frame: CGRect) {
            self.scrollViewContainer = UIView()
            self.scrollViewContainer.clipsToBounds = true
            
            self.scrollView = UIScrollView()
            
            super.init(frame: frame)
            
            self.scrollView.layer.anchorPoint = CGPoint()
            self.scrollView.delaysContentTouches = false
            self.scrollView.clipsToBounds = false
            if #available(iOSApplicationExtension 11.0, iOS 11.0, *) {
                self.scrollView.contentInsetAdjustmentBehavior = .never
            }
            if #available(iOS 13.0, *) {
                self.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.alwaysBounceHorizontal = false
            self.scrollView.delegate = self
            
            self.scrollViewContainer.addSubview(self.scrollView)
            self.addSubview(self.scrollViewContainer)
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
            if case .ended = recognizer.state {
                let scrollViewLocation = recognizer.location(in: self.scrollView)
                for (id, itemView) in self.visibleItemViews {
                    if let view = itemView.view, view.frame.insetBy(dx: -4.0, dy: -4.0).contains(scrollViewLocation) {
                        self.component?.pressed(id)
                        break
                    }
                }
            }
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if self.ignoreScrolling {
                return
            }
            self.updateVisibleItems(transition: .immediate, animateAppearingItems: true)
        }
        
        private func updateVisibleItems(transition: Transition, animateAppearingItems: Bool) {
            guard let component = self.component, let itemEnvironment = self.itemEnvironment else {
                return
            }
            
            var validItemIds = Set<EmojiPagerContentComponent.StaticEmojiSegment>()
            let visibleBounds = self.scrollView.bounds
            
            let componentHeight: CGFloat = self.scrollView.contentSize.height
            
            let isExpanded = componentHeight > 32.0
            
            let items = EmojiPagerContentComponent.StaticEmojiSegment.allCases
            let itemSize: CGFloat = isExpanded ? 42.0 : 32.0
            let itemSpacing: CGFloat = 4.0
            let sideInset: CGFloat = isExpanded ? 5.0 : 2.0
            let itemOffset: CGFloat = isExpanded ? -8.0 : 0.0
            for i in 0 ..< items.count {
                let itemFrame = CGRect(origin: CGPoint(x: sideInset + CGFloat(i) * (itemSize + itemSpacing), y: floor(componentHeight - itemSize) / 2.0 + itemOffset), size: CGSize(width: itemSize, height: itemSize))
                if visibleBounds.intersects(itemFrame) {
                    let item = items[i]
                    validItemIds.insert(item)
                    
                    var animateItem = false
                    var itemTransition = transition
                    let itemView: ComponentView<Empty>
                    if let current = self.visibleItemViews[item] {
                        itemView = current
                    } else {
                        animateItem = animateAppearingItems
                        itemTransition = .immediate
                        itemView = ComponentView<Empty>()
                        self.visibleItemViews[item] = itemView
                    }
                    
                    let animationName: String
                    switch item {
                    case .people:
                        animationName = "emojicat_smiles"
                    case .animalsAndNature:
                        animationName = "emojicat_animals"
                    case .foodAndDrink:
                        animationName = "emojicat_food"
                    case .activityAndSport:
                        animationName = "emojicat_activity"
                    case .travelAndPlaces:
                        animationName = "emojicat_places"
                    case .objects:
                        animationName = "emojicat_objects"
                    case .symbols:
                        animationName = "emojicat_symbols"
                    case .flags:
                        animationName = "emojicat_flags"
                    }
                    
                    let color: UIColor
                    if itemEnvironment.highlightedSubgroupId == AnyHashable(items[i].rawValue) {
                        color = component.theme.chat.inputMediaPanel.panelIconColor.mixedWith(component.theme.chat.inputPanel.primaryTextColor, alpha: 0.35)
                    } else {
                        color = component.theme.chat.inputMediaPanel.panelIconColor
                    }
                    
                    let _ = itemView.update(
                        transition: itemTransition,
                        component: AnyComponent(LottieAnimationComponent(
                            animation: LottieAnimationComponent.AnimationItem(
                                name: animationName,
                                mode: animateItem ? .animating(loop: false) : .still(position: .end)
                            ),
                            colors: ["__allcolors__": color],
                            size: CGSize(width: itemSize, height: itemSize)
                        )),
                        environment: {},
                        containerSize: CGSize(width: itemSize, height: itemSize)
                    )
                    if let view = itemView.view {
                        if view.superview == nil {
                            self.scrollView.addSubview(view)
                        }
                        itemTransition.setFrame(view: view, frame: itemFrame)
                    }
                }
            }
            
            var removedItemIds: [EmojiPagerContentComponent.StaticEmojiSegment] = []
            for (id, itemView) in self.visibleItemViews {
                if !validItemIds.contains(id) {
                    removedItemIds.append(id)
                    itemView.view?.removeFromSuperview()
                }
            }
            for id in removedItemIds {
                self.visibleItemViews.removeValue(forKey: id)
            }
        }
        
        func update(component: EntityKeyboardStaticStickersPanelComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
            transition.setFrame(view: self.scrollViewContainer, frame: CGRect(origin: CGPoint(), size: availableSize))
            transition.setCornerRadius(layer: self.scrollViewContainer.layer, cornerRadius: min(availableSize.width / 2.0, availableSize.height / 2.0))
            
            let itemEnvironment = environment[EntityKeyboardTopPanelItemEnvironment.self].value
            
            var scrollToItem: AnyHashable?
            if itemEnvironment.highlightedSubgroupId != self.itemEnvironment?.highlightedSubgroupId {
                scrollToItem = itemEnvironment.highlightedSubgroupId
            }
            
            self.component = component
            self.itemEnvironment = itemEnvironment
            
            let isExpanded = itemEnvironment.isExpanded
            let itemSize: CGFloat = isExpanded ? 42.0 : 32.0
            let itemSpacing: CGFloat = 4.0
            let sideInset: CGFloat = isExpanded ? 5.0 : 2.0
            let itemCount = EmojiPagerContentComponent.StaticEmojiSegment.allCases.count
            
            self.ignoreScrolling = true
            self.scrollView.frame = CGRect(origin: CGPoint(), size: CGSize(width: max(availableSize.width, 160.0), height: availableSize.height))
            self.scrollView.contentSize = CGSize(width: sideInset * 2.0 + itemSize * CGFloat(itemCount) + itemSpacing * CGFloat(itemCount - 1), height: availableSize.height)
            self.ignoreScrolling = false
            
            self.updateVisibleItems(transition: transition, animateAppearingItems: false)
            
            if (!itemEnvironment.isHighlighted || isExpanded) && self.scrollView.contentOffset.x != 0.0 {
                self.scrollView.setContentOffset(CGPoint(), animated: true)
                scrollToItem = nil
            }
            
            if let scrollToItem = scrollToItem {
                let items = EmojiPagerContentComponent.StaticEmojiSegment.allCases
                for i in 0 ..< items.count {
                    if AnyHashable(items[i].rawValue) == scrollToItem {
                        let itemFrame = CGRect(origin: CGPoint(x: sideInset + CGFloat(i) * (itemSize + itemSpacing), y: 0.0), size: CGSize(width: itemSize, height: itemSize))
                        self.scrollView.scrollRectToVisible(itemFrame.insetBy(dx: -sideInset, dy: 0.0), animated: true)
                        break
                    }
                }
            }
            
            if itemEnvironment.isExpanded {
                let titleView: ComponentView<Empty>
                if let current = self.titleView {
                    titleView = current
                } else {
                    titleView = ComponentView<Empty>()
                    self.titleView = titleView
                }
                let titleSize = titleView.update(
                    transition: .immediate,
                    component: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(string: component.title, font: Font.regular(10.0), textColor: component.theme.chat.inputPanel.primaryTextColor)),
                        insets: UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
                    )),
                    environment: {},
                    containerSize: CGSize(width: 62.0, height: 100.0)
                )
                if let view = titleView.view {
                    if view.superview == nil {
                        view.alpha = 0.0
                        self.addSubview(view)
                    }
                    view.frame = CGRect(origin: CGPoint(x: floor((availableSize.width - titleSize.width) / 2.0), y: availableSize.height - titleSize.height - 4.0), size: titleSize)
                    transition.setAlpha(view: view, alpha: 1.0)
                }
            } else if let titleView = self.titleView {
                self.titleView = nil
                if let view = titleView.view {
                    transition.setAlpha(view: view, alpha: 0.0, completion: { [weak view] _ in
                        view?.removeFromSuperview()
                    })
                }
            }
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

final class EntityKeyboardTopPanelItemEnvironment: Equatable {
    let isExpanded: Bool
    let isHighlighted: Bool
    let highlightedSubgroupId: AnyHashable?
    
    init(isExpanded: Bool, isHighlighted: Bool, highlightedSubgroupId: AnyHashable?) {
        self.isExpanded = isExpanded
        self.isHighlighted = isHighlighted
        self.highlightedSubgroupId = highlightedSubgroupId
    }
    
    static func ==(lhs: EntityKeyboardTopPanelItemEnvironment, rhs: EntityKeyboardTopPanelItemEnvironment) -> Bool {
        if lhs.isExpanded != rhs.isExpanded {
            return false
        }
        if lhs.isHighlighted != rhs.isHighlighted {
            return false
        }
        if lhs.highlightedSubgroupId != rhs.highlightedSubgroupId {
            return false
        }
        return true
    }
}

private final class ReorderGestureRecognizer: UIGestureRecognizer {
    private let shouldBegin: (CGPoint) -> (allowed: Bool, requiresLongPress: Bool, itemView: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>?)
    private let willBegin: (CGPoint) -> Void
    private let began: (ComponentHostView<EntityKeyboardTopPanelItemEnvironment>) -> Void
    private let ended: () -> Void
    private let moved: (CGFloat) -> Void
    private let isActiveUpdated: (Bool) -> Void
    
    private var initialLocation: CGPoint?
    private var longTapTimer: SwiftSignalKit.Timer?
    private var longPressTimer: SwiftSignalKit.Timer?
    
    private var itemView: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>?
    
    public init(shouldBegin: @escaping (CGPoint) -> (allowed: Bool, requiresLongPress: Bool, itemView: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>?), willBegin: @escaping (CGPoint) -> Void, began: @escaping (ComponentHostView<EntityKeyboardTopPanelItemEnvironment>) -> Void, ended: @escaping () -> Void, moved: @escaping (CGFloat) -> Void, isActiveUpdated: @escaping (Bool) -> Void) {
        self.shouldBegin = shouldBegin
        self.willBegin = willBegin
        self.began = began
        self.ended = ended
        self.moved = moved
        self.isActiveUpdated = isActiveUpdated
        
        super.init(target: nil, action: nil)
    }
    
    deinit {
        self.longTapTimer?.invalidate()
        self.longPressTimer?.invalidate()
    }
    
    private func startLongTapTimer() {
        self.longTapTimer?.invalidate()
        let longTapTimer = SwiftSignalKit.Timer(timeout: 0.25, repeat: false, completion: { [weak self] in
            self?.longTapTimerFired()
        }, queue: Queue.mainQueue())
        self.longTapTimer = longTapTimer
        longTapTimer.start()
    }
    
    private func stopLongTapTimer() {
        self.itemView = nil
        self.longTapTimer?.invalidate()
        self.longTapTimer = nil
    }
    
    private func startLongPressTimer() {
        self.longPressTimer?.invalidate()
        let longPressTimer = SwiftSignalKit.Timer(timeout: 0.6, repeat: false, completion: { [weak self] in
            self?.longPressTimerFired()
        }, queue: Queue.mainQueue())
        self.longPressTimer = longPressTimer
        longPressTimer.start()
    }
    
    private func stopLongPressTimer() {
        self.itemView = nil
        self.longPressTimer?.invalidate()
        self.longPressTimer = nil
    }
    
    override public func reset() {
        super.reset()
        
        self.itemView = nil
        self.stopLongTapTimer()
        self.stopLongPressTimer()
        self.initialLocation = nil
        
        self.isActiveUpdated(false)
    }
    
    private func longTapTimerFired() {
        guard let location = self.initialLocation else {
            return
        }
        
        self.longTapTimer?.invalidate()
        self.longTapTimer = nil
        
        self.willBegin(location)
    }
    
    private func longPressTimerFired() {
        guard let _ = self.initialLocation else {
            return
        }
        
        self.isActiveUpdated(true)
        self.state = .began
        self.longPressTimer?.invalidate()
        self.longPressTimer = nil
        self.longTapTimer?.invalidate()
        self.longTapTimer = nil
        if let itemView = self.itemView {
            self.began(itemView)
        }
        self.isActiveUpdated(true)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        if self.numberOfTouches > 1 {
            self.isActiveUpdated(false)
            self.state = .failed
            self.ended()
            return
        }
        
        if self.state == .possible {
            if let location = touches.first?.location(in: self.view) {
                let (allowed, requiresLongPress, itemView) = self.shouldBegin(location)
                if allowed {
                    self.isActiveUpdated(true)
                    
                    self.itemView = itemView
                    self.initialLocation = location
                    if requiresLongPress {
                        self.startLongTapTimer()
                        self.startLongPressTimer()
                    } else {
                        self.state = .began
                        if let itemView = self.itemView {
                            self.began(itemView)
                        }
                    }
                } else {
                    self.isActiveUpdated(false)
                    self.state = .failed
                }
            } else {
                self.isActiveUpdated(false)
                self.state = .failed
            }
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        self.initialLocation = nil
        
        self.stopLongTapTimer()
        if self.longPressTimer != nil {
            self.stopLongPressTimer()
            self.isActiveUpdated(false)
            self.state = .failed
        }
        if self.state == .began || self.state == .changed {
            self.isActiveUpdated(false)
            self.ended()
            self.state = .failed
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        
        self.initialLocation = nil
        
        self.stopLongTapTimer()
        if self.longPressTimer != nil {
            self.isActiveUpdated(false)
            self.stopLongPressTimer()
            self.state = .failed
        }
        if self.state == .began || self.state == .changed {
            self.isActiveUpdated(false)
            self.ended()
            self.state = .failed
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if (self.state == .began || self.state == .changed), let initialLocation = self.initialLocation, let location = touches.first?.location(in: self.view) {
            self.state = .changed
            let offset = location.x - initialLocation.x
            self.moved(offset)
        } else if let touch = touches.first, let initialTapLocation = self.initialLocation, self.longPressTimer != nil {
            let touchLocation = touch.location(in: self.view)
            let dX = touchLocation.x - initialTapLocation.x
            let dY = touchLocation.y - initialTapLocation.y
            
            if dX * dX + dY * dY > 3.0 * 3.0 {
                self.stopLongTapTimer()
                self.stopLongPressTimer()
                self.initialLocation = nil
                self.isActiveUpdated(false)
                self.state = .failed
            }
        }
    }
}

final class EntityKeyboardTopPanelComponent: Component {
    typealias EnvironmentType = EntityKeyboardTopContainerPanelEnvironment
    
    final class Item: Equatable {
        let id: AnyHashable
        let isReorderable: Bool
        let content: AnyComponent<EntityKeyboardTopPanelItemEnvironment>
        
        init(id: AnyHashable, isReorderable: Bool, content: AnyComponent<EntityKeyboardTopPanelItemEnvironment>) {
            self.id = id
            self.isReorderable = isReorderable
            self.content = content
        }
        
        static func ==(lhs: Item, rhs: Item) -> Bool {
            if lhs.id != rhs.id {
                return false
            }
            if lhs.isReorderable != rhs.isReorderable {
                return false
            }
            if lhs.content != rhs.content {
                return false
            }
            
            return true
        }
    }
    
    let theme: PresentationTheme
    let items: [Item]
    let defaultActiveItemId: AnyHashable?
    let activeContentItemIdUpdated: ActionSlot<(AnyHashable, AnyHashable?, Transition)>
    let reorderItems: ([Item]) -> Void
    
    init(
        theme: PresentationTheme,
        items: [Item],
        defaultActiveItemId: AnyHashable? = nil,
        activeContentItemIdUpdated: ActionSlot<(AnyHashable, AnyHashable?, Transition)>,
        reorderItems: @escaping ([Item]) -> Void
    ) {
        self.theme = theme
        self.items = items
        self.defaultActiveItemId = defaultActiveItemId
        self.activeContentItemIdUpdated = activeContentItemIdUpdated
        self.reorderItems = reorderItems
    }
    
    static func ==(lhs: EntityKeyboardTopPanelComponent, rhs: EntityKeyboardTopPanelComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        if lhs.defaultActiveItemId != rhs.defaultActiveItemId {
            return false
        }
        if lhs.activeContentItemIdUpdated !== rhs.activeContentItemIdUpdated {
            return false
        }
        
        return true
    }
    
    final class View: UIView, UIScrollViewDelegate {
        private struct ItemLayout {
            struct ItemDescription {
                var isStatic: Bool
                var isStaticExpanded: Bool
            }
            
            struct Item {
                var frame: CGRect
                var innerFrame: CGRect
            }
            
            let sideInset: CGFloat = 7.0
            let itemSize: CGSize
            let staticItemSize: CGSize
            let staticExpandedItemSize: CGSize
            let innerItemSize: CGSize
            let itemSpacing: CGFloat = 15.0
            let contentSize: CGSize
            let isExpanded: Bool
            let items: [Item]
            
            init(isExpanded: Bool, height: CGFloat, items: [ItemDescription]) {
                self.isExpanded = isExpanded
                self.itemSize = self.isExpanded ? CGSize(width: 54.0, height: 68.0) : CGSize(width: 32.0, height: 32.0)
                self.staticItemSize = self.itemSize
                self.staticExpandedItemSize = self.isExpanded ? self.staticItemSize : CGSize(width: 160.0, height: 32.0)
                self.innerItemSize = self.isExpanded ? CGSize(width: 50.0, height: 62.0) : CGSize(width: 28.0, height: 28.0)
                
                var contentSize = CGSize(width: sideInset, height: height)
                var resultItems: [Item] = []
                
                var isFirst = true
                let itemY = floor((contentSize.height - self.itemSize.height) / 2.0)
                for item in items {
                    if isFirst {
                        isFirst = false
                    } else {
                        contentSize.width += itemSpacing
                    }
                    let currentItemSize: CGSize
                    if item.isStaticExpanded {
                        currentItemSize = self.staticExpandedItemSize
                    } else if item.isStatic {
                        currentItemSize = self.staticItemSize
                    } else {
                        currentItemSize = self.itemSize
                    }
                    let frame = CGRect(origin: CGPoint(x: contentSize.width, y: itemY), size: currentItemSize)
                    
                    var innerFrame = frame
                    if item.isStaticExpanded {
                    } else if item.isStatic {
                    } else {
                        innerFrame.origin.x += floor((self.itemSize.width - self.innerItemSize.width)) / 2.0
                        innerFrame.origin.y += floor((self.itemSize.height - self.innerItemSize.height)) / 2.0
                        innerFrame.size = self.innerItemSize
                    }
                    
                    resultItems.append(Item(
                        frame: frame,
                        innerFrame: innerFrame
                    ))
                    
                    contentSize.width += frame.width
                }
                
                contentSize.width += sideInset
                
                self.contentSize = contentSize
                self.items = resultItems
            }
            
            func containerFrame(at index: Int) -> CGRect {
                return self.items[index].frame
            }
            
            func contentFrame(index: Int, containerFrame: CGRect) -> CGRect {
                let outerFrame = self.items[index].frame
                let innerFrame = self.items[index].innerFrame
                
                let sizeDifference = CGSize(width: outerFrame.width - innerFrame.width, height: outerFrame.height - innerFrame.height)
                let offsetDifference = CGPoint(x: outerFrame.minX - innerFrame.minX, y: outerFrame.minY - innerFrame.minY)
                
                var frame = containerFrame
                frame.origin.x -= offsetDifference.x
                frame.origin.y -= offsetDifference.y
                frame.size.width -= sizeDifference.width
                frame.size.height -= sizeDifference.height
                
                return frame
            }
            
            func contentFrame(at index: Int) -> CGRect {
                return self.items[index].innerFrame
            }
            
            func visibleItemRange(for rect: CGRect) -> (minIndex: Int, maxIndex: Int) {
                for i in 0 ..< self.items.count {
                    if self.items[i].frame.intersects(rect) {
                        for j in i ..< self.items.count {
                            if !self.items[j].frame.intersects(rect) {
                                return (i, j - 1)
                            }
                        }
                        return (i, self.items.count - 1)
                    }
                }
                return (0, -1)
            }
        }
        
        private let scrollView: UIScrollView
        private var itemViews: [AnyHashable: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>] = [:]
        private var highlightedIconBackgroundView: UIView
        
        private var temporaryReorderingOrderIndex: (id: AnyHashable, index: Int)?
        
        private weak var currentReorderingItemView: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>?
        private var currentReorderingItemId: AnyHashable?
        private var currentReorderingItemContainerView: UIView?
        private var initialReorderingItemFrame: CGRect?
        private var currentReorderingScrollDisplayLink: ConstantDisplayLinkAnimator?
        private lazy var reorderingHapticFeedback: HapticFeedback = {
            return HapticFeedback()
        }()
        
        private var itemLayout: ItemLayout?
        private var items: [Item] = []
        private var ignoreScrolling: Bool = false
        
        private var isDragging: Bool = false
        private var isReordering: Bool = false
        private var isDraggingOrReordering: Bool = false
        private var draggingStoppedTimer: SwiftSignalKit.Timer?
        private var draggingFocusItemIndex: Int?
        private var draggingEndOffset: CGFloat?
        
        private var isExpanded: Bool = false
        
        private var visibilityFraction: CGFloat = 1.0
        
        private var activeContentItemId: AnyHashable?
        private var activeSubcontentItemId: AnyHashable?
        
        private var reorderGestureRecognizer: ReorderGestureRecognizer?
        
        private var component: EntityKeyboardTopPanelComponent?
        weak var state: EmptyComponentState?
        private var environment: EntityKeyboardTopContainerPanelEnvironment?
        
        override init(frame: CGRect) {
            self.scrollView = UIScrollView()
            
            self.highlightedIconBackgroundView = UIView()
            self.highlightedIconBackgroundView.isUserInteractionEnabled = false
            self.highlightedIconBackgroundView.clipsToBounds = true
            self.highlightedIconBackgroundView.isHidden = true
            
            super.init(frame: frame)
            
            self.scrollView.layer.anchorPoint = CGPoint()
            self.scrollView.delaysContentTouches = false
            self.scrollView.clipsToBounds = false
            if #available(iOSApplicationExtension 11.0, iOS 11.0, *) {
                self.scrollView.contentInsetAdjustmentBehavior = .never
            }
            if #available(iOS 13.0, *) {
                self.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.alwaysBounceHorizontal = true
            self.scrollView.delegate = self
            self.addSubview(self.scrollView)
            
            self.scrollView.addSubview(self.highlightedIconBackgroundView)
            
            self.clipsToBounds = true
            
            self.disablesInteractiveTransitionGestureRecognizerNow = { [weak self] in
                guard let strongSelf = self else {
                    return false
                }
                return strongSelf.scrollView.contentOffset.x > 0.0
            }
            
            let reorderGestureRecognizer = ReorderGestureRecognizer(
                shouldBegin: { [weak self] point in
                    guard let strongSelf = self else {
                        return (false, false, nil)
                    }
                    if !strongSelf.isExpanded {
                        return (false, false, nil)
                    }
                    let scrollViewLocation = strongSelf.convert(point, to: strongSelf.scrollView)
                    for (id, itemView) in strongSelf.itemViews {
                        if itemView.frame.contains(scrollViewLocation) {
                            for item in strongSelf.items {
                                if item.id == id, item.isReorderable {
                                    return (true, true, itemView)
                                }
                            }
                            break
                        }
                    }
                    return (false, false, nil)
                }, willBegin: { _ in
                }, began: { [weak self] itemView in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.beginReordering(itemView: itemView)
                }, ended: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.endReordering()
                }, moved: { [weak self] value in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updateReordering(offset: value)
                }, isActiveUpdated: { [weak self] isActive in
                    guard let strongSelf = self else {
                        return
                    }
                    let wasReordering = strongSelf.isReordering
                    strongSelf.updateIsReordering(isActive)
                    if !isActive, wasReordering {
                        strongSelf.endReordering()
                    }
                }
            )
            self.reorderGestureRecognizer = reorderGestureRecognizer
            self.addGestureRecognizer(reorderGestureRecognizer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if self.ignoreScrolling {
                return
            }
            
            self.updateVisibleItems(attemptSynchronousLoads: false, transition: .immediate)
        }
        
        public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            self.draggingEndOffset = nil
            
            if let component = self.component {
                var focusItemIndex: Int?
                
                var location = self.scrollView.panGestureRecognizer.location(in: self.scrollView)
                let translation = self.scrollView.panGestureRecognizer.translation(in: self.scrollView)
                location.x -= translation.x
                location.y -= translation.y
                
                for (id, itemView) in self.itemViews {
                    if itemView.frame.insetBy(dx: -4.0, dy: -4.0).contains(location) {
                        inner: for i in 0 ..< component.items.count {
                            if id == component.items[i].id {
                                focusItemIndex = i
                                break inner
                            }
                        }
                        break
                    }
                }
                
                self.draggingFocusItemIndex = focusItemIndex
            }
            
            self.updateIsDragging(true)
        }
        
        public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            self.draggingEndOffset = scrollView.contentOffset.x
            
            if let component = self.component {
                var focusItemIndex: Int?
                
                var location = self.scrollView.panGestureRecognizer.location(in: self.scrollView)
                let translation = self.scrollView.panGestureRecognizer.translation(in: self.scrollView)
                location.x -= translation.x
                location.y -= translation.y
                
                for (id, itemView) in self.itemViews {
                    if itemView.frame.insetBy(dx: -4.0, dy: -4.0).contains(location) {
                        inner: for i in 0 ..< component.items.count {
                            if id == component.items[i].id {
                                focusItemIndex = i
                                break inner
                            }
                        }
                        break
                    }
                }
                
                self.draggingFocusItemIndex = focusItemIndex
            }
            
            if !decelerate {
                self.updateIsDragging(false)
            }
        }
        
        public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            self.updateIsDragging(false)
        }
        
        private func updateIsDragging(_ isDragging: Bool) {
            self.isDragging = isDragging
            self.updateIsDraggingOrReordering()
        }
        
        private func updateIsReordering(_ isReordering: Bool) {
            self.isReordering = isReordering
            self.updateIsDraggingOrReordering()
        }
        
        private func updateIsDraggingOrReordering() {
            let isDraggingOrReordering = self.isDragging || self.isReordering
            
            if !isDraggingOrReordering {
                if !self.isDraggingOrReordering {
                    return
                }
                
                if self.draggingStoppedTimer == nil {
                    self.draggingStoppedTimer = SwiftSignalKit.Timer(timeout: 0.8, repeat: false, completion: { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.draggingStoppedTimer = nil
                        strongSelf.isDraggingOrReordering = false
                        guard let environment = strongSelf.environment else {
                            return
                        }
                        environment.isExpandedUpdated(false, Transition(animation: .curve(duration: 0.3, curve: .spring)))
                    }, queue: .mainQueue())
                    self.draggingStoppedTimer?.start()
                }
            } else {
                self.draggingStoppedTimer?.invalidate()
                self.draggingStoppedTimer = nil
            
                if !self.isDraggingOrReordering {
                    self.isDraggingOrReordering = true
                    
                    guard let environment = self.environment else {
                        return
                    }
                    environment.isExpandedUpdated(true, Transition(animation: .curve(duration: 0.3, curve: .spring)))
                }
            }
        }
        
        private func beginReordering(itemView: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>) {
            if let currentReorderingItemView = self.currentReorderingItemView {
                if let componentView = currentReorderingItemView.componentView {
                    currentReorderingItemView.addSubview(componentView)
                }
                self.currentReorderingItemView = nil
                self.currentReorderingItemId = nil
            }
            
            guard let id = self.itemViews.first(where: { $0.value === itemView })?.key else {
                return
            }
            
            self.currentReorderingItemId = id
            self.currentReorderingItemView = itemView
            
            let reorderingItemContainerView: UIView
            if let current = self.currentReorderingItemContainerView {
                reorderingItemContainerView = current
            } else {
                reorderingItemContainerView = UIView()
                self.addSubview(reorderingItemContainerView)
                self.currentReorderingItemContainerView = reorderingItemContainerView
            }
            
            reorderingItemContainerView.alpha = 0.5
            reorderingItemContainerView.layer.animateAlpha(from: 1.0, to: 0.5, duration: 0.2)
            
            reorderingItemContainerView.frame = itemView.convert(itemView.bounds, to: self)
            self.initialReorderingItemFrame = reorderingItemContainerView.frame
            if let componentView = itemView.componentView {
                reorderingItemContainerView.addSubview(componentView)
            }
            
            self.reorderingHapticFeedback.impact()
            
            if self.currentReorderingScrollDisplayLink == nil {
                self.currentReorderingScrollDisplayLink = ConstantDisplayLinkAnimator(update: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updateReorderingAutoscroll()
                })
                self.currentReorderingScrollDisplayLink?.isPaused = false
            }
        }
        
        private func endReordering() {
            if let currentReorderingItemView = self.currentReorderingItemView {
                self.currentReorderingItemView = nil
                
                if let componentView = currentReorderingItemView.componentView {
                    let localFrame = componentView.convert(componentView.bounds, to: self.scrollView)
                    currentReorderingItemView.superview?.bringSubviewToFront(currentReorderingItemView)
                    currentReorderingItemView.addSubview(componentView)
                    
                    let deltaPosition = CGPoint(x: localFrame.minX - currentReorderingItemView.frame.minX, y: localFrame.minY - currentReorderingItemView.frame.minY)
                    currentReorderingItemView.layer.animatePosition(from: deltaPosition, to: CGPoint(), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
                }
            }
            
            if let reorderingItemContainerView = self.currentReorderingItemContainerView {
                self.currentReorderingItemContainerView = nil
                reorderingItemContainerView.removeFromSuperview()
            }
            
            if let currentReorderingScrollDisplayLink = self.currentReorderingScrollDisplayLink {
                self.currentReorderingScrollDisplayLink = nil
                currentReorderingScrollDisplayLink.invalidate()
            }
            
            self.currentReorderingItemId = nil
            self.temporaryReorderingOrderIndex = nil
            
            self.component?.reorderItems(self.items)
            //self.state?.updated(transition: Transition(animation: .curve(duration: 0.3, curve: .spring)))
        }
        
        private func updateReordering(offset: CGFloat) {
            guard let itemLayout = self.itemLayout, let currentReorderingItemId = self.currentReorderingItemId, let reorderingItemContainerView = self.currentReorderingItemContainerView, let initialReorderingItemFrame = self.initialReorderingItemFrame else {
                return
            }
            reorderingItemContainerView.frame = initialReorderingItemFrame.offsetBy(dx: offset, dy: 0.0)
            
            let localReorderingItemFrame = reorderingItemContainerView.convert(reorderingItemContainerView.bounds, to: self.scrollView)
            
            for i in 0 ..< self.items.count {
                if !self.items[i].isReorderable {
                    continue
                }
                let containerFrame = itemLayout.containerFrame(at: i)
                if containerFrame.intersects(localReorderingItemFrame) {
                    let temporaryReorderingOrderIndex: (id: AnyHashable, index: Int) = (currentReorderingItemId, i)
                    let hadPrevous = self.temporaryReorderingOrderIndex != nil
                    if self.temporaryReorderingOrderIndex?.id != temporaryReorderingOrderIndex.id || self.temporaryReorderingOrderIndex?.index != temporaryReorderingOrderIndex.index {
                        self.temporaryReorderingOrderIndex = temporaryReorderingOrderIndex
                        
                        if hadPrevous {
                            self.reorderingHapticFeedback.tap()
                        }
                        
                        self.state?.updated(transition: Transition(animation: .curve(duration: 0.3, curve: .spring)))
                    }
                    break
                }
            }
        }
        
        private func updateReorderingAutoscroll() {
            guard let reorderingItemContainerView = self.currentReorderingItemContainerView, let initialReorderingItemFrame = self.initialReorderingItemFrame else {
                return
            }
            
            var bounds = self.scrollView.bounds
            let delta: CGFloat = 3.0
            if reorderingItemContainerView.frame.minX < 16.0 {
                bounds.origin.x -= delta
            } else if reorderingItemContainerView.frame.maxX > self.scrollView.bounds.width - 16.0 {
                bounds.origin.x += delta
            }
            
            if bounds.origin.x + bounds.size.width > self.scrollView.contentSize.width {
                bounds.origin.x = self.scrollView.contentSize.width - bounds.size.width
            }
            if bounds.origin.x < 0.0 {
                bounds.origin.x = 0.0
            }
            
            if self.scrollView.bounds != bounds {
                self.scrollView.bounds = bounds
                
                let offset = reorderingItemContainerView.frame.minX - initialReorderingItemFrame.minX
                self.updateReordering(offset: offset)
            }
        }
        
        private func updateVisibleItems(attemptSynchronousLoads: Bool, transition: Transition) {
            guard let itemLayout = self.itemLayout else {
                return
            }
            
            var visibleBounds = self.scrollView.bounds
            visibleBounds.origin.x -= 200.0
            visibleBounds.size.width += 400.0
            
            var validIds = Set<AnyHashable>()
            let visibleItemRange = itemLayout.visibleItemRange(for: visibleBounds)
            if !self.items.isEmpty && visibleItemRange.maxIndex >= visibleItemRange.minIndex {
                for index in visibleItemRange.minIndex ... visibleItemRange.maxIndex {
                    let item = self.items[index]
                    validIds.insert(item.id)
                    
                    var itemTransition = transition
                    let itemView: ComponentHostView<EntityKeyboardTopPanelItemEnvironment>
                    if let current = self.itemViews[item.id] {
                        itemView = current
                    } else {
                        itemTransition = .immediate
                        itemView = ComponentHostView<EntityKeyboardTopPanelItemEnvironment>()
                        self.scrollView.addSubview(itemView)
                        self.itemViews[item.id] = itemView
                    }
                    
                    let itemOuterFrame = itemLayout.contentFrame(at: index)
                    let itemSize = itemView.update(
                        transition: itemTransition,
                        component: item.content,
                        environment: {
                            EntityKeyboardTopPanelItemEnvironment(isExpanded: itemLayout.isExpanded, isHighlighted: self.activeContentItemId == item.id, highlightedSubgroupId: self.activeContentItemId == item.id ? self.activeSubcontentItemId : nil)
                        },
                        containerSize: itemOuterFrame.size
                    )
                    let itemFrame = CGRect(origin: CGPoint(x: itemOuterFrame.minX + floor((itemOuterFrame.width - itemSize.width) / 2.0), y: itemOuterFrame.minY + floor((itemOuterFrame.height - itemSize.height) / 2.0)), size: itemSize)
                    /*if index == visibleItemRange.minIndex, !itemTransition.animation.isImmediate {
                        print("\(index): \(itemView.frame) -> \(itemFrame)")
                    }*/
                    itemTransition.setFrame(view: itemView, frame: itemFrame)
                }
            }
            var removedIds: [AnyHashable] = []
            for (id, itemView) in self.itemViews {
                if !validIds.contains(id) {
                    removedIds.append(id)
                    itemView.removeFromSuperview()
                }
            }
            for id in removedIds {
                self.itemViews.removeValue(forKey: id)
            }
        }
        
        func update(component: EntityKeyboardTopPanelComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
            if self.component?.theme !== component.theme {
                self.highlightedIconBackgroundView.backgroundColor = component.theme.chat.inputMediaPanel.panelHighlightedIconBackgroundColor
            }
            self.component = component
            self.state = state
            
            if let defaultActiveItemId = component.defaultActiveItemId {
                self.activeContentItemId = defaultActiveItemId
            }
            
            let panelEnvironment = environment[EntityKeyboardTopContainerPanelEnvironment.self].value
            self.environment = panelEnvironment
            
            let isExpanded = availableSize.height > 41.0
            let wasExpanded = self.isExpanded
            self.isExpanded = isExpanded
            
            if !isExpanded {
                if self.isDragging {
                    self.isDragging = false
                }
                if self.isReordering {
                    self.isReordering = false
                    self.reorderGestureRecognizer?.state = .failed
                }
                if self.isDraggingOrReordering {
                    self.isDraggingOrReordering = false
                }
                if let draggingStoppedTimer = self.draggingStoppedTimer {
                    self.draggingStoppedTimer = nil
                    draggingStoppedTimer.invalidate()
                }
            }
            
            let intrinsicHeight: CGFloat = availableSize.height
            let height = intrinsicHeight
            
            var items = component.items
            if let (id, index) = self.temporaryReorderingOrderIndex {
                for i in 0 ..< items.count {
                    if items[i].id == id {
                        let item = items.remove(at: i)
                        items.insert(item, at: min(index, items.count))
                        break
                    }
                }
            }
            self.items = items
            
            if self.activeContentItemId == nil {
                self.activeContentItemId = items.first?.id
            }
            
            let previousItemLayout = self.itemLayout
            let itemLayout = ItemLayout(isExpanded: isExpanded, height: availableSize.height, items: self.items.map { item -> ItemLayout.ItemDescription in
                let isStatic = item.id == AnyHashable("static")
                return ItemLayout.ItemDescription(
                    isStatic: isStatic,
                    isStaticExpanded: isStatic && self.activeContentItemId == item.id
                )
            })
            self.itemLayout = itemLayout
            
            self.ignoreScrolling = true
            
            var updatedBounds: CGRect?
            if wasExpanded != isExpanded, let previousItemLayout = previousItemLayout {
                if !isExpanded {
                    if let draggingEndOffset = self.draggingEndOffset {
                        if abs(self.scrollView.contentOffset.x - draggingEndOffset) > 16.0 {
                            self.draggingFocusItemIndex = nil
                        }
                    } else {
                        self.draggingFocusItemIndex = nil
                    }
                }
                
                var visibleBounds = self.scrollView.bounds
                visibleBounds.origin.x -= 200.0
                visibleBounds.size.width += 400.0
                
                let previousVisibleRange = previousItemLayout.visibleItemRange(for: visibleBounds)
                if previousVisibleRange.minIndex <= previousVisibleRange.maxIndex {
                    var itemIndex = self.draggingFocusItemIndex ?? ((previousVisibleRange.minIndex + previousVisibleRange.maxIndex) / 2)
                    if !isExpanded {
                        if self.scrollView.bounds.maxX >= self.scrollView.contentSize.width {
                            itemIndex = component.items.count - 1
                        }
                        if self.scrollView.bounds.minX <= 0.0 {
                            itemIndex = 0
                        }
                    }
                    
                    var previousItemFrame = previousItemLayout.containerFrame(at: itemIndex)
                    var updatedItemFrame = itemLayout.containerFrame(at: itemIndex)
                    
                    let previousDistanceToItem = (previousItemFrame.minX - self.scrollView.bounds.minX)
                    let previousDistanceToItemRight = (previousItemFrame.maxX - self.scrollView.bounds.maxX)
                    var newBounds = CGRect(origin: CGPoint(x: updatedItemFrame.minX - previousDistanceToItem, y: 0.0), size: availableSize)
                    var useRightAnchor = false
                    if newBounds.minX > itemLayout.contentSize.width - self.scrollView.bounds.width {
                        newBounds.origin.x = itemLayout.contentSize.width - self.scrollView.bounds.width
                        itemIndex = component.items.count - 1
                        useRightAnchor = true
                    }
                    if newBounds.minX < 0.0 {
                        newBounds.origin.x = 0.0
                        itemIndex = 0
                        useRightAnchor = false
                    }
                    
                    if useRightAnchor {
                        var newBounds = CGRect(origin: CGPoint(x: updatedItemFrame.maxX - previousDistanceToItemRight, y: 0.0), size: availableSize)
                        if newBounds.minX > itemLayout.contentSize.width - self.scrollView.bounds.width {
                            newBounds.origin.x = itemLayout.contentSize.width - self.scrollView.bounds.width
                        }
                        if newBounds.minX < 0.0 {
                        }
                    }
                    
                    previousItemFrame = previousItemLayout.containerFrame(at: itemIndex)
                    updatedItemFrame = itemLayout.containerFrame(at: itemIndex)
                    
                    self.draggingFocusItemIndex = itemIndex
                    
                    updatedBounds = newBounds
                    
                    var updatedVisibleBounds = newBounds
                    updatedVisibleBounds.origin.x -= 200.0
                    updatedVisibleBounds.size.width += 400.0
                    let updatedVisibleRange = itemLayout.visibleItemRange(for: updatedVisibleBounds)
                    
                    if useRightAnchor {
                        let baseFrame = CGRect(origin: CGPoint(x: updatedItemFrame.maxX - previousItemFrame.width, y: previousItemFrame.minY), size: previousItemFrame.size)
                        for index in updatedVisibleRange.minIndex ... updatedVisibleRange.maxIndex {
                            let indexDifference = index - itemIndex
                            if let itemView = self.itemViews[self.items[index].id] {
                                let itemContainerMaxX = baseFrame.maxX + CGFloat(indexDifference) * (previousItemLayout.itemSize.width + previousItemLayout.itemSpacing)
                                let itemContainerFrame = CGRect(origin: CGPoint(x: itemContainerMaxX - baseFrame.width, y: baseFrame.minY), size: baseFrame.size)
                                let itemOuterFrame = previousItemLayout.contentFrame(index: index, containerFrame: itemContainerFrame)
                                
                                let itemSize = itemView.bounds.size
                                itemView.frame = CGRect(origin: CGPoint(x: itemOuterFrame.minX + floor((itemOuterFrame.width - itemSize.width) / 2.0), y: itemOuterFrame.minY + floor((itemOuterFrame.height - itemSize.height) / 2.0)), size: itemSize)
                                
                                if let activeContentItemId = self.activeContentItemId, activeContentItemId == self.items[index].id {
                                    self.highlightedIconBackgroundView.frame = itemOuterFrame
                                }
                            }
                        }
                    } else {
                        let baseFrame = CGRect(origin: CGPoint(x: updatedItemFrame.minX, y: previousItemFrame.minY), size: previousItemFrame.size)
                        for index in updatedVisibleRange.minIndex ... updatedVisibleRange.maxIndex {
                            let indexDifference = index - itemIndex
                            if let itemView = self.itemViews[self.items[index].id] {
                                var itemContainerOriginX = baseFrame.minX
                                if indexDifference > 0 {
                                    for i in 0 ..< indexDifference {
                                        itemContainerOriginX += previousItemLayout.itemSpacing
                                        itemContainerOriginX += previousItemLayout.containerFrame(at: itemIndex + i).width
                                    }
                                } else if indexDifference < 0 {
                                    for i in 0 ..< (-indexDifference) {
                                        itemContainerOriginX -= previousItemLayout.itemSpacing
                                        itemContainerOriginX -= previousItemLayout.containerFrame(at: itemIndex - i - 1).width
                                    }
                                }
                                
                                let previousContainerFrame = previousItemLayout.containerFrame(at: index)
                                let itemContainerFrame = CGRect(origin: CGPoint(x: itemContainerOriginX, y: previousContainerFrame.minY), size: previousContainerFrame.size)
                                let itemOuterFrame = previousItemLayout.contentFrame(index: index, containerFrame: itemContainerFrame)
                                
                                let itemSize = itemView.bounds.size
                                itemView.frame = CGRect(origin: CGPoint(x: itemOuterFrame.minX + floor((itemOuterFrame.width - itemSize.width) / 2.0), y: itemOuterFrame.minY + floor((itemOuterFrame.height - itemSize.height) / 2.0)), size: itemSize)
                                
                                if let activeContentItemId = self.activeContentItemId, activeContentItemId == self.items[index].id {
                                    self.highlightedIconBackgroundView.frame = itemOuterFrame
                                }
                            }
                        }
                    }
                }
                
                if !isExpanded {
                    self.draggingFocusItemIndex = nil
                }
            }
            
            if self.scrollView.contentSize != itemLayout.contentSize {
                self.scrollView.contentSize = itemLayout.contentSize
            }
            if let updatedBounds = updatedBounds {
                self.scrollView.bounds = updatedBounds
            } else {
                self.scrollView.bounds = CGRect(origin: self.scrollView.bounds.origin, size: availableSize)
            }
            self.ignoreScrolling = false
            
            self.updateVisibleItems(attemptSynchronousLoads: !(self.scrollView.isDragging || self.scrollView.isDecelerating), transition: transition)
            
            if let activeContentItemId = self.activeContentItemId {
                if let index = self.items.firstIndex(where: { $0.id == activeContentItemId }) {
                    let itemFrame = itemLayout.containerFrame(at: index)
                    
                    var highlightTransition = transition
                    if self.highlightedIconBackgroundView.isHidden {
                        self.highlightedIconBackgroundView.isHidden = false
                        highlightTransition = .immediate
                    }
                    
                    let isRound: Bool
                    if let string = activeContentItemId.base as? String, (string == "recent" || string == "static") {
                        isRound = true
                    } else {
                        isRound = false
                    }
                    highlightTransition.setCornerRadius(layer: self.highlightedIconBackgroundView.layer, cornerRadius: isRound ? min(itemFrame.width / 2.0, itemFrame.height / 2.0) : 10.0)
                    highlightTransition.setPosition(view: self.highlightedIconBackgroundView, position: CGPoint(x: itemFrame.midX, y: itemFrame.midY))
                    highlightTransition.setBounds(view: self.highlightedIconBackgroundView, bounds: CGRect(origin: CGPoint(), size: itemFrame.size))
                } else {
                    self.highlightedIconBackgroundView.isHidden = true
                }
            } else {
                self.highlightedIconBackgroundView.isHidden = true
            }
            transition.setAlpha(view: self.highlightedIconBackgroundView, alpha: isExpanded ? 0.0 : 1.0)
            
            panelEnvironment.visibilityFractionUpdated.connect { [weak self] (fraction, transition) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.visibilityFractionUpdated(value: fraction, transition: transition)
            }
            
            component.activeContentItemIdUpdated.connect { [weak self] (itemId, subcontentItemId, transition) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.activeContentItemIdUpdated(itemId: itemId, subcontentItemId: subcontentItemId, transition: transition)
            }
            
            return CGSize(width: availableSize.width, height: height)
        }
        
        private func visibilityFractionUpdated(value: CGFloat, transition: Transition) {
            if self.visibilityFraction == value {
                return
            }
            
            self.visibilityFraction = value
            
            let scale = max(0.01, self.visibilityFraction)
            
            transition.setScale(view: self.highlightedIconBackgroundView, scale: scale)
            transition.setAlpha(view: self.highlightedIconBackgroundView, alpha: self.visibilityFraction)
            
            for (_, itemView) in self.itemViews {
                transition.setSublayerTransform(view: itemView, transform: CATransform3DMakeScale(scale, scale, 1.0))
                transition.setAlpha(view: itemView, alpha: self.visibilityFraction)
            }
        }
        
        private func activeContentItemIdUpdated(itemId: AnyHashable, subcontentItemId: AnyHashable?, transition: Transition) {
            guard let component = self.component, let itemLayout = self.itemLayout else {
                return
            }
            if self.activeContentItemId == itemId && self.activeSubcontentItemId == subcontentItemId {
                return
            }
            self.activeContentItemId = itemId
            self.activeSubcontentItemId = subcontentItemId
            
            let _ = component
            let _ = itemLayout
            self.state?.updated(transition: Transition(animation: .curve(duration: 0.4, curve: .spring)))
            
            if let component = self.component, let itemLayout = self.itemLayout {
                for i in 0 ..< component.items.count {
                    if component.items[i].id == itemId {
                        let itemFrame = itemLayout.containerFrame(at: i)
                        self.scrollView.scrollRectToVisible(itemFrame.insetBy(dx: -2.0, dy: 0.0), animated: true)
                        break
                    }
                }
            }

            /*var found = false
            for i in 0 ..< self.items.count {
                if self.items[i].id == itemId {
                    found = true
                    self.highlightedIconBackgroundView.isHidden = false
                    let itemFrame = itemLayout.containerFrame(at: i)
                    
                    var highlightTransition = transition
                    if highlightTransition.animation.isImmediate {
                        highlightTransition = highlightTransition.withAnimation(.curve(duration: 0.3, curve: .spring))
                    }
                    highlightTransition.setPosition(view: self.highlightedIconBackgroundView, position: CGPoint(x: itemFrame.midX, y: itemFrame.midY))
                    highlightTransition.setBounds(view: self.highlightedIconBackgroundView, bounds: CGRect(origin: CGPoint(), size: itemFrame.size))
                    
                    self.scrollView.scrollRectToVisible(itemFrame.insetBy(dx: -6.0, dy: 0.0), animated: true)
                    
                    break
                }
            }
            if !found {
                self.highlightedIconBackgroundView.isHidden = true
            }*/
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
