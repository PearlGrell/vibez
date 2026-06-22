import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/provider/search_provider.dart';
import 'package:vibez/presentation/discover/pages/discover_page.dart';
import 'package:vibez/presentation/discover/pages/search_page.dart';
import 'package:vibez/presentation/discover/widgets/app_search_bar.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchProvider.notifier).onQueryChanged(_searchController.text);
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
              onPressed: () {},
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
            AppSearchBar(controller: _searchController),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
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
