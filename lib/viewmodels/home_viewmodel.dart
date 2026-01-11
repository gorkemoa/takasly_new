import 'package:flutter/material.dart';
import '../services/general_service.dart';
import '../models/products/product_models.dart';
import '../models/home/home_models.dart';
import '../models/general_models.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/cache_service.dart';

class HomeViewModel extends ChangeNotifier {
  final GeneralService _generalService = GeneralService();
  final CacheService _cacheService = CacheService();
  final Logger _logger = Logger();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeLogos? _logos;
  HomeLogos? get logos => _logos;

  bool _isCategoriesLoading = true;
  bool get isCategoriesLoading => _isCategoriesLoading;

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

  List<Popup> _popups = [];
  List<Popup> get popups => _popups;

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
    if (_categories.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch critical metadata in parallel
      // We wrap each in a catch block so one failure doesn't stop the others
      await Future.wait([
        fetchLogos().catchError((e) {
          _logger.w('Logos fetch failed: $e');
        }),
        fetchCategories(0, isRefresh).catchError((e) {
          _logger.e('Categories fetch failed: $e');
        }),
        fetchCities().catchError((e) {
          _logger.w('Cities fetch failed: $e');
        }),
        fetchConditions().catchError((e) {
          _logger.w('Conditions fetch failed: $e');
        }),
        fetchPopups().catchError((e) {
          _logger.w('Popups fetch failed: $e');
        }),
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
    _isCategoriesLoading = true;
    try {
      // If it's the root categories (parentId == 0) and not a refresh, try cache first
      // Cache logic removed as requested. Always fetch fresh.
      final response = await _generalService.getCategories(parentId);
      if (response['success'] == true && response['data'] != null) {
        final List cats = response['data']['categories'];
        final parsedCats = cats.map((e) => Category.fromJson(e)).toList();

        if (parentId == 0) {
          _categories = parsedCats;
        } else {
          _subCategories = parsedCats;
        }
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error fetching categories (parent: $parentId): $e');
    } finally {
      if (parentId == 0) {
        _isCategoriesLoading = false;
        notifyListeners();
      }
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
      fetchCategories(category!.catID!);
    }
    notifyListeners();
  }

  void setCategoryPath(Category finalCategory, List<Category> path) {
    _selectedCategory = finalCategory;
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

  Future<void> fetchPopups() async {
    try {
      final allPopups = await _generalService.getPopups();
      final hiddenPopupIds = await _cacheService.getHiddenPopups();

      // Filter logic:
      // If popupView == 1 (Show Once) and it's in hidden list -> Don't show
      // If popupView == 2 (Always Show) -> Always show (ignore hidden list or don't add to it)
      // Actually, if user checked "Don't show again", we probably shouldn't show it even if it was type 2 originally?
      // Requirement says: "1 gelirse checkbox koyarsın 1 kere göster diye cache de tuta"
      // So type 2 implies "Sürekli Göster" (Always Show), likely no checkbox.
      // So we only filter if it is in hidden list.

      _popups = allPopups.where((popup) {
        if (popup.popupID == null) return false;
        // If it's in hidden list, we don't show it.
        // Logic for adding to hidden list is in the View/VM action.
        return !hiddenPopupIds.contains(popup.popupID);
      }).toList();

      notifyListeners();
    } catch (e) {
      _logger.e('Error fetching popups: $e');
    }
  }

  Future<void> hidePopup(int popupId) async {
    await _cacheService.saveHiddenPopup(popupId);
    // Optionally remove from current _popups list if we want immediate feedback,
    // but usually this runs when dialog closes so list update for next launch is enough.
  }
}
