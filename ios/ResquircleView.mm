#import "ResquircleView.h"

#import <React/RCTConversions.h>

#import <react/renderer/components/ResquircleViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/ResquircleViewSpec/Props.h>
#import <react/renderer/components/ResquircleViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

#if __has_include("Resquircle-Swift.h")
#import "Resquircle-Swift.h"
#endif

@implementation ResquircleView {
    ResquircleDrawingView * _contentView;
    ResquircleDrawingView * _shadowView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<ResquircleViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const ResquircleViewProps>();
    _props = defaultProps;

    // Content view: hosts Fabric children + draws fill/border and applies clipping mask.
    _contentView = [[ResquircleDrawingView alloc] init];
    // Shadow view: draws shadows without being clipped by overflow.
    _shadowView = [[ResquircleDrawingView alloc] init];
    _shadowView.drawSquircleLayer = NO;
    _shadowView.overflow = @"visible";

    self.contentView = _contentView;
    [self insertSubview:_shadowView belowSubview:self.contentView];
  }

  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _shadowView.frame = self.bounds;
  _contentView.frame = self.bounds;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<ResquircleViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<ResquircleViewProps const>(props);

    // Back-compat
    if (oldViewProps.color != newViewProps.color) {
        UIColor *c = RCTUIColorFromSharedColor(newViewProps.color);
        _contentView.squircleBackgroundColor = c;
        _shadowView.squircleBackgroundColor = c;
    }

    if (oldViewProps.squircleBackgroundColor != newViewProps.squircleBackgroundColor) {
        UIColor *c = RCTUIColorFromSharedColor(newViewProps.squircleBackgroundColor);
        _contentView.squircleBackgroundColor = c;
        _shadowView.squircleBackgroundColor = c;
    }

    if (oldViewProps.squircleBorderColor != newViewProps.squircleBorderColor) {
        UIColor *c = RCTUIColorFromSharedColor(newViewProps.squircleBorderColor);
        _contentView.squircleBorderColor = c;
        _shadowView.squircleBorderColor = c;
    }

    if (oldViewProps.squircleBorderWidth != newViewProps.squircleBorderWidth) {
        CGFloat w = newViewProps.squircleBorderWidth;
        _contentView.squircleBorderWidth = w;
        _shadowView.squircleBorderWidth = w;
    }

    if (oldViewProps.borderRadius != newViewProps.borderRadius) {
        CGFloat r = newViewProps.borderRadius;
        _contentView.borderRadius = r;
        _shadowView.borderRadius = r;
    }

    if (oldViewProps.cornerSmoothing != newViewProps.cornerSmoothing) {
        CGFloat s = newViewProps.cornerSmoothing;
        _contentView.cornerSmoothing = s;
        _shadowView.cornerSmoothing = s;
    }

    if (oldViewProps.squircleBoxShadow != newViewProps.squircleBoxShadow) {
        NSString *shadow = newViewProps.squircleBoxShadow.empty()
          ? nil
          : [NSString stringWithUTF8String:newViewProps.squircleBoxShadow.c_str()];
        // Shadows should stay visible even when content is clipped.
        _shadowView.squircleBoxShadow = shadow;
        _contentView.squircleBoxShadow = nil;
    }

    if (oldViewProps.overflow != newViewProps.overflow) {
        NSString *overflow = newViewProps.overflow.empty()
          ? nil
          : [NSString stringWithUTF8String:newViewProps.overflow.c_str()];
        // Clip only content (and its children). Keep shadow un-clipped.
        _contentView.overflow = overflow;
        _shadowView.overflow = @"visible";
    }

    [super updateProps:props oldProps:oldProps];
}

@end
