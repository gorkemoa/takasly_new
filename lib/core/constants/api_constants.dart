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
  static const String favoriteList =
      'service/user/product/'; // + {id}/favoriteList
  static const String tradeList = 'service/user/product/'; // + {id}/tradeList
  static const String addFavorite = 'service/user/product/addFavorite';
  static const String removeFavorite = 'service/user/product/removeFavorite';
  static const String addProduct = 'service/user/product/'; // + {id}/addProduct

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
  static const String popularCategories =
      'service/general/general/popularCategories';
  static const String cities = 'service/general/general/cities/all';
  static const String districts =
      'service/general/general/districts/'; // + {cityId}
  static const String conditions = 'service/general/general/productConditions';

  // Contact Endpoints
  static const String contactSubjects = 'service/general/contact/subjects';
  static const String sendMessage = 'service/general/contact/sendMessage';

  // Notification Endpoints
  static const String notAllRead = 'service/user/account/notification/allRead';
  static const String notRead = 'service/user/account/notification/read';
  static const String notDelete = 'service/user/account/notification/delete';
  static const String notAllDelete =
      'service/user/account/notification/allDelete';

  // Account Management
  static const String updateUser = 'service/user/update/account';
  static const String changePassword = 'service/user/update/password';
  static const String deleteUser = 'service/user/account/delete';
  static const String userTickets = 'service/user/account/tickets/list';
  static const String ticketMessages = 'service/user/account/tickets/messages';
  static const String ticketDetail = 'service/user/account/tickets/detail';
  static const String addMessage = 'service/user/account/tickets/addMessage';
  static const String reportUser = 'service/user/product/reportUser';
  static const String userBlocked = 'service/user/account/userBlocked';
  static const String blockedUsers =
      'service/user/account/'; // + {id}/blockedUsers
  static const String userUnBlocked = 'service/user/account/userUnBlocked';
}
