// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

/// Writes short silent WAV files so `just_audio` can load bundled ambient tracks.
void main() {
  final Directory dir = Directory('assets/sounds');
  dir.createSync(recursive: true);
  final Uint8List bytes = _silentWavPcm8();
  for (final String name in <String>['rain', 'white_noise', 'forest']) {
    final File f = File('${dir.path}/$name.wav');
    f.writeAsBytesSync(bytes);
    print('Wrote ${f.path}');
  }
}

Uint8List _silentWavPcm8() {
  const int sampleRate = 8000;
  const int bitsPerSample = 8;
  const int channels = 1;
  const int numSamples = sampleRate ~/ 5;
  const int dataSize = numSamples * channels;
  const int riffSize = 36 + dataSize;
  final BytesBuilder b = BytesBuilder();
  void ascii(String s) => b.add(s.codeUnits);
  void u32(int v) {
    final ByteData bd = ByteData(4)..setUint32(0, v, Endian.little);
    b.add(bd.buffer.asUint8List());
  }

  void u16(int v) {
    final ByteData bd = ByteData(2)..setUint16(0, v, Endian.little);
    b.add(bd.buffer.asUint8List());
  }

  ascii('RIFF');
  u32(riffSize);
  ascii('WAVE');
  ascii('fmt ');
  u32(16);
  u16(1);
  u16(channels);
  u32(sampleRate);
  u32(sampleRate * channels * bitsPerSample ~/ 8);
  u16(channels * bitsPerSample ~/ 8);
  u16(bitsPerSample);
  ascii('data');
  u32(dataSize);
  for (int i = 0; i < numSamples; i++) {
    b.addByte(128);
  }
  return b.toBytes();
}
