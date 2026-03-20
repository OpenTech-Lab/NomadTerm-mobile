import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'session_list_screen.dart';

/// Root shell that hosts bottom tab navigation between Sessions and Dashboard.
///
/// Uses [IndexedStack] to keep both screens alive so that session subscriptions
/// and usage listeners are not torn down on tab switch.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _screens = [
    SessionListScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final th = context.watch<SettingsProvider>().nomadTheme;

    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _TerminalBottomNav(
        selectedIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        th: th,
      ),
    );
  }
}

// ── Terminal-style bottom nav bar ─────────────────────────────────────────

class _TerminalBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final NomadTheme th;

  const _TerminalBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.th,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: th.surface,
        border: Border(top: BorderSide(color: th.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          _NavItem(
            icon: Icons.terminal,
            label: th.labelTabSessions,
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
            th: th,
          ),
          _NavItem(
            icon: Icons.monitor_heart_outlined,
            label: th.labelTabDashboard,
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
            th: th,
          ),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final NomadTheme th;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.th,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? th.accent : th.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(label, style: th.monoSm(color: color, size: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
