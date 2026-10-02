import '../manage_imports.dart';
import '../utils/BrandTheme.dart';

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
      backgroundColor: BrandTokens.page,
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                      // Balance left after this transaction, so the
                                      // running total can be followed down the list.
                                      if (data.balance != null) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          'Bal ${appStore.currencyCode}${data.balance!.toStringAsFixed(digitAfterDecimal)}',
                                          style: secondaryTextStyle(size: 11),
                                        ),
                                      ],
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
            // One way to add money is enough: the balance card above
            // already opens the top-up screen, and this second button
            // led to a different, older flow for the same thing.
          ],
        ),
      ),
    );
  }
}
