import * as React from 'react';
import {
  Pressable,
  StyleSheet,
  View,
  type ColorValue,
  type DimensionValue,
  type ViewProps,
  processColor,
} from 'react-native';

import NativeResquircleView from './ResquircleViewNativeComponent';
import type {
  ResquircleButtonProps,
  ResquircleViewProps,
} from './ResquircleView.types';

const DEFAULT_CORNER_SMOOTHING = 0.6;

type InternalResquircleOverlayProps = {
  cornerSmoothing?: number;
  backgroundColor?: ColorValue;
  borderRadius?: number;
  borderColor?: ColorValue;
  borderWidth?: number;
  overflow?: 'visible' | 'hidden';
  squircleBoxShadow?: string;
};

const ResquircleNativeOverlay = (props: InternalResquircleOverlayProps) => {
  const {
    cornerSmoothing,
    backgroundColor,
    borderRadius,
    borderColor,
    borderWidth,
    overflow,
    squircleBoxShadow,
  } = props;

  return (
    <NativeResquircleView
      // Fabric/codegen: pass ColorValue, native will convert.
      squircleBackgroundColor={backgroundColor}
      squircleBorderColor={borderColor}
      squircleBorderWidth={borderWidth}
      squircleBoxShadow={squircleBoxShadow}
      borderRadius={borderRadius}
      cornerSmoothing={cornerSmoothing}
      overflow={overflow}
      style={StyleSheet.absoluteFill}
      pointerEvents="none"
    />
  );
};

export const ResquircleView = React.forwardRef<
  View,
  ViewProps & ResquircleViewProps
>((props, ref) => {
  const { children } = props;
  const { resquircleProps, contentStyle, restProps } =
    useResquircleProps(props);

  return (
    <View ref={ref} style={contentStyle} {...restProps}>
      <ResquircleNativeOverlay {...resquircleProps} />
      {children}
    </View>
  );
});

ResquircleView.displayName = 'ResquircleView';

export const ResquircleButton = React.forwardRef<View, ResquircleButtonProps>(
  (props, ref) => {
    const { children, activeOpacity = 0.85 } = props;
    const { resquircleProps, contentStyle, restProps } =
      useResquircleProps(props);

    return (
      <Pressable
        ref={ref}
        style={({ pressed }) => [
          contentStyle,
          pressed && { opacity: activeOpacity },
        ]}
        {...restProps}
      >
        {({ pressed }) => (
          <>
            <ResquircleNativeOverlay {...resquircleProps} />
            {typeof children === 'function' ? children({ pressed }) : children}
          </>
        )}
      </Pressable>
    );
  }
);

ResquircleButton.displayName = 'ResquircleButton';

const useResquircleProps = (
  props: ResquircleViewProps | ResquircleButtonProps
) => {
  const { cornerSmoothing, overflow, style, ...restProps } = props as any;

  const flattenedStyle = style ? StyleSheet.flatten(style) : undefined;

  const {
    // shadow styles
    boxShadow,
    shadowColor,
    shadowOpacity,
    shadowRadius,
    shadowOffset,
    elevation,
    // padding
    padding,
    paddingVertical,
    paddingHorizontal,
    paddingBottom,
    paddingEnd,
    paddingLeft,
    paddingRight,
    paddingStart,
    paddingTop,
    // other styles that should be passed to container
    ...containerStyle
  } = flattenedStyle || ({} as any);

  const derivedSquircleBoxShadow = React.useMemo(() => {
    if (typeof boxShadow === 'string' && boxShadow.trim().length > 0) {
      return boxShadow;
    }

    if (
      shadowColor == null &&
      shadowOpacity == null &&
      shadowRadius == null &&
      shadowOffset == null &&
      elevation == null
    ) {
      return undefined;
    }

    if (shadowRadius == null && shadowOffset == null && shadowColor == null) {
      return undefined;
    }

    const offsetX =
      typeof shadowOffset?.width === 'number' ? shadowOffset.width : 0;
    const offsetY =
      typeof shadowOffset?.height === 'number' ? shadowOffset.height : 0;
    const blur = typeof shadowRadius === 'number' ? shadowRadius : 0;
    const spread = 0;

    const rgba = colorToRgbaString(shadowColor as ColorValue, shadowOpacity);
    if (!rgba) return undefined;

    return `${offsetX}px ${offsetY}px ${blur}px ${spread}px ${rgba}`;
  }, [
    boxShadow,
    shadowColor,
    shadowOpacity,
    shadowRadius,
    shadowOffset,
    elevation,
  ]);

  const calculatedPadding = React.useMemo(() => {
    const extraPadding = flattenedStyle?.borderWidth || 0;
    if (extraPadding === 0) {
      return {};
    }

    const calculatePadding = (_paddingValue: DimensionValue) => {
      if (typeof _paddingValue === 'number') {
        return _paddingValue + extraPadding;
      }
      return _paddingValue;
    };

    const result: any = {};
    if (padding !== undefined) result.padding = calculatePadding(padding);
    if (paddingVertical !== undefined)
      result.paddingVertical = calculatePadding(paddingVertical);
    if (paddingHorizontal !== undefined)
      result.paddingHorizontal = calculatePadding(paddingHorizontal);
    if (paddingBottom !== undefined)
      result.paddingBottom = calculatePadding(paddingBottom);
    if (paddingEnd !== undefined)
      result.paddingEnd = calculatePadding(paddingEnd);
    if (paddingLeft !== undefined)
      result.paddingLeft = calculatePadding(paddingLeft);
    if (paddingRight !== undefined)
      result.paddingRight = calculatePadding(paddingRight);
    if (paddingStart !== undefined)
      result.paddingStart = calculatePadding(paddingStart);
    if (paddingTop !== undefined)
      result.paddingTop = calculatePadding(paddingTop);

    if (Object.keys(result).length === 0 && extraPadding > 0) {
      result.padding = extraPadding;
    }

    return result;
  }, [
    flattenedStyle?.borderWidth,
    padding,
    paddingVertical,
    paddingHorizontal,
    paddingBottom,
    paddingEnd,
    paddingLeft,
    paddingRight,
    paddingStart,
    paddingTop,
  ]);

  const resquircleProps = React.useMemo(
    () => ({
      borderRadius: flattenedStyle?.borderRadius ?? 0,
      borderWidth: flattenedStyle?.borderWidth ?? 0,
      backgroundColor: flattenedStyle?.backgroundColor ?? 'transparent',
      borderColor: flattenedStyle?.borderColor ?? 'transparent',
      cornerSmoothing:
        cornerSmoothing !== undefined
          ? cornerSmoothing
          : DEFAULT_CORNER_SMOOTHING,
      overflow: overflow ?? 'visible',
      squircleBoxShadow: derivedSquircleBoxShadow,
    }),
    [
      cornerSmoothing,
      overflow,
      derivedSquircleBoxShadow,
      flattenedStyle?.borderRadius,
      flattenedStyle?.borderWidth,
      flattenedStyle?.backgroundColor,
      flattenedStyle?.borderColor,
    ]
  );

  const contentStyle = React.useMemo(
    () => [
      styles.container,
      containerStyle,
      calculatedPadding,
      {
        borderWidth: 0,
        borderColor: 'transparent',
        backgroundColor: 'transparent',
        ...(boxShadow != null ? { boxShadow: undefined } : null),
        ...(shadowColor != null ? { shadowColor: undefined } : null),
        ...(shadowOpacity != null ? { shadowOpacity: undefined } : null),
        ...(shadowRadius != null ? { shadowRadius: undefined } : null),
        ...(shadowOffset != null ? { shadowOffset: undefined } : null),
        ...(elevation != null ? { elevation: undefined } : null),
      },
    ],
    [
      containerStyle,
      calculatedPadding,
      boxShadow,
      shadowColor,
      shadowOpacity,
      shadowRadius,
      shadowOffset,
      elevation,
    ]
  );

  return {
    resquircleProps,
    contentStyle,
    restProps,
  };
};

const colorToRgbaString = (color: ColorValue | undefined, opacity?: number) => {
  if (color == null) return undefined;
  const processed = processColor(color);
  if (processed == null) return undefined;
  const argb = (processed as number) >>> 0;
  const a = (argb >>> 24) & 0xff;
  const r = (argb >>> 16) & 0xff;
  const g = (argb >>> 8) & 0xff;
  const b = argb & 0xff;
  const baseAlpha = a / 255;
  const finalAlpha =
    typeof opacity === 'number'
      ? Math.max(0, Math.min(1, baseAlpha * opacity))
      : Math.max(0, Math.min(1, baseAlpha));
  return `rgba(${r}, ${g}, ${b}, ${finalAlpha})`;
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
  },
});
