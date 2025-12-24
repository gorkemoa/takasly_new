class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.takasly.tr/v2.0.0/';

  // Auth Endpoints
  static const String login = 'service/auth/login';
  static const String register = 'service/auth/register';
  static const String checkCode = 'service/auth/code/checkCode';
  static const String againSendCode = 'service/auth/code/againSendCode';
  static const String allProductList = 'service/user/product/allProductList';
  static const String productDetail =
      'service/user/product/'; // + {id}/productDetail

  // Auth Credentials
  static const String apiUser = 'Tk2BULs2IC4HJN2nlvp9T5ycBoyMJD';
  static const String apiPassword = 'vRP4rTBAqm1tm2I17I1EI3PHFtE5l0';

  // Event Endpoints
  static const String events = 'service/user/event/all';
  static const String eventDetail = 'service/user/event/'; // + {id}/detail
}
