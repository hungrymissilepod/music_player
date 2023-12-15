/// enum to tell [Visualizer] to build a texture as:
/// [both1D] frequencies data on the 1st 256px row, wave on the 2nd 256px
/// [fft2D] frequencies data 256x256 px
/// [wave2D] wave data 256x256px
/// [both2D] both frequencies & wave data interleaved 256x512px
enum TextureType {
  both1D,
  fft2D,
  wave2D,
  both2D, // no implemented yet
}
