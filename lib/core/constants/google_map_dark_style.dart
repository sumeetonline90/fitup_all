/// Dark theme JSON for [GoogleMap] — Stitch live tracker aesthetic.
const String kGoogleMapDarkStyleJson = r'''
[
  {"elementType": "geometry", "stylers": [{"color": "#1a1a1a"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1a1a"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1624"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]}
]
''';
