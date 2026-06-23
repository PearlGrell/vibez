import 'package:flutter/material.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/presentation/discover/discover_screen.dart';
import 'package:vibez/presentation/discover/widgets/add_sheet.dart';
import 'package:vibez/presentation/landing/widgets/app_bottom_navbar.dart';
import 'package:vibez/presentation/profile/profile_screen.dart';

enum Page { discover, profile }

class LandingScreen extends StatefulWidget {
  final Page currentPage;
  const LandingScreen({super.key, required this.currentPage});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentPage == Page.discover ? 0 : 1;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          KeepAlivePage(child: DiscoverScreen()),
          KeepAlivePage(child: ProfileScreen()),
        ],
      ),
      bottomNavigationBar: AppBottomNavbar(
        currentIndex: _currentIndex,
        buttonTap: () {
          showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isDismissible: true,
              enableDrag: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                  child: const AddSheet(),
                );
              }
          );
        },
        onTap: (idx) {
          setState(() {
            _currentIndex = idx;
          });
          _controller.animateToPage(
            idx,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
