import 'package:flutter/material.dart';

import '../constants/home_strings.dart';
import 'home_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, required this.username});

  final String username;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          HomePage(username: widget.username),
          const _EmptyTabPage(),
          const _EmptyTabPage(),
          const _EmptyTabPage(),
          const _EmptyTabPage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: const Color(0xFF131731),
              indicatorColor: const Color(0xFF6D43EE),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                states,
              ) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                );
              }),
            ),
            child: NavigationBar(
              height: 72,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: HomeStrings.navHome,
                ),
                NavigationDestination(
                  icon: Icon(Icons.sensors_outlined),
                  selectedIcon: Icon(Icons.sensors_rounded),
                  label: HomeStrings.navSensors,
                ),
                NavigationDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy_rounded),
                  label: HomeStrings.navRobot,
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: HomeStrings.navLogs,
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: HomeStrings.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTabPage extends StatelessWidget {
  const _EmptyTabPage();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF0B0F28), Color(0xFF1A1540), Color(0xFF0A0D20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
