import '../manage_imports.dart';


class WalkThroughScreen extends StatefulWidget {
  @override
  WalkThroughScreenState createState() => WalkThroughScreenState();
}

class WalkThroughScreenState extends State<WalkThroughScreen> {
  PageController pageController = PageController();
  int currentPage = 0;

  List<WalkThroughModel> walkThroughClass = [
    WalkThroughModel(
        name: language.walkthrough_title_1,
        text: language.walkthrough_subtitle_1,
        img: ic_walk1),
    WalkThroughModel(
        name: language.walkthrough_title_2,
        text: language.walkthrough_subtitle_2,
        img: ic_walk2),
    WalkThroughModel(
        name: language.walkthrough_title_3,
        text: language.walkthrough_subtitle_3,
        img: ic_walk3)
  ];

  bool get _isLastPage => currentPage >= walkThroughClass.length - 1;

  void _finish() {
    launchScreen(context, SignInScreen(), isNewTask: true);
    sharedPref.setBool(IS_FIRST_TIME, false);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: brandBlack,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: walkThroughClass.length,
            controller: pageController,
            itemBuilder: (context, i) {
              // Parallax: the picture drifts slower than the page while swiping.
              return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double offset = 0;
                  if (pageController.hasClients && pageController.position.haveDimensions) {
                    offset = (pageController.page ?? 0) - i;
                  }
                  return Transform.translate(
                    offset: Offset(offset * size.width * 0.35, 0),
                    child: Transform.scale(scale: 1.1, child: child),
                  );
                },
                child: Image.asset(
                  walkThroughClass[i].img.toString(),
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                ),
              );
            },
            onPageChanged: (int i) => setState(() => currentPage = i),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent, Colors.black.withValues(alpha: 0.92)],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            top: padding.top + 14,
            left: 16,
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(ic_app_logo, width: 42, height: 42, fit: BoxFit.cover)),
                SizedBox(width: 10),
                Text(mAppName, style: boldTextStyle(size: 20, color: Colors.white)),
              ],
            ),
          ),
          Positioned(
            top: padding.top + 14,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isLastPage ? 0 : 1,
              duration: Duration(milliseconds: 300),
              child: TextButton(
                onPressed: _isLastPage ? null : _finish,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: StadiumBorder(),
                ),
                child: Text(language.skip, style: boldTextStyle(color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: padding.bottom + 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: Offset(0, 0.25), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(currentPage),
                    children: [
                      Text(walkThroughClass[currentPage].name!,
                          style: boldTextStyle(size: 30, color: Colors.white), textAlign: TextAlign.center),
                      SizedBox(height: 10),
                      Text(walkThroughClass[currentPage].text.toString(),
                          style: secondaryTextStyle(size: 15, color: Colors.white70), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    walkThroughClass.length,
                    (i) => AnimatedContainer(
                      duration: Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: i == currentPage ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == currentPage ? brandYellow : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                GestureDetector(
                  onTap: () {
                    if (_isLastPage) {
                      _finish();
                    } else {
                      pageController.nextPage(duration: Duration(milliseconds: 600), curve: Curves.easeOutCubic);
                    }
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    height: 64,
                    width: _isLastPage ? 220 : 64,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: brandYellow,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: brandYellow.withValues(alpha: 0.5), blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isLastPage)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: (currentPage + 1) / walkThroughClass.length),
                            duration: Duration(milliseconds: 500),
                            builder: (context, value, _) => SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 3,
                                color: brandBlack,
                                backgroundColor: brandBlack.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        _isLastPage
                            ? Text('Get Started',
                                maxLines: 1, softWrap: false, overflow: TextOverflow.clip,
                                style: boldTextStyle(size: 18, color: brandBlack))
                            : Icon(Icons.arrow_forward, color: brandBlack),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
