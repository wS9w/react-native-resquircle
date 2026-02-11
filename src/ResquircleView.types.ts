import type { Pressable, ViewProps } from 'react-native';

type ResquircleProps = {
  /**
   * Corner smoothing amount.
   *
   * Range: **0..1**
   * Default: 0.6 (60%)
   */
  cornerSmoothing?: number;
  /**
   * Controls whether the squircle drawing is clipped.
   */
  overflow?: 'visible' | 'hidden';
};

export type ResquircleViewProps = {
  style?: any;
} & Omit<ViewProps, 'style'> &
  ResquircleProps;

export type ResquircleButtonProps = {
  activeOpacity?: number;
  style?: any;
} & Omit<React.ComponentProps<typeof Pressable>, 'style'> &
  ResquircleProps;
