import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_booking/utils/images.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../service/RideService.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import 'CancelOrderDialog.dart';

class BookingWidget extends StatefulWidget {
  final bool isLast;
  final int? id;
  final String? dt;

  BookingWidget({required this.id, this.isLast = false, this.dt});

  @override
  BookingWidgetState createState() => BookingWidgetState();
}

class BookingWidgetState extends State<BookingWidget> {
  RideService rideService = RideService();
  final int timerMaxSeconds = appStore.rideMinutes != null ? int.parse(appStore.rideMinutes!) * 60 : 5 * 60;

  int currentSeconds = 0;
  int duration = 0;
  int count = 0;
  Timer? timer;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? d2;

  String get timerText => '${((duration - currentSeconds) ~/ 60).toString().padLeft(2, '0')}: ${((duration - currentSeconds) % 60).toString().padLeft(2, '0')}';
  bool called = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    print(REMAINING_TIME);
    print(IS_TIME);
    if (sharedPref.getString(IS_TIME) == null) {
      duration = timerMaxSeconds;
      startTimeout();
      sharedPref.setString(IS_TIME, DateTime.now().add(Duration(seconds: timerMaxSeconds)).toString());
      sharedPref.setString(REMAINING_TIME, timerMaxSeconds.toString());
    } else {
      duration = DateTime.parse(sharedPref.getString(IS_TIME)!).difference(DateTime.now()).inSeconds;
      if (duration > 0) {
        startTimeout();
      } else {
        sharedPref.remove(IS_TIME);
        duration = timerMaxSeconds;
        setState(() {});
        startTimeout();
      }
    }
  }

  // cancelRideCall() {
  //   Map req = {
  //     'status': CANCELED,
  //     'cancel_by': AUTO,
  //     "reason": "Ride is auto cancelled",
  //   };
  //   appStore.setLoading(true);
  //   rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
  //     appStore.setLoading(false);
  //     toast(language.noNearByDriverFound);
  //     sharedPref.remove(REMAINING_TIME);
  //     sharedPref.remove(IS_TIME);
  //   }).catchError((error) {
  //     appStore.setLoading(false);
  //     log(error.toString());
  //   });
  // }

  startTimeout() {
    if (called == true) return;
    called = true;
    if (widget.dt != null) {
      DateTime? d1 = DateTime.tryParse(widget.dt.validate());
      if (d1 != null) {
        // d1=d1.toUtc();
        print("CheckDateTime:::${d1}");
        // d1=d1.t
        setState(
          () {
            // d2 = d1.toUtc().add(Duration(seconds: timerMaxSeconds));
            d2 = d1!.add(Duration(seconds: timerMaxSeconds));
          },
        );
        print("CheckDateTimedafjfkljf:::${d2}");
        return;
      }
    }
    return;
    var duration2 = Duration(seconds: 1);
    timer = Timer.periodic(duration2, (timer) {
      setState(
        () {
          currentSeconds = timer.tick;
          count++;
          if (count >= 60) {
            int data = int.parse(sharedPref.getString(REMAINING_TIME)!);
            data = data - count;
            Map req = {
              'max_time_for_find_driver_for_ride_request': data,
            };
            rideRequestUpdate(request: req, rideId: widget.id).then((value) {
              //
            }).catchError((error) {
              log(error.toString());
            });
            sharedPref.setString(REMAINING_TIME, data.toString());
            count = 0;
          }
          if (timer.tick >= duration) {
            timer.cancel();
            Map req = {
              'status': CANCELED,
              'cancel_by': AUTO,
              "reason": "Ride is auto cancelled",
            };
            appStore.setLoading(true);
            rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
              appStore.setLoading(false);
              toast(language.noNearByDriverFound);
              sharedPref.remove(REMAINING_TIME);
              sharedPref.remove(IS_TIME);
            }).catchError((error) {
              appStore.setLoading(false);
              log(error.toString());
            });
          }
        },
      );
    });
  }

  Future<void> cancelRequest(String? reason) async {
    Map req = {
      "id": widget.id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
      toast(value.message);
    }).catchError((error) {
      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.lookingForNearbyDrivers, style: boldTextStyle()),
              // Stream.periodic(Duration(seconds: 2),(computationCount) {
              //   return SizedBox();
              // },),
              if (d2 != null)
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: primaryColor, borderRadius: radius(8)),
                    child: StreamBuilder(
                      stream: Stream.periodic(Duration(seconds: 1)),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if (d2 != null && d2!.difference(DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""))).isNegative) {
                          // print("CheckDateTImeIssue++++++++++123186:${d2!.difference(DateTime.now().toUtc())}");
                          Map req = {
                            'status': CANCELED,
                            'cancel_by': AUTO,
                            "reason": "Ride is auto cancelled",
                          };
                          d2 = null;
                          print("AutoCancelFunctionCall:::::");
                          appStore.setLoading(true);
                          rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
                            appStore.setLoading(false);
                            toast(language.noNearByDriverFound);
                            sharedPref.remove(REMAINING_TIME);
                            sharedPref.remove(IS_TIME);
                          }).catchError((error) {
                            appStore.setLoading(false);
                            log(error.toString());
                          });
                        }
                        if (d2 != null && d2!.difference(DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""))).isNegative)
                          return Text("--:--", style: boldTextStyle(color: Colors.white));
                        if (d2 == null) return Text("--:--", style: boldTextStyle(color: Colors.white));
                        return Text(
                            (d2!.difference(DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""))).inSeconds / 60).toInt().toString().padLeft(2, "0") +
                                ":" +
                                (d2!.difference(DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""))).inSeconds % 60).toString().padLeft(2, "0").toString(),
                            style: boldTextStyle(color: Colors.white));
                      },
                    )
                    // Text(timerText, style: boldTextStyle(color: Colors.white)),
                    )
            ],
          ),
          SizedBox(height: 8),
          Lottie.asset(bookingAnim, height: 100, width: MediaQuery.of(context).size.width, fit: BoxFit.contain),
          SizedBox(height: 20),
          Text(language.weAreLookingForNearDriversAcceptsYourRide, style: primaryTextStyle(), textAlign: TextAlign.center),
          SizedBox(height: 16),
          AppButtonWidget(
            width: MediaQuery.of(context).size.width,
            text: language.cancel,
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  isScrollControlled: true,
                  builder: (context) {
                    return CancelOrderDialog(
                      onCancel: (reason) async {
                        Navigator.pop(context);
                        appStore.setLoading(true);
                        sharedPref.remove(REMAINING_TIME);
                        sharedPref.remove(IS_TIME);
                        await cancelRequest(reason);
                        appStore.setLoading(false);
                      },
                    );
                  });
            },
          )
        ],
      ),
    );
  }
}
