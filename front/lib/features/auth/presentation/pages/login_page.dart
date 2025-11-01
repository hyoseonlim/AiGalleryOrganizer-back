import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'AI Gallery',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8), // Google Blue
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '스마트하게 정리하는 갤러리',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 60),
                const Text('이메일', style: TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                    hintText: '이메일을 입력하세요',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                const Text('비밀번호', style: TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 8),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력하세요',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // For now, navigate to the gallery page.
                    // This will be changed to the main navigation page later.
                    Navigator.pushReplacementNamed(context, '/gallery');
                  },
                  child: const Text('로그인', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('또는', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                _SocialButton(
                  // Using an icon as a placeholder for the Google logo
                  icon: Icon(Icons.g_mobiledata, color: Colors.red.shade700, size: 30),
                  text: 'Google',
                  onPressed: () {
                    // TODO: Implement Google Sign-In
                  },
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  icon: const Icon(Icons.apple, color: Colors.white),
                  text: 'Apple',
                  onPressed: () {
                    // TODO: Implement Apple Sign-In
                  },
                  isApple: true,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('회원가입'),
                    ),
                    const Text('|', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement password recovery
                      },
                      child: const Text('비밀번호 찾기'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback onPressed;
  final bool isApple;

  const _SocialButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: icon,
      label: Text(
        text,
        style: TextStyle(
          color: isApple ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isApple ? Colors.black : Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}