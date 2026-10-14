/// Seconds for a touch at [x] on a progress bar [width] wide.
double seekTarget(double x, double width, double duration) {
  if (width <= 0 || duration <= 0) return 0;
  return ((x / width).clamp(0.0, 1.0) * duration).roundToDouble();
}
