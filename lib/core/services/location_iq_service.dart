import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationIQService {
  final String apiKey = 'pk.faabc02907e60526bf767ce67fb1fe90';

  // Search for places (autocomplete) - Using the exact API format
  static Future<List<LocationResult>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    print('🔍 Starting LocationIQ search for: "$query"');

    // API Format: 
    // q = search term
    // limit = number of results
    // dedupe = 1 (removes duplicate addresses)
    final url = 'https://api.locationiq.com/v1/autocomplete?key=pk.faabc02907e60526bf767ce67fb1fe90&q=$query&limit=5&dedupe=1&countrycodes=ph';
    
    print('🌐 LocationIQ URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        try {
          List<dynamic> data = json.decode(response.body);
          print('✅ Parsed ${data.length} results from LocationIQ');
          
          if (data.isNotEmpty) {
            final results = data.map((json) => LocationResult.fromJson(json)).toList();
            print('✅ Successfully created ${results.length} LocationResult objects');
            return results;
          } else {
            print('⚠️ LocationIQ returned empty results array');
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
        }
      } else {
        print('❌ LocationIQ API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ Network error fetching location: $e");
    }
    
    print('🔄 Falling back to OpenStreetMap Nominatim');
    return _tryNominatim(query);
  }

  // Try OpenStreetMap Nominatim as fallback
  static Future<List<LocationResult>> _tryNominatim(String query) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&countrycodes=ph';
      print('🗺️ Trying Nominatim: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('📊 Nominatim Status: ${response.statusCode}');
      print('📄 Nominatim Body: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final results = data.map((place) => LocationResult(
              displayName: place['display_name'] ?? '',
              lat: double.tryParse(place['lat'] ?? '0.0') ?? 0.0,
              lon: double.tryParse(place['lon'] ?? '0.0') ?? 0.0,
            )).toList();
            print('✅ Nominatim returned ${results.length} results');
            return results;
          }
        } catch (e) {
          print('❌ Nominatim JSON parsing error: $e');
        }
      } else {
        print('❌ Nominatim HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Nominatim network error: $e');
    }
    
    print('❌ All services failed, using built-in fallback');
    return _fallbackSearch(query);
  }

  // Geocoding: Convert address to coordinates
  static Future<LocationResult?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse('https://api.locationiq.com/v1/search?key=pk.faabc02907e60526bf767ce67fb1fe90&q=${Uri.encodeComponent(address)}&format=json&limit=1');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return LocationResult.fromJson(data[0]);
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    
    return _fallbackGeocode(address);
  }

  // Reverse Geocoding: Convert coordinates to address
  static Future<LocationResult?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse('https://api.locationiq.com/v1/reverse?key=pk.faabc02907e60526bf767ce67fb1fe90&lat=$latitude&lon=$longitude&format=json');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return LocationResult.fromJson(data);
        }
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    
    return _fallbackReverseGeocode(latitude, longitude);
  }

  // Fallback methods when API key is invalid or missing
  static Future<LocationResult?> _fallbackGeocode(String address) async {
    // Simple fallback - return location with approximate coordinates for major PH cities
    final Map<String, Map<String, double>> cityCoordinates = {
      'makati': {'lat': 14.5547, 'lon': 121.0244},
      'manila': {'lat': 14.5995, 'lon': 120.9842},
      'quezon city': {'lat': 14.6760, 'lon': 121.0438},
      'taguig': {'lat': 14.5176, 'lon': 121.0505},
      'pasay': {'lat': 14.5378, 'lon': 121.0015},
      'pasig': {'lat': 14.5764, 'lon': 121.0851},
      'mandaluyong': {'lat': 14.5794, 'lon': 121.0359},
      'san juan': {'lat': 14.6019, 'lon': 121.0365},
      'caloocan': {'lat': 14.6507, 'lon': 120.9754},
      'muntinlupa': {'lat': 14.4091, 'lon': 121.0198},
      'las piñas': {'lat': 14.4445, 'lon': 120.9769},
      'paranaque': {'lat': 14.4793, 'lon': 121.0197},
      'valenzuela': {'lat': 14.6998, 'lon': 120.9839},
      'marikina': {'lat': 14.6506, 'lon': 121.1089},
      'cebu': {'lat': 10.3157, 'lon': 123.8854},
      'davao': {'lat': 7.0731, 'lon': 125.6128},
    };

    final lowerAddress = address.toLowerCase();
    for (final city in cityCoordinates.keys) {
      if (lowerAddress.contains(city)) {
        final coords = cityCoordinates[city]!;
        return LocationResult(
          displayName: address,
          lat: coords['lat']!,
          lon: coords['lon']!,
        );
      }
    }

    return LocationResult(
      displayName: address,
      lat: 14.5995, // Default to Manila
      lon: 120.9842,
    );
  }

  static Future<LocationResult?> _fallbackReverseGeocode(double latitude, double longitude) async {
    return LocationResult(
      displayName: 'Location at $latitude, $longitude',
      lat: latitude,
      lon: longitude,
    );
  }

  static Future<List<LocationResult>> _fallbackSearch(String query) async {
    // Fallback search using popular Philippine locations
    final List<LocationResult> fallbackLocations = [
      LocationResult(
        displayName: 'Makati City, Metro Manila, Philippines',
        lat: 14.5547,
        lon: 121.0244,
      ),
      LocationResult(
        displayName: 'Bonifacio Global City, Taguig City, Metro Manila, Philippines',
        lat: 14.5426,
        lon: 121.0534,
      ),
      LocationResult(
        displayName: 'Ortigas Center, Pasig City, Metro Manila, Philippines',
        lat: 14.5847,
        lon: 121.0583,
      ),
      LocationResult(
        displayName: 'Quezon City, Metro Manila, Philippines',
        lat: 14.6398,
        lon: 121.0370,
      ),
      LocationResult(
        displayName: 'Manila, Metro Manila, Philippines',
        lat: 14.5995,
        lon: 120.9842,
      ),
      LocationResult(
        displayName: 'Pasay City, Metro Manila, Philippines',
        lat: 14.5378,
        lon: 121.0015,
      ),
      LocationResult(
        displayName: 'SM Mall of Asia, Pasay City, Metro Manila, Philippines',
        lat: 14.5358,
        lon: 120.9783,
      ),
      LocationResult(
        displayName: 'Cebu City, Philippines',
        lat: 10.3157,
        lon: 123.8854,
      ),
      LocationResult(
        displayName: 'Davao City, Philippines',
        lat: 7.0731,
        lon: 125.6128,
      ),
    ];

    final lowerQuery = query.toLowerCase();
    return fallbackLocations.where((location) => 
        location.name.toLowerCase().contains(lowerQuery) ||
        location.fullAddress.toLowerCase().contains(lowerQuery)
    ).take(5).toList();
  }
}

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;

  LocationResult({required this.displayName, required this.lat, required this.lon});

  // This "factory" converts the JSON map into a Flutter object
  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
    );
  }

  // Helper method for backward compatibility
  String get fullAddress => displayName;
  String get name => displayName.split(',').first.isNotEmpty ? displayName.split(',').first : displayName;
  double get latitude => lat;
  double get longitude => lon;
}
