import {
  codegenNativeComponent,
  type ColorValue,
  type ViewProps,
} from 'react-native';
import type { Float } from 'react-native/Libraries/Types/CodegenTypes';

// NOTE: RN codegen expects an interface (not a type-alias intersection).
// Otherwise it may fail with:
// "Failed to find type definition for <TypeName>"
export interface NativeResquircleViewProps extends ViewProps {
  /**
   * Background fill for the squircle.
   */
  squircleBackgroundColor?: ColorValue;
  /**
   * Border stroke color.
   */
  squircleBorderColor?: ColorValue;
  /**
   * Border width (dp).
   */
  squircleBorderWidth?: Float;
  /**
   * Corner radius (dp).
   */
  borderRadius?: Float;
  /**
   * Corner smoothing amount. Range 0..1
   */
  cornerSmoothing?: Float;
  /**
   * CSS-like box-shadow string: "0px 2px 4px 0px rgba(...), ..."
   */
  squircleBoxShadow?: string;
  /**
   * Controls whether children are clipped to the squircle shape.
   * (iOS implementation clips native subviews; Android pending.)
   */
  overflow?: string;
  /**
   * Back-compat: old example prop. Treated as squircleBackgroundColor.
   */
  color?: ColorValue;
}

export default codegenNativeComponent<NativeResquircleViewProps>(
  'ResquircleView'
);
