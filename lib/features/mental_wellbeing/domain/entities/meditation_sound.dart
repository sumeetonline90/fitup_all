enum MeditationSound { silent, rain, whiteNoise, forest }

MeditationSound meditationSoundFromName(String? raw) {
  if (raw == null || raw.isEmpty) {
    return MeditationSound.silent;
  }
  for (final MeditationSound s in MeditationSound.values) {
    if (s.name == raw) {
      return s;
    }
  }
  return MeditationSound.silent;
}

extension MeditationSoundX on MeditationSound {
  String get label => switch (this) {
    MeditationSound.silent => 'Silent',
    MeditationSound.rain => 'Rain',
    MeditationSound.whiteNoise => 'White Noise',
    MeditationSound.forest => 'Forest',
  };

  /// Asset path when available; null = no file in build.
  String? get assetPath => switch (this) {
    MeditationSound.silent => null,
    MeditationSound.rain => 'assets/sounds/rain.wav',
    MeditationSound.whiteNoise => 'assets/sounds/white_noise.wav',
    MeditationSound.forest => 'assets/sounds/forest.wav',
  };

  /// Network fallback when local assets are not bundled on the device build.
  ///
  /// This keeps sound modes functional while the app is being tested without
  /// packaged audio files.
  String? get fallbackUrl => switch (this) {
    MeditationSound.silent => null,
    MeditationSound.rain =>
      'https://cdn.pixabay.com/audio/2022/03/15/audio_c8c8a73467.mp3',
    MeditationSound.whiteNoise =>
      'https://cdn.pixabay.com/audio/2022/01/18/audio_d0af0f76d5.mp3',
    MeditationSound.forest =>
      'https://cdn.pixabay.com/audio/2022/03/10/audio_c62a0c54c3.mp3',
  };
}
