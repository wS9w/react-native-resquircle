type ShadowSpec = {
    x: number;
    y: number;
    blur: number;
    spread?: number;
    color: string;
    /**
     * 0..100 (percent)
     */
    opacity: number;
  };
  
  export const buildBoxShadow = (shadows: ShadowSpec[]) =>
    shadows
      .map(({ x, y, blur, spread = 0, color, opacity }) => {
        const a = Math.max(0, Math.min(1, opacity / 100));
        return `${x}px ${y}px ${blur}px ${spread}px ${hexToRgba(color, a)}`;
      })
      .join(', ');
  
  const hexToRgba = (hex: string, alpha: number) => {
    const h = hex.replace('#', '');
    const bigint =
      h.length === 3
        ? parseInt(
            h
              .split('')
              .map((c) => c + c)
              .join(''),
            16
          )
        : parseInt(h, 16);
    const r = (bigint >> 16) & 255;
    const g = (bigint >> 8) & 255;
    const b = bigint & 255;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  };
  