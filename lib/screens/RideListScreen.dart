import '../manage_imports.dart';

const RIDES_ACTIVE = 'active';

class RideListScreen extends StatefulWidget {
  @override
  RideListScreenState createState() => RideListScreenState();
}

class RideListScreenState extends State<RideListScreen> {
  final List<String> riderStatus = [RIDES_ACTIVE, COMPLETED, CANCELED];

  String _tabLabel(String status) => status == RIDES_ACTIVE ? 'Active' : changeStatusText(status);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: riderStatus.length,
      child: Scaffold(
        backgroundColor: Color(0xFFF4F6F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: brandBlue,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(language.rides, style: boldTextStyle(color: Colors.white)),
        ),
        body: Column(children: [
          Container(
            height: 44,
            margin: EdgeInsets.fromLTRB(16, 16, 16, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius(defaultRadius + 4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: TabBar(
              dividerHeight: 0,
              padding: EdgeInsets.all(4),
              indicator: BoxDecoration(borderRadius: radius(defaultRadius + 2), color: brandBlue),
              labelColor: Colors.white,
              unselectedLabelColor: brandBlue,
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: radius(defaultRadius + 2),
              labelStyle: boldTextStyle(color: Colors.white, size: 13),
              unselectedLabelStyle: primaryTextStyle(size: 13),
              labelPadding: EdgeInsets.symmetric(horizontal: 4),
              // single line on narrow phones
              tabs: riderStatus.map((e) => Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_tabLabel(e), maxLines: 1, softWrap: false)))).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: riderStatus.map((e) => CreateTabScreen(status: e)).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}
