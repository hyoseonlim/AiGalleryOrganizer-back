import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          _buildSectionTitle(title: '계정'),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('홍길동'),
            subtitle: Text('user@example.com'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement logout
              },
              child: const Text('로그아웃'),
            ),
          ),
          const Divider(),
          _buildSectionTitle(title: '저장공간'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('사용량: 2.5 GB / 10 GB'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.25, // 2.5 / 10
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionTitle(title: '백업'),
          SwitchListTile(
            title: const Text('자동 백업'),
            value: true,
            onChanged: (bool value) {
              // TODO: Handle auto backup toggle
            },
          ),
          SwitchListTile(
            title: const Text('WiFi 전용'),
            subtitle: const Text('모바일 데이터 사용 안 함'),
            value: true,
            onChanged: (bool value) {
              // TODO: Handle WiFi only toggle
            },
          ),
          SwitchListTile(
            title: const Text('충전 중에만'),
            value: false,
            onChanged: (bool value) {
              // TODO: Handle charging only toggle
            },
          ),
          const Divider(),
          _buildSectionTitle(title: 'AI 설정'),
          ListTile(
            title: const Text('AI 정리 제안 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to AI settings detail page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }
}
