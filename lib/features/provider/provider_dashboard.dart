import 'package:flutter/material.dart';

import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import 'screens/available_jobs_page.dart';
import 'screens/my_quotes_page.dart';
import 'screens/provider_home_page.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentIndex = 0;

  static const _primaryBlue = Color(0xFF2563EB);

  List<Widget> _buildPages() {
    return [
      ProviderHomePage(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const AvailableJobsPage(),
      const MyQuotesPage(),
      const MessagesScreen(),
      const ProviderProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
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
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _primaryBlue,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedIconTheme: const IconThemeData(size: 26),
            unselectedIconTheme: const IconThemeData(size: 24),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_rounded),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money_rounded),
                label: 'Quotes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_rounded),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
