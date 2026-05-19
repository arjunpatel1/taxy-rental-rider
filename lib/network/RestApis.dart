import 'package:taxi_booking/model/PolyLineData.dart';
import 'package:taxi_booking/model/search_location_model.dart';
import 'package:taxi_booking/model/select_location_model.dart';

import '../manage_imports.dart';

Future<LoginResponse> signUpApi(Map request) async {
  Response response = await buildHttpResponse('register', request: request, method: HttpMethod.POST);

  if (!(response.statusCode >= 200 && response.statusCode <= 206)) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((json) async {
    var loginResponse = LoginResponse.fromJson(json);

    if (loginResponse.data!.loginType == 'mobile') {
      await sharedPref.setString(TOKEN, loginResponse.data!.apiToken.validate());
      await sharedPref.setString(USER_TYPE, loginResponse.data!.userType.validate());
      await sharedPref.setString(FIRST_NAME, loginResponse.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, loginResponse.data!.lastName.validate());
      await sharedPref.setString(CONTACT_NUMBER, loginResponse.data!.contactNumber.validate());
      await sharedPref.setString(USER_EMAIL, loginResponse.data!.email.validate());
      await sharedPref.setString(USER_NAME, loginResponse.data!.username.validate());
      await sharedPref.setString(ADDRESS, loginResponse.data!.address.validate());
      await sharedPref.setInt(USER_ID, loginResponse.data!.id!);
      await sharedPref.setString(USER_PROFILE_PHOTO, loginResponse.data!.profileImage.validate());
      await sharedPref.setString(GENDER, loginResponse.data!.gender.validate());
      await sharedPref.setString(LOGIN_TYPE, loginResponse.data!.loginType.validate());
      await appStore.setLoggedIn(true);
      await appStore.setUserEmail(loginResponse.data!.email.validate());
      await sharedPref.setString(UID, loginResponse.data!.uid.validate());
      await appStore.setUserProfile(loginResponse.data!.profileImage.validate());
      await appStore.setReferralCode(loginResponse.data!.referralCode.validate());
    }

    return loginResponse;
  });
}

Future<LoginResponse> logInApi(Map request, {bool isSocialLogin = false}) async {
  Response response = await buildHttpResponse(isSocialLogin ? 'social-login' : 'login', request: request, method: HttpMethod.POST);

  if (!(response.statusCode >= 200 && response.statusCode <= 206)) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((json) async {
    var loginResponse = LoginResponse.fromJson(json);
    if (loginResponse.data != null) {
      await sharedPref.setString(TOKEN, loginResponse.data!.apiToken.validate());
      await sharedPref.setString(USER_TYPE, loginResponse.data!.userType.validate());
      await sharedPref.setString(FIRST_NAME, loginResponse.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, loginResponse.data!.lastName.validate());
      await sharedPref.setString(CONTACT_NUMBER, loginResponse.data!.contactNumber.validate());
      await sharedPref.setString(USER_EMAIL, loginResponse.data!.email.validate());
      await sharedPref.setString(USER_NAME, loginResponse.data!.username.validate());
      await sharedPref.setString(ADDRESS, loginResponse.data!.address.validate());
      await sharedPref.setInt(USER_ID, loginResponse.data!.id ?? 0);
      await sharedPref.setString(USER_PROFILE_PHOTO, loginResponse.data!.profileImage.validate());
      await sharedPref.setString(GENDER, loginResponse.data!.gender.validate());
      await sharedPref.setString(LOGIN_TYPE, loginResponse.data!.loginType.validate());
      await appStore.setLoggedIn(true);
      await appStore.setUserEmail(loginResponse.data!.email.validate());
      if (loginResponse.data!.uid != null) await sharedPref.setString(UID, loginResponse.data!.uid.validate());
      await appStore.setUserProfile(loginResponse.data!.profileImage.validate());
      await appStore.setReferralCode(loginResponse.data!.referralCode.validate());
    }

    return loginResponse;
  }).catchError((e) {
    log('${e.toString()}');
    throw e.toString();
  });
}

Future<MultipartRequest> getMultiPartRequest(String endPoint, {String? baseUrl}) async {
  String url = '${baseUrl ?? buildBaseUrl(endPoint).toString()}';
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future sendMultiPartRequest(MultipartRequest multiPartRequest, {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  multiPartRequest.headers.addAll(buildHeaderTokens());

  await multiPartRequest.send().then((res) {
    res.stream.bytesToString().then(
      (value) {
        onSuccess?.call(jsonDecode(value));
      },
    );
  }).catchError((error) {
    onError?.call(error.toString());
  });
}

/// Profile Update
Future updateProfile({String? uid, String? firstName, String? lastName, String? userEmail, String? contactNumber, File? file}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['id'] = sharedPref.getInt(USER_ID).toString();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['email'] = userEmail ?? appStore.userEmail;
  multiPartRequest.fields['first_name'] = firstName.validate();
  multiPartRequest.fields['last_name'] = lastName.validate();
  multiPartRequest.fields['contact_number'] = contactNumber.validate();
  // multiPartRequest.fields['address'] = address.validate();
  // multiPartRequest.fields['gender'] = gender.validate();
  multiPartRequest.fields['uid'] = uid.validate();
  multiPartRequest.fields['player_id'] = sharedPref.getString(PLAYER_ID).toString();

  if (file != null) multiPartRequest.files.add(await MultipartFile.fromPath('profile_image', file.path));

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      LoginResponse res = LoginResponse.fromJson(data);

      await sharedPref.setString(FIRST_NAME, res.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, res.data!.lastName.validate());
      await sharedPref.setString(USER_PROFILE_PHOTO, res.data!.profileImage.validate());
      await sharedPref.setString(USER_NAME, res.data!.username.validate());
      await sharedPref.setString(USER_ADDRESS, res.data!.address.validate());
      await sharedPref.setString(CONTACT_NUMBER, res.data!.contactNumber.validate());
      await sharedPref.setString(GENDER, res.data!.gender.validate());
      await appStore.setUserEmail(res.data!.email.validate());
      await appStore.setUserProfile(res.data!.profileImage.validate());
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<void> logout({bool isDelete = false}) async {
  if (!isDelete) {
    await logoutApi().then((value) async {
      logOutSuccess();
    }).catchError((e) {
      throw e.toString();
    });
  } else {
    logOutSuccess();
  }
}

Future<ChangePasswordResponseModel> changePassword(Map req) async {
  return ChangePasswordResponseModel.fromJson(await handleResponse(await buildHttpResponse('change-password', request: req, method: HttpMethod.POST)));
}

Future<ChangePasswordResponseModel> forgotPassword(Map req) async {
  return ChangePasswordResponseModel.fromJson(await handleResponse(await buildHttpResponse('forget-password', request: req, method: HttpMethod.POST)));
}

Future<LoginResponse> getUserDetail({int? userId}) async {
  return LoginResponse.fromJson(await handleResponse(await buildHttpResponse('user-detail?id=$userId', method: HttpMethod.GET)));
}

Future<WalletListModel> getWalletList({required int page}) async {
  return WalletListModel.fromJson(await handleResponse(await buildHttpResponse('wallet-list?page=$page', method: HttpMethod.GET)));
}

Future<PaymentListModel> getPaymentList() async {
  return PaymentListModel.fromJson(await handleResponse(await buildHttpResponse('payment-gateway-list?status=1', method: HttpMethod.GET)));
}

Future<LDBaseResponse> saveWallet(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-wallet', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveCoinWallet(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-coin-wallet', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveSOS(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-sos', method: HttpMethod.POST, request: request)));
}

Future<ContactNumberListModel> getSosList({int? regionId, int? page}) async {
  return ContactNumberListModel.fromJson(await handleResponse(await buildHttpResponse(regionId != null ? 'sos-list?region_id=$regionId' : 'sos-list?page=$page', method: HttpMethod.GET)));
}

Future<ContactNumberListModel> deleteSosList({int? id}) async {
  return ContactNumberListModel.fromJson(await handleResponse(await buildHttpResponse('sos-delete/$id', method: HttpMethod.POST)));
}

Future<EstimatePriceModel> estimatePriceList(Map request) async {
  return EstimatePriceModel.fromJson(await handleResponse(await buildHttpResponse('estimate-price-time', method: HttpMethod.POST, request: request)));
}

Future<CouponListModel> getCouponList({required int page, required int serviceId}) async {
  return CouponListModel.fromJson(await handleResponse(await buildHttpResponse('coupon-list?page=$page', method: HttpMethod.GET)));
}

Future<ModelZoneList> getZoneList({String? name, int? zoneId}) async {
  return ModelZoneList.fromJson(await handleResponse(await buildHttpResponse('managezone-list?per_page=1000&name=$name&zone_id=$zoneId', method: HttpMethod.GET)).then((value) => value));
}

Future<ModelAirportList> getAirportList({String? name}) async {
  return ModelAirportList.fromJson(await handleResponse(await buildHttpResponse('airport-list?per_page=1000&name=$name', method: HttpMethod.GET)).then((value) => value));
}

Future<LDBaseResponse> savePayment(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-payment', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveRideRequest(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-riderequest', method: HttpMethod.POST, request: request)));
}

Future<BidListingModel> getBidListing(Map request) async {
  return BidListingModel.fromJson(await handleResponse(await buildHttpResponse('get-bidding-riderequest', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> responseBidListing(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('riderequest-bid-respond', method: HttpMethod.POST, request: request)));
}

Future<AppSettingModel> getAppSetting() async {
  return AppSettingModel.fromJson(await handleResponse(await buildHttpResponse('admin-dashboard', method: HttpMethod.GET)));
}

Future<CurrentRequestModel> getCurrentRideRequest() async {
  var response = await buildHttpResponse('current-riderequest', method: HttpMethod.GET);
  var responseData = await handleResponse(response);

  // Check if the response is a list and handle accordingly
  if (responseData is List) {
    // If the API returns an empty list, return an empty model
    if (responseData.isEmpty) {
      return CurrentRequestModel(
        rideRequest: null,
        onRideRequest: null,
        schedule_ride_request: [],
      );
    }
    // If it's a non-empty list, take the first item (assuming it's what you need)
    else {
      return CurrentRequestModel.fromJson(responseData[0]);
    }
  }
  // If it's already a map, process as before
  else {
    return CurrentRequestModel.fromJson(responseData);
  }
}

Future<LDBaseResponse> rideRequestUpdate({required Map request, int? rideId}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('riderequest-update/$rideId', method: HttpMethod.POST, request: request)));
}

Future<ServerLanguageResponse> getLanguageList(versionNo) async {
  return ServerLanguageResponse.fromJson(await handleResponse(await buildHttpResponse('language-table-list?version_no=$versionNo', method: HttpMethod.GET)).then((value) => value));
}

Future<LDBaseResponse> ratingReview({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-ride-rating', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> adminNotify({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('admin-sos-notify', method: HttpMethod.POST, request: request)));
}

Future<RiderListModel> getRiderRequestList({int? page, String? status, LatLng? sourceLatLog, int? riderId}) async {
  if (sourceLatLog != null) {
    return RiderListModel.fromJson(await handleResponse(await buildHttpResponse('riderequest-list?page=$page&rider_id=$riderId', method: HttpMethod.GET)));
  } else {
    return RiderListModel.fromJson(await handleResponse(await buildHttpResponse(status != null ? 'riderequest-list?page=$page&status=$status&rider_id=$riderId' : 'riderequest-list?page=$page&rider_id=$riderId', method: HttpMethod.GET)));
  }
}

Future<LDBaseResponse> saveComplain({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-complaint', method: HttpMethod.POST, request: request)));
}

Future<RideDetailModel> rideDetail({required int? orderId}) async {
  return RideDetailModel.fromJson(await handleResponse(await buildHttpResponse('riderequest-detail?id=$orderId', method: HttpMethod.GET)));
}

/// Get Notification List
Future<NotificationListModel> getNotification({required int page}) async {
  return NotificationListModel.fromJson(await handleResponse(await buildHttpResponse('notification-list?page=$page&limit=$PER_PAGE', method: HttpMethod.POST)));
}

// Future<ModelSearchPlaceRes> searchAddressRequest({String? search}) async {
//   return ModelSearchPlaceRes.fromJson(await handleResponse(await buildHttpResponse('https://places.googleapis.com/v1/places:autocomplete', header_extra: {'X-Goog-Api-Key': '$GOOGLE_MAP_API_KEY'}, request: {"input": search}, method: HttpMethod.POST)));
// }
//
// Future<GooglePlacesApiResponse> searchAddressRequestPlaceId({String? placeId}) async {
//   return GooglePlacesApiResponse.fromJson(await handleResponse(await buildHttpResponse('https://places.googleapis.com/v1/places/$placeId?fields=id,displayName,location&key=$GOOGLE_MAP_API_KEY', header_extra: {}, method: HttpMethod.GET)));
// }

Future<LoginResponse> updateStatus(Map request) async {
  return LoginResponse.fromJson(await handleResponse(await buildHttpResponse('update-user-status', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> deleteUser() async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('delete-user-account', method: HttpMethod.POST)));
}

/// Profile Update
Future updateProfileUid() async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['id'] = sharedPref.getInt(USER_ID).toString();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['uid'] = sharedPref.getString(UID).toString();

  log('multipart request:${multiPartRequest.fields}');
  log(sharedPref.getString(UID).toString());

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<LDBaseResponse> complaintComment({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-complaintcomment', method: HttpMethod.POST, request: request)));
}

Future<ComplaintCommentModel> complaintList({required int complaintId, required int currentPage}) async {
  return ComplaintCommentModel.fromJson(await handleResponse(await buildHttpResponse('complaintcomment-list?complaint_id=$complaintId&page=$currentPage', method: HttpMethod.GET)));
}

Future<LDBaseResponse> logoutApi() async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('logout?clear=player_id', method: HttpMethod.GET)));
}

Future<UserDetailModel> getDriverDetail({int? userId}) async {
  return UserDetailModel.fromJson(await handleResponse(await buildHttpResponse('user-detail?id=$userId', method: HttpMethod.GET)));
}

logOutSuccess() async {
  sharedPref.remove(FIRST_NAME);
  sharedPref.remove(LAST_NAME);
  sharedPref.remove(USER_PROFILE_PHOTO);
  sharedPref.remove(USER_NAME);
  sharedPref.remove(USER_ADDRESS);
  sharedPref.remove(CONTACT_NUMBER);
  sharedPref.remove(GENDER);
  sharedPref.remove(UID);
  sharedPref.remove(TOKEN);
  sharedPref.remove(USER_TYPE);
  sharedPref.remove(ADDRESS);
  sharedPref.remove(USER_ID);
  sharedPref.remove(COUNTRY);
  appStore.setLoggedIn(false);
  if (!(sharedPref.getBool(REMEMBER_ME) ?? false) || sharedPref.getString(LOGIN_TYPE) == LoginTypeGoogle || sharedPref.getString(LOGIN_TYPE) == 'mobile') {
    sharedPref.remove(USER_EMAIL);
    sharedPref.remove(USER_PASSWORD);
    sharedPref.remove(REMEMBER_ME);
  }
  sharedPref.remove(LOGIN_TYPE);
  launchScreen(getContext, SignInScreen(), isNewTask: true);
}

Future<NearByDriverModel> getNearByDriverList({LatLng? latLng}) async {
  return NearByDriverModel.fromJson(await handleResponse(await buildHttpResponse('near-by-driver?latitude=${latLng!.latitude}&longitude=${latLng.longitude}', method: HttpMethod.GET)));
}

Future<WalletInfoModel> getWalletData() async {
  return WalletInfoModel.fromJson(await handleResponse(await buildHttpResponse('wallet-detail', method: HttpMethod.GET)));
}

Future<WithDrawListModel> getWithDrawList({int? page}) async {
  return WithDrawListModel.fromJson(await handleResponse(await buildHttpResponse('withdrawrequest-list?page=$page', method: HttpMethod.GET)));
}

Future<RewardsListModel> getRewardsList({int? page}) async {
  return RewardsListModel.fromJson(await handleResponse(await buildHttpResponse(
    'reward-list?page=$page',
    method: HttpMethod.GET,
  )));
}

Future<CoinWalletListModel> getCoinWalletList({required int page}) async {
  return CoinWalletListModel.fromJson(await handleResponse(await buildHttpResponse(
    'coin-wallet-list?page=$page',
    method: HttpMethod.GET,
  )));
}

Future<LDBaseResponse> saveWithDrawRequest(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-withdrawrequest', method: HttpMethod.POST, request: request)));
}

Future<ReferralHistoryListModel> getReferralList({int? page}) async {
  return ReferralHistoryListModel.fromJson(await handleResponse(await buildHttpResponse(
    'reference-list?page=$page',
    method: HttpMethod.GET,
  )));
}

Future<ModelFAQ> getFaqList({required int page}) async {
  return ModelFAQ.fromJson(await handleResponse(await buildHttpResponse('faq-list?app=rider&page=$page', method: HttpMethod.GET)));
}

/// Get cancel Reason
Future<cancelReasonList> getCancelReasonList({required String type}) async {
  return cancelReasonList.fromJson(await handleResponse(await buildHttpResponse('cancelReason-list?type=$type', method: HttpMethod.GET)));
}

/// Update Bank Info
Future updateBankDetail({String? bankName, String? bankCode, String? accountName, String? accountNumber, String? routing, String? iban, String? swift}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['contact_number'] = sharedPref.getString(CONTACT_NUMBER).validate();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['user_bank_account[bank_name]'] = bankName.validate();
  multiPartRequest.fields['user_bank_account[bank_code]'] = bankCode.validate();
  multiPartRequest.fields['user_bank_account[account_holder_name]'] = accountName.validate();
  multiPartRequest.fields['user_bank_account[account_number]'] = accountNumber.validate();
  // This field missing in Bank Detail: Routing Number, Bank IBAN, Bank Swift
  multiPartRequest.fields['user_bank_account[routing_number]'] = routing.validate();
  multiPartRequest.fields['user_bank_account[bank_iban]'] = iban.validate();
  multiPartRequest.fields['user_bank_account[bank_swift]'] = swift.validate();

  log('Request:${multiPartRequest.fields}');

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    log('data:$data');
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<LDBaseResponse> updateExtraChargePaymentMethod(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('update-extra-charge-paymentmethod', method: HttpMethod.POST, request: request)));
}

Future<PolyLineData> getPolylineData(String origins, String destinations) async {
  return PolyLineData.fromJson(await handleResponse(await buildHttpResponse('directions-polyline-api?origin=$origins&destination=$destinations', method: HttpMethod.GET)));
}

Future<SearchLocationModel> searchAddressRequest(Map request) async {
  return SearchLocationModel.fromJson(await handleResponse(await buildHttpResponse('place-autocomplete-api', method: HttpMethod.POST, request: request)));
}

Future<SelectLocationModel> searchAddressRequestPlaceId(String placeId) async {
  return SelectLocationModel.fromJson(await handleResponse(await buildHttpResponse('place-detail-api?placeid=$placeId', method: HttpMethod.GET)));
}
