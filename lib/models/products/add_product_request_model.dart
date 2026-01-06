import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class AddProductRequestModel {
  final String userToken;
  final String productTitle;
  final String productDesc;
  final int categoryID;
  final int conditionID;
  final String tradeFor;
  final List<File> productImages;
  final String productCity;
  final String productDistrict;
  final double productLat;
  final double productLong;
  final int isShowContact; // 1 or 0
  final List<String>? existingImageUrlList;

  AddProductRequestModel({
    required this.userToken,
    required this.productTitle,
    required this.productDesc,
    required this.categoryID,
    required this.conditionID,
    required this.tradeFor,
    required this.productImages,
    required this.productCity,
    required this.productDistrict,
    required this.productLat,
    required this.productLong,
    this.isShowContact = 1,
    this.existingImageUrlList,
  });

  Map<String, String> toFields() {
    final fields = {
      'userToken': userToken,
      'productTitle': productTitle,
      'productDesc': productDesc,
      'categoryID': categoryID.toString(),
      'conditionID': conditionID.toString(),
      'tradeFor': tradeFor,
      'productCity': productCity,
      'productDistrict': productDistrict,
      'productLat': productLat.toString(),
      'productLong': productLong.toString(),
      'isShowContact': isShowContact.toString(),
    };

    if (existingImageUrlList != null && existingImageUrlList!.isNotEmpty) {
      for (int i = 0; i < existingImageUrlList!.length; i++) {
        // Send existing URLs as productImages[index] to avoid Map key collision
        // and allow backend to receive it as an array.
        fields['productImages[$i]'] = existingImageUrlList![i];
      }
    }

    return fields;
  }

  Future<List<http.MultipartFile>> toFiles() async {
    List<http.MultipartFile> files = [];
    for (var image in productImages) {
      var stream = http.ByteStream(image.openRead().cast());
      var length = await image.length();
      var multipartFile = http.MultipartFile(
        'productImages[]',
        stream,
        length,
        filename: basename(image.path),
      );
      files.add(multipartFile);
    }
    return files;
  }
}
