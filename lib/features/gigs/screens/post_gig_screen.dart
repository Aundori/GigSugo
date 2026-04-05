import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/location_iq_service.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class PostGigScreen extends ConsumerStatefulWidget {
  const PostGigScreen({super.key});

  @override
  ConsumerState<PostGigScreen> createState() => _PostGigScreenState();
}

class _PostGigScreenState extends ConsumerState<PostGigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  
  String _selectedEventType = 'Wedding';
  
  final List<String> _eventTypes = [
    'Wedding',
    'Corporate', 
    'Bar/Club',
    'Party',
    'Café',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submitGig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance.collection('gig_listings').add({
        'clientId': userId,
        'title': _titleController.text.trim(),
        'tag': _selectedEventType,        // Changed from eventType to tag
        'date': _dateController.text.trim(),
        'budget': _budgetController.text.trim(),
        'location': _locationController.text.trim(),
        'genre': _genreController.text.trim(),  // Changed from genreNeeded to genre
        'description': _descriptionController.text.trim(),
        'duration': _durationController.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'applicantCount': 0,
      });

      if (mounted) {
        context.go('/client-home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gig posted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error posting gig: $e',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.bg,
              ),
            ),
            backgroundColor: const Color(0xFFE74C3C),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/client-home'),
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1C2338)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.amber,
            ),
          ),
        ),
        title: const Text(
          'Post a Gig',
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gig Title
              _buildSectionLabel('GIG TITLE'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _titleController,
                icon: Icon(Icons.title, size: 20, color: AppColors.amber),
                hintText: 'Enter gig title',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a gig title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Event Type
              _buildSectionLabel('EVENT TYPE'),
              const SizedBox(height: 8),
              _buildEventTypeFilters(),
              
              const SizedBox(height: 24),
              
              // Date and Budget Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('DATE'),
                        const SizedBox(height: 8),
                        _buildTextInput(
                          controller: _dateController,
                          icon: Icon(Icons.calendar_today, size: 20, color: AppColors.amber),
                          hintText: 'Select date',
                          isDateField: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('BUDGET'),
                        const SizedBox(height: 8),
                        _buildTextInput(
                          controller: _budgetController,
                          icon: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '₱',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ),
                          hintText: '0',
                          prefixText: '₱',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Duration
              _buildSectionLabel('DURATION'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _durationController,
                icon: Icon(Icons.access_time, size: 20, color: AppColors.amber),
                hintText: 'e.g., 2-3 hours',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Location
              _buildSectionLabel('LOCATION'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _locationController,
                icon: Icon(Icons.location_on, size: 20, color: AppColors.amber),
                hintText: 'Enter location',
                isLocationField: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Genre Needed
              _buildSectionLabel('GENRE NEEDED'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _genreController,
                icon: Icon(Icons.music_note, size: 20, color: AppColors.amber),
                hintText: 'Enter genre needed',
              ),
              
              const SizedBox(height: 24),
              
              // Description
              _buildSectionLabel('DESCRIPTION'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _descriptionController,
                icon: Icon(Icons.description, size: 20, color: AppColors.amber),
                hintText: 'Describe your gig...',
                maxLines: 4,
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitGig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Post Gig',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'post', userType: 'client'),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.muted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required Widget icon,
    required String hintText,
    String? prefixText,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isDateField = false,
    bool isLocationField = false,
  }) {
    if (isDateField) {
      // Special handling for date field
      return GestureDetector(
        onTap: () {
          print('Date field tapped - opening date picker');
          _selectDate(context, controller);
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 48,
            maxHeight: 120,
          ),
          decoration: BoxDecoration(
            color: AppColors.card2,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  controller.text.isEmpty ? hintText : controller.text,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: controller.text.isEmpty ? AppColors.muted : AppColors.text,
                  ),
                ),
                const Spacer(),
                if (prefixText != null)
                  Text(
                    prefixText!,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.text,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Regular text field with optional clickable location icon
    return Container(
      constraints: const BoxConstraints(
        minHeight: 48,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: AppColors.card2,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          prefixText: prefixText,
          prefixIcon: isLocationField 
            ? GestureDetector(
                onTap: () {
                  print('Location icon tapped - opening location picker');
                  _openLocationPicker(controller);
                },
                child: icon,
              )
            : icon,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: AppColors.muted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    print('_selectDate called');
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2027, 12, 31),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.amber,
                onPrimary: Colors.black,
                surface: const Color(0xFF1E2330),
                onSurface: Colors.white,
                background: const Color(0xFF0A0E1A),
                onBackground: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF0A0E1A),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.amber,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      print('Date picker result: $picked');
      if (picked != null) {
        final formattedDate = '${picked.month}/${picked.day}/${picked.year}';
        print('Formatted date: $formattedDate');
        controller.text = formattedDate;
        print('Controller text set to: ${controller.text}');
        
        // Force rebuild to update the UI
        if (mounted) {
          setState(() {});
          print('setState called to rebuild UI');
        }
      } else {
        print('No date selected');
      }
    } catch (e) {
      print('Error in date picker: $e');
    }
  }

  Future<void> _openLocationPicker(TextEditingController controller) async {
    try {
      // Show enhanced location selection dialog
      final result = await showDialog<LocationResult>(
        context: context,
        builder: (BuildContext context) {
          return _EnhancedLocationPickerDialog(
            controller: controller,
          );
        },
      );

      if (result != null) {
        controller.text = result.fullAddress;
        setState(() {});
        print('Location selected: ${result.fullAddress}');
        print('Coordinates: ${result.latitude}, ${result.longitude}');
      }
    } catch (e) {
      print('Error opening location picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open location picker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEventTypeFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _eventTypes.map((eventType) {
        final isSelected = eventType == _selectedEventType;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEventType = eventType;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.amber : AppColors.card2,
              border: Border.all(
                color: isSelected ? AppColors.amber : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              eventType,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.bg : AppColors.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class VenueLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  VenueLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class _EnhancedLocationPickerDialog extends StatefulWidget {
  final TextEditingController controller;

  const _EnhancedLocationPickerDialog({required this.controller});

  @override
  State<_EnhancedLocationPickerDialog> createState() => _EnhancedLocationPickerDialogState();
}

class _EnhancedLocationPickerDialogState extends State<_EnhancedLocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<VenueLocation> _popularVenues = [
    VenueLocation(
      name: 'Makati Shangri-La',
      address: 'Makati Avenue, Makati City, 1200 Metro Manila',
      latitude: 14.5547,
      longitude: 121.0244,
    ),
    VenueLocation(
      name: 'Bonifacio High Street',
      address: 'Bonifacio Global City, Taguig City, 1630 Metro Manila',
      latitude: 14.5426,
      longitude: 121.0534,
    ),
    VenueLocation(
      name: 'SM Mall of Asia',
      address: 'Pasay City, 1300 Metro Manila',
      latitude: 14.5358,
      longitude: 120.9783,
    ),
    VenueLocation(
      name: 'Ortigas Center',
      address: 'Ortigas Center, Pasig City, 1600 Metro Manila',
      latitude: 14.5847,
      longitude: 121.0583,
    ),
    VenueLocation(
      name: 'Quezon City Circle',
      address: 'Quezon City, 1100 Metro Manila',
      latitude: 14.6760,
      longitude: 121.0438,
    ),
    VenueLocation(
      name: 'Intramuros Manila',
      address: 'Intramuros, Manila, 1002 Metro Manila',
      latitude: 14.5893,
      longitude: 120.9769,
    ),
    VenueLocation(
      name: 'Resorts World Manila',
      address: 'Newport City, Pasay City, 1300 Metro Manila',
      latitude: 14.5367,
      longitude: 121.0405,
    ),
    VenueLocation(
      name: 'Ayala Museum',
      address: 'Makati Avenue, Makati City, 1200 Metro Manila',
      latitude: 14.5585,
      longitude: 121.0225,
    ),
  ];

  List<VenueLocation> _filteredVenues = [];
  List<LocationResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _filteredVenues = _popularVenues;
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    print('🔍 Performing search for: "$query"');
    
    if (query.isEmpty) {
      setState(() {
        _filteredVenues = _popularVenues;
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    // Filter popular venues
    final filteredPopularVenues = _popularVenues
        .where((venue) => 
            venue.name.toLowerCase().contains(query.toLowerCase()) ||
            venue.address.toLowerCase().contains(query.toLowerCase()))
        .toList();

    print('📍 Filtered popular venues: ${filteredPopularVenues.length}');

    // Search using LocationIQ
    print('🌐 Calling LocationIQ API...');
    final locationResults = await LocationIQService.searchPlaces(query);
    print('📊 LocationIQ returned ${locationResults.length} results');

    setState(() {
      _filteredVenues = filteredPopularVenues;
      _searchResults = locationResults;
      _isSearching = false;
    });
    
    print('✅ Search complete - Popular: ${filteredPopularVenues.length}, LocationIQ: ${locationResults.length}');
  }

  Future<void> _selectLocation(LocationResult location) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
    );

    try {
      // Get more detailed address using geocoding
      final detailedLocation = await LocationIQService.geocodeAddress(location.fullAddress);
      
      // Close loading indicator
      Navigator.pop(context);
      
      // Return the location (use detailed if available, otherwise use original)
      Navigator.pop(context, detailedLocation ?? location);
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      print('📍 Getting current location...');
      
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please enable them in settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('📍 Got coordinates: ${position.latitude}, ${position.longitude}');

      // Reverse geocode to get address
      print('🔄 Reverse geocoding coordinates...');
      final locationResult = await LocationIQService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (locationResult != null) {
        print('✅ Reverse geocoding successful: ${locationResult.displayName}');
        
        // Clear search and show current location
        setState(() {
          _searchController.text = locationResult.displayName;
          _searchResults = [locationResult];
          _showSearchResults = true;
          _isGettingLocation = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location detected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Could not get address for your location.');
      }
    } catch (e) {
      print('❌ Error getting current location: $e');
      
      setState(() {
        _isGettingLocation = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openMapForVenue(VenueLocation venue) async {
    final Uri mapUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': venue.address,
      },
    );

    print('Opening map for venue: ${venue.name}');
    print('Map URL: $mapUri');

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(
          mapUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Error opening map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open map: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMapForLocation(LocationResult location) async {
    final Uri mapUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': location.fullAddress,
      },
    );

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(
          mapUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Error opening map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.amber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Search or choose from popular venues',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Field and Current Location Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for a location...',
                        hintStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                        prefixIcon: const Icon(Icons.search, color: AppColors.amber, size: 20),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Current Location Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.amber,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location, color: AppColors.amber, size: 18),
                      label: Text(
                        _isGettingLocation ? 'Getting Location...' : 'Use Current Location',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.amber.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Custom Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      icon: const Icon(Icons.edit_location_alt, color: AppColors.text, size: 18),
                      label: const Text(
                        'Enter Custom Location',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Venue List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Results Section
                    if (_showSearchResults && _searchResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Search Results',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                      ..._searchResults.map((location) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.search, color: AppColors.amber, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location.name,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          location.fullAddress,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12,
                                            color: AppColors.muted,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openMapForLocation(location),
                                    icon: const Icon(Icons.map, color: AppColors.amber, size: 16),
                                    label: const Text(
                                      'View Map',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        color: AppColors.amber,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.amber.withOpacity(0.1),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _selectLocation(location),
                                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    label: const Text(
                                      'Select',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.green.withOpacity(0.1),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: AppColors.border.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Popular Venues Section
                    if (!_showSearchResults || _searchResults.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Popular Venues',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                    
                    // Loading indicator
                    if (_isSearching)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
                              SizedBox(height: 12),
                              Text(
                                'Searching...',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Popular Venues List
                    if (!_isSearching)
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredVenues.length,
                          itemBuilder: (context, index) {
                            final venue = _filteredVenues[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border.withOpacity(0.2)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.amber.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.place, color: AppColors.amber, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                venue.name,
                                                style: const TextStyle(
                                                  fontFamily: 'DM Sans',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                venue.address,
                                                style: const TextStyle(
                                                  fontFamily: 'DM Sans',
                                                  fontSize: 12,
                                                  color: AppColors.muted,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _openMapForVenue(venue),
                                          icon: const Icon(Icons.map, color: AppColors.amber, size: 16),
                                          label: const Text(
                                            'View Map',
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              color: AppColors.amber,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor: AppColors.amber.withOpacity(0.1),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context, LocationResult(
                                              displayName: venue.address,
                                              lat: venue.latitude,
                                              lon: venue.longitude,
                                            ));
                                          },
                                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          label: const Text(
                                            'Select',
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.green.withOpacity(0.1),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // No Results Message
                    if (_showSearchResults && _searchResults.isEmpty && !_isSearching) ...[
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.card2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange, size: 32),
                                const SizedBox(height: 12),
                                const Text(
                                  'No locations found',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try different keywords',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Custom Location Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_searchController.text.isNotEmpty) {
                          // Open Google Maps for custom location search
                          final Uri searchUri = Uri(
                            scheme: 'https',
                            host: 'www.google.com',
                            path: '/maps/search/',
                            queryParameters: {'q': _searchController.text},
                          );
                          
                          if (await canLaunchUrl(searchUri)) {
                            await launchUrl(searchUri, mode: LaunchMode.externalApplication);
                            
                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.card,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: const Text('Confirm Location'),
                                content: Text(
                                  'Have you confirmed the location on Google Maps?\n\n'
                                  'Location: ${_searchController.text}',
                                  style: const TextStyle(color: AppColors.text),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.amber,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              Navigator.pop(context, LocationResult(
                                displayName: _searchController.text,
                                lat: 0.0, // Would need geocoding for real coords
                                lon: 0.0,
                              ));
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text(
                        'Search Custom Location',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 Search for specific addresses or landmarks',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebMapSelectionDialog extends StatefulWidget {
  final Position currentPosition;
  final Function(LocationResult) onLocationSelected;

  const _WebMapSelectionDialog({
    required this.currentPosition,
    required this.onLocationSelected,
  });

  @override
  State<_WebMapSelectionDialog> createState() => _WebMapSelectionDialogState();
}

class _WebMapSelectionDialogState extends State<_WebMapSelectionDialog> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  final List<MapLocation> _mapLocations = [
    MapLocation(
      name: 'Makati City',
      address: 'Makati City, Metro Manila, Philippines',
      latitude: 14.5547,
      longitude: 121.0244,
    ),
    MapLocation(
      name: 'Bonifacio Global City',
      address: 'BGC, Taguig City, Metro Manila, Philippines',
      latitude: 14.5426,
      longitude: 121.0534,
    ),
    MapLocation(
      name: 'Manila City',
      address: 'Manila, Metro Manila, Philippines',
      latitude: 14.5995,
      longitude: 120.9842,
    ),
    MapLocation(
      name: 'Quezon City',
      address: 'Quezon City, Metro Manila, Philippines',
      latitude: 14.6760,
      longitude: 121.0438,
    ),
    MapLocation(
      name: 'Pasay City',
      address: 'Pasay City, Metro Manila, Philippines',
      latitude: 14.5378,
      longitude: 121.0015,
    ),
    MapLocation(
      name: 'Mall of Asia',
      address: 'SM Mall of Asia, Pasay City, Philippines',
      latitude: 14.5358,
      longitude: 120.9783,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _latController.text = widget.currentPosition.latitude.toStringAsFixed(6);
    _lonController.text = widget.currentPosition.longitude.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.map, color: AppColors.amber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Choose from popular locations or enter coordinates',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Popular Locations
                    const Text(
                      'Popular Locations',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._mapLocations.map((location) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.place, color: AppColors.amber, size: 20),
                        ),
                        title: Text(
                          location.name,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          location.address,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.muted, size: 16),
                        onTap: () => _selectMapLocation(location),
                      ),
                    )),
                    
                    const SizedBox(height: 20),
                    
                    // Manual Entry
                    const Text(
                      'Enter Coordinates Manually',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              labelStyle: const TextStyle(
                                fontFamily: 'DM Sans',
                                color: AppColors.muted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.amber),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lonController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              labelStyle: const TextStyle(
                                fontFamily: 'DM Sans',
                                color: AppColors.muted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.amber),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _addressController,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Address (optional)',
                              labelStyle: const TextStyle(
                                fontFamily: 'DM Sans',
                                color: AppColors.muted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.amber),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _reverseGeocodeCoordinates,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Get Address & Select',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.card2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final Uri mapUri = Uri(
                          scheme: 'https',
                          host: 'www.google.com',
                          path: '/maps',
                          queryParameters: {
                            'q': '${widget.currentPosition.latitude},${widget.currentPosition.longitude}',
                          },
                        );
                        
                        if (await canLaunchUrl(mapUri)) {
                          await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card2,
                        foregroundColor: AppColors.text,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Open Google Maps',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMapLocation(MapLocation location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationResult = LocationResult(
        displayName: location.address,
        lat: location.latitude,
        lon: location.longitude,
      );
      widget.onLocationSelected(locationResult);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reverseGeocodeCoordinates() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid latitude and longitude'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Reverse geocoding coordinates: $lat, $lon');
      final locationResult = await LocationIQService.reverseGeocode(lat, lon);

      if (locationResult != null) {
        print('✅ Reverse geocoding successful: ${locationResult.displayName}');
        widget.onLocationSelected(locationResult);
      } else {
        print('⚠️ Could not get address for coordinates');
        // Use coordinates as address if reverse geocoding fails
        final fallbackLocation = LocationResult(
          displayName: _addressController.text.isNotEmpty 
              ? _addressController.text 
              : 'Location ($lat, $lon)',
          lat: lat,
          lon: lon,
        );
        widget.onLocationSelected(fallbackLocation);
      }
    } catch (e) {
      print('❌ Error reverse geocoding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class MapLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  MapLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
