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
    ResquircleDrawingView * _view;
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

    _view = [[ResquircleDrawingView alloc] init];

    self.contentView = _view;
  }

  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _view.frame = self.bounds;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<ResquircleViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<ResquircleViewProps const>(props);

    // Back-compat
    if (oldViewProps.color != newViewProps.color) {
        _view.squircleBackgroundColor = RCTUIColorFromSharedColor(newViewProps.color);
    }

    if (oldViewProps.squircleBackgroundColor != newViewProps.squircleBackgroundColor) {
        _view.squircleBackgroundColor = RCTUIColorFromSharedColor(newViewProps.squircleBackgroundColor);
    }

    if (oldViewProps.squircleBorderColor != newViewProps.squircleBorderColor) {
        _view.squircleBorderColor = RCTUIColorFromSharedColor(newViewProps.squircleBorderColor);
    }

    if (oldViewProps.squircleBorderWidth != newViewProps.squircleBorderWidth) {
        _view.squircleBorderWidth = newViewProps.squircleBorderWidth;
    }

    if (oldViewProps.borderRadius != newViewProps.borderRadius) {
        _view.borderRadius = newViewProps.borderRadius;
    }

    if (oldViewProps.cornerSmoothing != newViewProps.cornerSmoothing) {
        _view.cornerSmoothing = newViewProps.cornerSmoothing;
    }

    if (oldViewProps.squircleBoxShadow != newViewProps.squircleBoxShadow) {
        NSString *shadow = newViewProps.squircleBoxShadow.empty()
          ? nil
          : [NSString stringWithUTF8String:newViewProps.squircleBoxShadow.c_str()];
        _view.squircleBoxShadow = shadow;
    }

    if (oldViewProps.overflow != newViewProps.overflow) {
        NSString *overflow = newViewProps.overflow.empty()
          ? nil
          : [NSString stringWithUTF8String:newViewProps.overflow.c_str()];
        _view.overflow = overflow;
    }

    [super updateProps:props oldProps:oldProps];
}

@end
