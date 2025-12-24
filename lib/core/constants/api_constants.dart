class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.takasly.tr/v2.0.0/';

  // Auth Endpoints
  static const String login = 'service/auth/login';
  static const String register = 'service/auth/register';
  static const String loginSocial = 'service/auth/loginSocial';
  static const String checkCode = 'service/auth/code/checkCode';
  static const String againSendCode = 'service/auth/code/againSendCode';
  static const String forgotPassword = 'service/auth/forgotPassword';
  static const String updatePass = 'service/auth/forgotPassword/updatePass';
  static const String getUser = 'service/user/id';
  static const String getUserProfile =
      'service/user/account/'; // + {id}/profileDetail
  static const String allProductList = 'service/user/product/allProductList';
  static const String productDetail =
      'service/user/product/'; // + {id}/productDetail

  // Auth Credentials
  static const String apiUser = 'Tk2BULs2IC4HJN2nlvp9T5ycBoyMJD';
  static const String apiPassword = 'vRP4rTBAqm1tm2I17I1EI3PHFtE5l0';

  // Event Endpoints
  static const String events = 'service/user/event/all';
  static const String eventDetail = 'service/user/event/'; // + {id}/detail

  // General Endpoints
  static const String logos = 'service/general/general/logos';
  static const String categories =
      'service/general/general/categories/'; // + {parentId}
  static const String cities = 'service/general/general/cities/all';
  static const String districts =
      'service/general/general/districts/'; // + {cityId}

  // Notification Endpoints
  static const String notAllRead = 'service/user/account/notification/allRead';
  static const String notRead = 'service/user/account/notification/read';
  static const String notDelete = 'service/user/account/notification/delete';
  static const String notAllDelete =
      'service/user/account/notification/allDelete';
}
