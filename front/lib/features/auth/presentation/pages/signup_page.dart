import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('이메일', style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                hintText: '이메일을 입력하세요',
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
              ),
            ),
            const SizedBox(height: 20),
            const Text('비밀번호 확인', style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 8),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호를 다시 입력하세요',
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement sign-up logic
                Navigator.of(context).pop(); // Go back to login page after sign up
              },
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('이미 계정이 있으신가요?'),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('로그인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}