import '../manage_imports.dart';

class WalletScreen extends StatefulWidget {
  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController addMoneyController = TextEditingController();
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  int totalPage = 1;

  int currentIndex = -1;

  List<WalletModel> walletData = [];

  num totalAmount = 0;

  UserBankAccount? userBankAccount;

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (currentPage < totalPage) {
          appStore.setLoading(true);
          currentPage++;
          setState(() {});

          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  void init() async {
    getBankDetail();
    getWalletListApi();
  }

  getWalletListApi() async {
    await getWalletList(page: currentPage).then((value) {
      appStore.setLoading(false);

      currentPage = value.pagination!.currentPage!;
      totalPage = value.pagination!.totalPages!;
      if (value.walletBalance != null)
        totalAmount = value.walletBalance!.totalAmount!;
      if (currentPage == 1) {
        walletData.clear();
      }
      walletData.addAll(value.data ?? []);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  getBankDetail() async {
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      userBankAccount = value.data!.userBankAccount;
      setState(() {});
    }).then((value) {
      log(value);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: brandBlue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(language.wallet, style: boldTextStyle(color: Colors.white)),
      ),
      body: Observer(builder: (context) {
        return Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brandBlue, Color(0xFF1760C8)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: brandBlue.withValues(alpha: 0.25), blurRadius: 16, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.availableBalance, style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                printAmountWidget(amount: totalAmount.toStringAsFixed(digitAfterDecimal), size: 26, color: Colors.white, weight: FontWeight.bold),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => launchScreen(context, WalletTopupScreen(currentBalance: totalAmount), pageRouteAnimation: PageRouteAnimation.Slide).then((_) => init()),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded, color: brandBlue, size: 20),
                                        SizedBox(width: 6),
                                        Text('Add money', style: boldTextStyle(color: brandBlue, size: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(language.recentTransactions, style: boldTextStyle(size: 16)),
                  AnimationLimiter(
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: walletData.length,
                      shrinkWrap: true,
                      itemBuilder: (_, index) {
                        WalletModel data = walletData[index];

                        return AnimationConfiguration.staggeredList(
                          delay: Duration(milliseconds: 200),
                          position: index,
                          duration: Duration(milliseconds: 375),
                          child: SlideAnimation(
                            child: Container(
                              margin: EdgeInsets.only(top: 6, bottom: 6),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 4))]),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (data.type == CREDIT ? Color(0xFF1E9E57) : Color(0xFFD93025)).withValues(alpha: 0.12)),
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                        data.type == CREDIT ? Icons.south_west_rounded : Icons.north_east_rounded,
                                        size: 20,
                                        color: data.type == CREDIT ? Color(0xFF1E9E57) : Color(0xFFD93025)),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            data.type == DEBIT
                                                ? language.moneyDebit
                                                : language.moneyDeposited,
                                            style: boldTextStyle(size: 15)),
                                        SizedBox(height: 2),
                                        Text(printDate(data.createdAt!),
                                            style:
                                                secondaryTextStyle(size: 11)),
                                        Row(
                                          children: [
                                            if (data.description != null && data.description!.isNotEmpty)
                                              Expanded(
                                                child: Text(data.description!,overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,),
                                              )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text("${data.type == CREDIT ? "+" : "-"}",
                                          style: boldTextStyle(
                                              color: data.type == CREDIT
                                                  ? Colors.green
                                                  : Colors.red)),
                                      printAmountWidget(
                                          amount:
                                              '${data.amount?.toStringAsFixed(digitAfterDecimal)}',
                                          color: data.type == CREDIT
                                              ? Colors.green
                                              : Colors.red,
                                          weight: FontWeight.bold),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            ),
            !appStore.isLoading && walletData.isEmpty
                ? emptyWidget()
                : SizedBox(),
          ],
        );
      }),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            if (totalAmount > 0)
              Expanded(
                child: AppButtonWidget(
                  text: language.withDraw,
                  width: MediaQuery.of(context).size.width,
                  onTap: () async {
                    if (userBankAccount != null &&
                        userBankAccount!.accountNumber.validate().isNotEmpty) {
                      launchScreen(
                          context,
                          WithDrawScreen(
                            bankInfo: userBankAccount!,
                            onTap: () {
                              init();
                            },
                          ));
                    } else {
                      toast(language.missingBankDetail);
                      await launchScreen(context, BankInfoScreen());
                      getBankDetail();
                      // if (res != null) {
                      //   getBankDetail();
                      // }
                    }
                  },
                ),
              ),
            if (totalAmount > 0) SizedBox(width: 16),
            Expanded(
              child: AppButtonWidget(
                text: language.addMoney,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(defaultRadius),
                            topRight: Radius.circular(defaultRadius))),
                    builder: (_) {
                      return Form(
                        key: formKey,
                        child: StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Padding(
                              padding: MediaQuery.of(context).viewInsets,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(language.addMoney,
                                            style: boldTextStyle()),
                                        CloseButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            addMoneyController.clear();
                                            currentIndex = -1;
                                          },
                                        )
                                      ],
                                    ),
                                    AppTextField(
                                      controller: addMoneyController,
                                      textFieldType: TextFieldType.PHONE,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d*$')),
                                      ],
                                      errorThisFieldRequired:
                                          language.thisFieldRequired,
                                      onChanged: (val) {
                                        //
                                      },
                                      validator: (String? val) {
                                        if (appStore.minAmountToAdd != null &&
                                            num.parse(val!) <
                                                appStore.minAmountToAdd!) {
                                          addMoneyController.text = appStore
                                              .minAmountToAdd
                                              .toString();
                                          addMoneyController.selection =
                                              TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: appStore
                                                          .minAmountToAdd
                                                          .toString()
                                                          .length));
                                          return "${language.minimum} ${appStore.minAmountToAdd} ${language.required}";
                                        } else if (appStore.maxAmountToAdd !=
                                                null &&
                                            num.parse(val!) >
                                                appStore.maxAmountToAdd!) {
                                          addMoneyController.text = appStore
                                              .maxAmountToAdd
                                              .toString();
                                          addMoneyController.selection =
                                              TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: appStore
                                                          .maxAmountToAdd
                                                          .toString()
                                                          .length));
                                          return "${language.maximum} ${appStore.maxAmountToAdd} ${language.required}";
                                        }
                                        return null;
                                      },
                                      decoration: inputDecoration(context,
                                          label: language.amount),
                                    ),
                                    SizedBox(height: 16),
                                    Wrap(
                                      runSpacing: 8,
                                      spacing: 8,
                                      children: appStore.walletPresetTopUpAmount
                                          .split('|')
                                          .map((e) {
                                        return inkWellWidget(
                                          onTap: () {
                                            currentIndex = appStore
                                                .walletPresetTopUpAmount
                                                .split('|')
                                                .indexOf(e);
                                            if (appStore.minAmountToAdd !=
                                                    null &&
                                                num.parse(e) <
                                                    appStore.minAmountToAdd!) {
                                              addMoneyController.text = appStore
                                                  .minAmountToAdd
                                                  .toString();
                                              addMoneyController.selection =
                                                  TextSelection.fromPosition(
                                                      TextPosition(
                                                          offset: appStore
                                                              .minAmountToAdd
                                                              .toString()
                                                              .length));
                                              toast(
                                                  "${language.minimum} ${appStore.minAmountToAdd} ${language.required}");
                                              currentIndex = -1;
                                            } else if (appStore
                                                        .minAmountToAdd !=
                                                    null &&
                                                int.parse(e) <
                                                    appStore.minAmountToAdd! &&
                                                appStore.maxAmountToAdd !=
                                                    null &&
                                                int.parse(e) >
                                                    appStore.maxAmountToAdd
                                                        .toString()
                                                        .length) {
                                              addMoneyController.text = appStore
                                                  .maxAmountToAdd
                                                  .toString();
                                              addMoneyController.selection =
                                                  TextSelection.fromPosition(
                                                      TextPosition(
                                                          offset: e.length));
                                              toast(
                                                  "${language.maximum} ${appStore.maxAmountToAdd} ${language.required}");
                                              currentIndex = -1;
                                            } else {
                                              addMoneyController.text = e;
                                              addMoneyController.selection =
                                                  TextSelection.fromPosition(
                                                      TextPosition(
                                                          offset: e.length));
                                            }

                                            setState(() {});
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: currentIndex ==
                                                      appStore
                                                          .walletPresetTopUpAmount
                                                          .split('|')
                                                          .indexOf(e)
                                                  ? primaryColor
                                                  : Colors.white,
                                              border: Border.all(
                                                  color: currentIndex ==
                                                          appStore
                                                              .walletPresetTopUpAmount
                                                              .split('|')
                                                              .indexOf(e)
                                                      ? primaryColor
                                                      : Colors.grey),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      defaultRadius),
                                            ),
                                            child: printAmountWidget(
                                                amount: '${e}',
                                                color: currentIndex ==
                                                        appStore
                                                            .walletPresetTopUpAmount
                                                            .split('|')
                                                            .indexOf(e)
                                                    ? Colors.white
                                                    : primaryColor,
                                                size: 14,
                                                weight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButtonWidget(
                                            text: language.addMoney,
                                            textStyle: boldTextStyle(
                                                color: Colors.white),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            color: primaryColor,
                                            onTap: () async {
                                              if (addMoneyController
                                                  .text.isNotEmpty) {
                                                if (formKey.currentState!
                                                        .validate() &&
                                                    addMoneyController
                                                        .text.isNotEmpty) {
                                                  Navigator.pop(context);
                                                  bool res = await launchScreen(
                                                      context,
                                                      PaymentScreen(
                                                          amount: num.parse(
                                                              addMoneyController
                                                                  .text)),
                                                      pageRouteAnimation:
                                                          PageRouteAnimation
                                                              .SlideBottomTop);
                                                  if (res == true) {
                                                    getWalletListApi();
                                                  }
                                                  addMoneyController.clear();
                                                  currentIndex = -1;
                                                } else {
                                                  toast(language
                                                      .pleaseSelectAmount);
                                                }
                                              } else {
                                                toast(language
                                                    .pleaseSelectAmount);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
