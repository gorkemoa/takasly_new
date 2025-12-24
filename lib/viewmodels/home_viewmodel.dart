import 'package:flutter/material.dart';
import '../services/general_service.dart';
import '../models/home/home_models.dart';
import '../models/general_models.dart';
import 'package:logger/logger.dart';

class HomeViewModel extends ChangeNotifier {
  final GeneralService _generalService = GeneralService();
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
  String _sortType = 'default';
  String get sortType => _sortType;

  List<int> _selectedConditionIds = [];
  List<int> get selectedConditionIds => _selectedConditionIds;

  // Category State
  Category? _selectedCategory;
  Category? get selectedCategory => _selectedCategory;

  List<Category> _subCategories = [];
  List<Category> get subCategories => _subCategories;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchLogos(),
        fetchCategories(),
        fetchCities(),
        fetchConditions(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Home init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConditions() async {
    try {
      _conditions = await _generalService.getConditions();
    } catch (e) {
      _logger.e('Error fetching conditions: $e');
    }
  }

  Future<void> fetchCategories([int parentId = 0]) async {
    try {
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
    _sortType = 'default';
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
