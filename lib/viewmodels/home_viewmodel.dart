import 'package:flutter/material.dart';
import '../services/general_service.dart';
import '../services/cache_service.dart';
import '../models/home/home_models.dart';
import '../models/general_models.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeViewModel extends ChangeNotifier {
  final GeneralService _generalService = GeneralService();
  final CacheService _cacheService = CacheService();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeLogos? _logos;
  HomeLogos? get logos => _logos;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<City> _cities = [];
  List<City> get cities => _cities;

  List<District> _districts = [];
  List<District> get districts => _districts;

  City? _selectedCity;
  City? get selectedCity => _selectedCity;

  District? _selectedDistrict;
  District? get selectedDistrict => _selectedDistrict;

  List<Condition> _conditions = [];
  List<Condition> get conditions => _conditions;

  // Filter State
  String _sortType = 'location';
  String get sortType => _sortType;

  List<int> _selectedConditionIds = [];
  List<int> get selectedConditionIds => _selectedConditionIds;

  // Category State
  Category? _selectedCategory;
  Category? get selectedCategory => _selectedCategory;

  List<Category> _subCategories = [];
  List<Category> get subCategories => _subCategories;

  Future<void> init({bool isRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch critical metadata in parallel
      // We pass isRefresh to allow forced category fetching
      await Future.wait([
        fetchLogos(),
        fetchCategories(0, isRefresh),
        fetchCities(),
        fetchConditions(),
      ]);

      // Basic data is ready, stop the main skeleton/loader
      _isLoading = false;
      notifyListeners();

      // 2. Start location detection in background
      detectUserLocation()
          .then((_) {
            _logger.i('Background location detection complete.');
          })
          .catchError((e) {
            _logger.e('Background location detection failed: $e');
          });
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Home init error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> detectUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permissions are permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();

      // Get placemarks (address info)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.administrativeArea; // e.g., "Ankara"
        final district =
            place.subAdministrativeArea; // e.g., "Yenimahalle" or "Çankaya"

        _logger.i(
          'Detected location (For Logs Only): City=$city, District=$district',
        );

        // Fix: Do NOT auto-populate filter fields.
        // The user wants these empty by default so they don't interfere with other filters.
        // The nearest listings are handled by ProductViewModel using coordinates, not these UI fields.
      }
    } catch (e) {
      _logger.e('Error auto-detecting location: $e');
      // Don't block the app flow if location detection fails
    }
  }

  Future<void> fetchConditions() async {
    try {
      _conditions = await _generalService.getConditions();
    } catch (e) {
      _logger.e('Error fetching conditions: $e');
    }
  }

  Future<void> fetchCategories([
    int parentId = 0,
    bool isRefresh = false,
  ]) async {
    try {
      // If it's the root categories (parentId == 0) and not a refresh, try cache first
      if (parentId == 0 && !isRefresh) {
        final cached = await _cacheService.getCategories();
        if (cached != null && cached.isNotEmpty) {
          _categories = cached;
          _logger.i('Loaded ${cached.length} categories from cache.');
          notifyListeners();

          // Check if cache is fresh enough (e.g., < 1 hour)
          final lastTime = await _cacheService.getCategoriesTime();
          if (lastTime != null) {
            final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTime);
            if (DateTime.now().difference(lastDate) <
                const Duration(hours: 1)) {
              _logger.i('Categories cache is fresh (< 1h), skipping API call.');
              return;
            }
          }
        }
      }

      final response = await _generalService.getCategories(parentId);
      if (response['success'] == true && response['data'] != null) {
        final List cats = response['data']['categories'];
        final parsedCats = cats.map((e) => Category.fromJson(e)).toList();

        if (parentId == 0) {
          _categories = parsedCats;
          // Save to cache
          await _cacheService.saveCategories(parsedCats);
        } else {
          _subCategories = parsedCats;
        }
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error fetching categories (parent: $parentId): $e');
    }
  }

  void setSortType(String type) {
    _sortType = type;
    notifyListeners();
  }

  void toggleCondition(int conditionId) {
    if (_selectedConditionIds.contains(conditionId)) {
      _selectedConditionIds.remove(conditionId);
    } else {
      _selectedConditionIds.add(conditionId);
    }
    notifyListeners();
  }

  void setSelectedCategory(Category? category) {
    _selectedCategory = category;
    _subCategories = []; // Reset subcategories
    if (category?.catID != null) {
      fetchCategories(category!.catID);
    }
    notifyListeners();
  }

  void clearFilters() {
    _selectedCity = null;
    _selectedDistrict = null;
    _districts = [];
    _sortType = 'location';
    _selectedConditionIds = [];
    _selectedCategory = null;
    _subCategories = [];
    notifyListeners();
  }

  Future<void> fetchLogos() async {
    try {
      final response = await _generalService.getLogos();
      if (response['success'] == true && response['data'] != null) {
        _logos = HomeLogos.fromJson(response['data']['logos']);
      }
    } catch (e) {
      _logger.e('Error fetching logos: $e');
      rethrow;
    }
  }

  Future<void> fetchCities() async {
    try {
      _cities = await _generalService.getCities();
    } catch (e) {
      _logger.e('Error fetching cities: $e');
    }
  }

  Future<void> fetchDistricts(int cityId) async {
    try {
      _districts = await _generalService.getDistricts(cityId);
      notifyListeners();
    } catch (e) {
      _logger.e('Error fetching districts: $e');
      _districts = [];
      notifyListeners();
    }
  }

  void setSelectedCity(City? city) {
    _selectedCity = city;
    _selectedDistrict = null;
    _districts = [];
    if (city?.cityNo != null) {
      fetchDistricts(city!.cityNo!);
    } else {
      notifyListeners();
    }
  }

  void setSelectedDistrict(District? district) {
    _selectedDistrict = district;
    notifyListeners();
  }
}
