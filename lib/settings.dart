import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppBar(title: const Text('Settings'), automaticallyImplyLeading: false),
        _buildSettingsSection('Account', [
          _buildSettingsTile(
            Icons.person,
            'Profile',
            'Manage your profile',
            () {},
          ),
          _buildSettingsTile(
            Icons.subscriptions,
            'Subscription',
            'Manage your subscription',
            () {},
          ),
        ]),
        _buildSettingsSection('Playback', [
          _buildSettingsTile(
            Icons.video_settings,
            'Video Quality',
            'Auto',
            () {},
          ),
          _buildSettingsTile(
            Icons.closed_caption,
            'Subtitles',
            'Configure subtitles',
            () {},
          ),
        ]),
        _buildSettingsSection('Connection', [
          _buildSettingsTile(
            Icons.link,
            'M3U URL',
            'Configure playlist URL',
            () {},
          ),
          _buildSettingsTile(
            Icons.vpn_key,
            'EPG Source',
            'Configure EPG',
            () {},
          ),
        ]),
        _buildSettingsSection('App', [
          _buildSettingsTile(Icons.info, 'About', 'Version 1.0.0', () {}),
          _buildSettingsTile(
            Icons.logout,
            'Logout',
            'Sign out of your account',
            () {},
          ),
        ]),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
