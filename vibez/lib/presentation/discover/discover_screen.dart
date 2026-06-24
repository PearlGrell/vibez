import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/provider/search_provider.dart';
import 'package:vibez/presentation/discover/pages/discover_page.dart';
import 'package:vibez/presentation/discover/pages/search_page.dart';
import 'package:vibez/presentation/discover/widgets/add_sheet.dart';
import 'package:vibez/presentation/discover/widgets/app_search_bar.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  const DiscoverScreen({super.key, required this.searchController});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    widget.searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchProvider.notifier).onQueryChanged(widget.searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyActions: false,
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s2,
          children: [
            Text("DISCOVER", style: Theme.of(context).textTheme.mono()),
            Text(
              "Find your frequency",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadows.shGlow,
            ),
            child: IconButton.filled(
              onPressed: () {
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
                  },
                );
              },
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: AppSpacing.s3,
        ),
        child: Column(
          children: [
            AppSearchBar(controller: widget.searchController),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.searchController,
                builder: (context, value, child) {
                  return _buildBody(value.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String s) {
    return s.trim().isEmpty ? const DiscoverPage() : const SearchPage();
  }
}
