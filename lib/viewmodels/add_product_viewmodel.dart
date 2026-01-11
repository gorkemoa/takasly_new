import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/product_service.dart';
import '../services/general_service.dart';
import '../services/api_service.dart';
import '../services/analytics_service.dart';
import '../services/in_app_review_service.dart';
import '../models/products/add_product_request_model.dart';
import '../models/general_models.dart';
import '../models/products/product_models.dart'
    show
        Category; // Use Category from product models if general models doesn't have it, or check definition.

// Checking imports: GeneralService returns specific models.
// I'll assume Category is in product_models as seen in Product structure,
// or I'll check where SearchViewModel gets it. SearchViewModel imports product_models hide Category
// and imports general_models. But general_models didn't show Category.
// Let's check SearchViewModel again. It says "import '../models/products/product_models.dart' hide Category;"
// and "import '../models/general_models.dart';"
// Wait, SearchViewModel has "List<Category> categories = [];". Where does this Category come from?
// It comes from... wait. SearchViewModel imports `product_models` hiding `Category`.
// So `Category` must be in `general_models`? But I just read `general_models.dart` and it only had City, District, Condition, ContactSubject.
// Ah, SearchViewModel line 103: `categories = cats.map((e) => Category.fromJson(e)).toList();`.
// If `general_models` doesn't have it, maybe it's defined in `SearchViewModel` file or implicitly imported?
// Re-reading `SearchViewModel`:
// `import '../models/products/product_models.dart' hide Category;`
// `import '../models/general_models.dart';`
// Maybe I missed it in `general_models` because of scroll? Or maybe it's in `product_models` and I misread the hide?
// Actually `product_models` HAD `Category` class at the bottom!
// So SearchViewModel hides it... why?
// "List<Category> categories = []; // For filter selection if needed"
// If it hides it from product_models, where does it get it?
// Maybe `popular_category_model.dart`?
// Let's assume `Category` is in `product_models.dart` and just use that one.

class AddProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController tradeForController = TextEditingController();

  // Models
  List<Category> categories = [];
  // Multi-level Subcategories
  List<List<Category>> categoryLevels = [];
  List<Category?> selectedSubCategories = [];

  List<Condition> conditions = [];
  List<City> cities = [];
  List<District> districts = [];

  // Selections
  Category? selectedCategory; // Main category
  Condition? selectedCondition;
  City? selectedCity;
  District? selectedDistrict;
  bool isShowContact = true;

  // Images
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Location
  double? productLat;
  double? productLong;

  bool isLoading = false;
  bool isDistrictsLoading = false;
  bool isLocationLoading = false;
  String? errorMessage;

  // Init
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      // Start all fetches in parallel
      final catFuture = _fetchCategories();
      final condFuture = _fetchConditions();
      final cityFuture = _fetchCities();

      // Only wait for Categories to show the first step
      await catFuture;

      isLoading = false;
      notifyListeners();

      // The other futures continue in the background.
      // They call notifyListeners() themselves when finished.
      await Future.wait([condFuture, cityFuture]);
    } catch (e) {
      errorMessage = "Başlangıç verileri yüklenemedi: $e";
      _logger.e(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetchers
  Future<void> _fetchCategories() async {
    try {
      final response = await _generalService
          .getCategories(); // Gets all top level
      if (response['success'] == true && response['data'] != null) {
        if (response['data']['categories'] == null) return;
        final List list = response['data']['categories'];
        categories = list.map((e) => Category.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error fetching categories: $e");
    }
  }

  Future<bool> _fetchSubCategories(int parentId, int levelIndex) async {
    try {
      final response = await _generalService.getCategories(parentId);
      if (response['success'] == true && response['data'] != null) {
        if (response['data']['categories'] == null) return false;
        final List list = response['data']['categories'];
        final newOptions = list.map((e) => Category.fromJson(e)).toList();

        if (newOptions.isNotEmpty) {
          if (levelIndex < categoryLevels.length) {
            categoryLevels[levelIndex] = newOptions;
            selectedSubCategories[levelIndex] = null;
          } else {
            categoryLevels.add(newOptions);
            selectedSubCategories.add(null);
          }
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.e("Error fetching sub-categories level $levelIndex: $e");
      return false;
    }
  }

  Future<void> _fetchConditions() async {
    try {
      final result = await _generalService.getConditions();
      if (result.isNotEmpty) {
        conditions = result;
        notifyListeners();
      } else {
        _logger.w("fetched conditions is empty");
      }
    } catch (e) {
      _logger.e("Error fetching conditions: $e");
    }
  }

  Future<void> _fetchCities() async {
    try {
      final result = await _generalService.getCities();
      if (result.isNotEmpty) {
        cities = result;
        notifyListeners();
      } else {
        _logger.w("fetched cities is empty");
      }
    } catch (e) {
      _logger.e("Error fetching cities: $e");
    }
  }

  // Setters
  Future<bool> setSelectedCategory(Category? category) async {
    selectedCategory = category;

    // Reset all sub levels
    categoryLevels.clear();
    selectedSubCategories.clear();

    notifyListeners();

    if (category?.catID != null) {
      return await _fetchSubCategories(category!.catID!, 0);
    }
    return false;
  }

  Future<bool> onSubCategoryChanged(int levelIndex, Category? category) async {
    // Update selection at this level
    if (levelIndex < selectedSubCategories.length) {
      selectedSubCategories[levelIndex] = category;
    }

    // Remove any deeper levels because the path changed
    if (levelIndex + 1 < categoryLevels.length) {
      categoryLevels.removeRange(levelIndex + 1, categoryLevels.length);
      selectedSubCategories.removeRange(
        levelIndex + 1,
        selectedSubCategories.length,
      );
    }

    notifyListeners();

    // Fetch next level if a valid category was selected
    if (category?.catID != null) {
      return await _fetchSubCategories(category!.catID!, levelIndex + 1);
    }
    return false;
  }

  void setCategoryPath(Category finalCategory, List<Category> path) {
    if (path.isEmpty) return;

    selectedCategory = path.first;
    if (path.length > 1) {
      selectedSubCategories = path.sublist(1);
    } else {
      selectedSubCategories = [];
    }
    notifyListeners();
  }

  void setSelectedCondition(Condition? condition) {
    selectedCondition = condition;
    notifyListeners();
  }

  void setSelectedDistrict(District? district) {
    selectedDistrict = district;
    notifyListeners();
  }

  void setShowContact(bool value) {
    isShowContact = value;
    notifyListeners();
  }

  Future<void> onCityChanged(City? city) async {
    selectedCity = city;
    selectedDistrict = null;
    districts = [];
    notifyListeners();

    if (city != null && city.cityNo != null) {
      try {
        isDistrictsLoading = true; // Local load for districts
        notifyListeners();
        districts = await _generalService.getDistricts(city.cityNo!);
      } catch (e) {
        _logger.e("Error fetching districts: $e");
      } finally {
        isDistrictsLoading = false;
        notifyListeners();
      }
    }
  }

  // Image Logic
  Future<void> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      if (pickedFiles.isNotEmpty) {
        selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error picking images: $e");
      errorMessage = "Resim seçilirken hata oluştu.";
      notifyListeners();
    }
  }

  Future<bool> pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        selectedImages.add(File(photo.path));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _logger.e("Error picking from camera: $e");
      errorMessage = "Fotoğraf çekilirken hata oluştu.";
      notifyListeners();
      return false;
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void makeCoverImage(int index) {
    if (index > 0 && index < selectedImages.length) {
      final image = selectedImages.removeAt(index);
      selectedImages.insert(0, image);
      notifyListeners();
    }
  }

  // Location Logic
  Future<void> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = "Konum servisi kapalı.";
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = "Konum izni reddedildi.";
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage = "Konum izni kalıcı olarak reddedildi.";
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage = "Konum izni kalıcı olarak reddedildi.";
        notifyListeners();
        return;
      }

      isLocationLoading = true;
      notifyListeners();

      Position position = await Geolocator.getCurrentPosition();
      productLat = position.latitude;
      productLong = position.longitude;

      // Reverse Geocoding
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final detectedCityName = place.administrativeArea; // e.g., "Ankara"
          final detectedDistrictName =
              place.subAdministrativeArea; // e.g. "Cankaya"

          if (detectedCityName != null) {
            // Find matching city
            // Normalize strings for better matching (simple approach: uppercase/lowercase check)
            // Ideally use a normalization helper for Turkish chars if needed
            final matchedCity = cities.firstWhere(
              (c) =>
                  c.cityName?.toLowerCase() == detectedCityName.toLowerCase(),
              orElse: () => City(), // Return empty if not found
            );

            if (matchedCity.cityNo != null) {
              selectedCity = matchedCity;

              // Now fetch districts for this city
              isDistrictsLoading = true;
              notifyListeners();

              final districtsResult = await _generalService.getDistricts(
                matchedCity.cityNo!,
              );
              districts = districtsResult;

              isDistrictsLoading = false;

              // Find matching district
              if (detectedDistrictName != null) {
                final matchedDistrict = districts.firstWhere(
                  (d) =>
                      d.districtName?.toLowerCase() ==
                      detectedDistrictName.toLowerCase(),
                  orElse: () => District(),
                );

                if (matchedDistrict.districtNo != null) {
                  selectedDistrict = matchedDistrict;
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.e("Reverse geocoding error: $e");
        // We don't block the flow if address matching fails,
        // the user still has the coordinates set.
      }
    } catch (e) {
      _logger.e("Location error: $e");
      errorMessage = "Konum alınamadı.";
    } finally {
      isLocationLoading = false;
      notifyListeners();
    }
  }

  // Submission
  Future<int?> submitProduct(String userToken, int userId) async {
    // Validation is relaxed to let the API handle errors/warnings as per user request.
    // if (!_validate()) return null;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final request = AddProductRequestModel(
        userToken: userToken,
        productTitle: titleController.text.trim(),
        productDesc: descController.text.trim(),
        // Get the deepest selected category
        categoryID: _getLastSelectedCategoryId(), // Now safe
        conditionID: selectedCondition?.id ?? 0,
        tradeFor: tradeForController.text.trim(),
        productImages: selectedImages,
        productCity: selectedCity?.cityNo?.toString() ?? "0",
        productDistrict: selectedDistrict?.districtNo?.toString() ?? "0",
        productLat: productLat ?? 0.0,
        productLong: productLong ?? 0.0,
        isShowContact: isShowContact ? 1 : 0,
      );

      final productId = await _productService.addProduct(request, userId);

      if (productId != null) {
        AnalyticsService().logEvent(
          'complete_add_product',
          parameters: {
            'product_id': productId,
            'category_id': request.categoryID,
            'city_id': request.productCity,
          },
        );
        InAppReviewService().incrementActionAndCheck();
      }

      return productId;
    } catch (e) {
      _logger.e("Submit error: $e");
      if (e is BusinessException) {
        errorMessage = e.message;
      } else {
        errorMessage = "Ürün yüklenirken bir hata oluştu: $e";
      }
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sponsorProduct(String userToken, int productId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _productService.sponsorProduct(userToken, productId);
      AnalyticsService().logEvent(
        'sponsor_product',
        parameters: {'product_id': productId},
      );
      return true;
    } catch (e) {
      _logger.e("Sponsor error: $e");
      errorMessage = "Ürün öne çıkarılırken hata oluştu: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Determine which step has missing data for auto-navigation
  int? getFirstMissingStep() {
    // Step 0: General Info
    if (titleController.text.trim().isEmpty) return 0;
    if (selectedCategory == null) return 0;
    for (int i = 0; i < categoryLevels.length; i++) {
      if (selectedSubCategories[i] == null) return 0;
    }

    // Step 1: Details (Condition)
    if (selectedCondition == null) return 1;

    // Step 2: Images & Desc
    // Images are critical
    if (selectedImages.isEmpty) return 2;
    if (descController.text.trim().isEmpty) return 2;

    // Step 3: Location & Publish
    if (selectedCity == null || selectedDistrict == null) return 3;
    if (productLat == null || productLong == null) return 3;

    return null;
  }

  int _getLastSelectedCategoryId() {
    if (selectedSubCategories.isNotEmpty) {
      // Iterate backwards to find the last non-null selection
      for (int i = selectedSubCategories.length - 1; i >= 0; i--) {
        if (selectedSubCategories[i] != null) {
          return selectedSubCategories[i]!.catID ?? 0;
        }
      }
    }
    return selectedCategory?.catID ?? 0;
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    tradeForController.dispose();
    super.dispose();
  }
}

// Removed local BusinessException class to use the one from api_service.dart
