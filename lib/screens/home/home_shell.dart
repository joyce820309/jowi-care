import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../food/wet_food_screen.dart';
import '../food/dry_food_screen.dart';
import '../food/snack_screen.dart';
import '../blacklist/blacklist_screen.dart';
import '../medical/medical_screen.dart';
import '../weight/weight_screen.dart';
import '../reminders/reminders_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeShell({super.key, required this.onToggleTheme});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    _FoodTabSection(),
    MedicalScreen(),
    WeightScreen(),
    RemindersScreen(),
    BlacklistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = AppStrings.fromLocale(locale);
    final appBarFg = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    final titles = [
      s.titleFood,
      s.titleMedical,
      s.titleWeight,
      s.titleReminders,
      s.titleBlacklist,
    ];

    final navItems = [
      BottomNavigationBarItem(icon: const Icon(Icons.restaurant_menu_outlined), activeIcon: const Icon(Icons.restaurant_menu), label: s.navFood),
      BottomNavigationBarItem(icon: const Icon(Icons.local_hospital_outlined), activeIcon: const Icon(Icons.local_hospital), label: s.navMedical),
      BottomNavigationBarItem(icon: const Icon(Icons.monitor_weight_outlined), activeIcon: const Icon(Icons.monitor_weight), label: s.navWeight),
      BottomNavigationBarItem(icon: const Icon(Icons.notifications_outlined), activeIcon: const Icon(Icons.notifications), label: s.navReminders),
      BottomNavigationBarItem(icon: const Icon(Icons.block_outlined), activeIcon: const Icon(Icons.block), label: s.navBlacklist),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          TextButton(
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            style: TextButton.styleFrom(foregroundColor: appBarFg),
            child: Text(
              s.toggleLang,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: appBarFg),
            onPressed: widget.onToggleTheme,
            tooltip: s.toggleThemeTooltip,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            items: navItems,
          ),
        ),
      ),
    );
  }
}

// 食物區：罐頭 / 乾乾 / 零食
class _FoodTabSection extends StatefulWidget {
  const _FoodTabSection();

  @override
  State<_FoodTabSection> createState() => _FoodTabSectionState();
}

class _FoodTabSectionState extends State<_FoodTabSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            splashBorderRadius: BorderRadius.circular(24),
            tabs: [
              Tab(text: s.tabWetFood),
              Tab(text: s.tabDryFood),
              Tab(text: s.tabSnack),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              WetFoodScreen(),
              DryFoodScreen(),
              SnackScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
