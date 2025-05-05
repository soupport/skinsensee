import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skinsense/services/theme_provider.dart';
import 'package:skinsense/services/tips_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tipsProvider = Provider.of<TipsProvider>(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink[300],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: const Text( // Use const Text for static text
                'Dark Mode',
                style: TextStyle(
                  color: Colors.black87, // Always black
                ),
              ),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: Colors.pink[300],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: const Text( // Use const Text for static text
                'Show Tips',
                style: TextStyle(
                  color: Colors.black87, // Always black
                ),
              ),
              trailing: Switch(
                value: tipsProvider.showTips,
                onChanged: (value) {
                  tipsProvider.toggleTips(value);
                },
                activeColor: Colors.pink[300],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: const Text( // Use const Text for static text
                'Notifications',
                style: TextStyle(
                  color: Colors.black87, // Always black
                ),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink[300],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: const Text( // Use const Text for static text
                'About',
                style: TextStyle(
                  color: Colors.black87, // Always black
                ),
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SkinSense',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.spa, color: Colors.pink),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}