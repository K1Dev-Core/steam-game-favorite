import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, FirebaseAuth? auth}) : _auth = auth;
  final FirebaseAuth? _auth;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  FirebaseAuth get _auth => widget._auth ?? FirebaseAuth.instance;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        await _auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await _auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'เชื่อมต่อไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'กรอกอีเมลก่อนขอเปลี่ยนรหัสผ่าน');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งลิงก์เปลี่ยนรหัสผ่านแล้ว')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F2F7),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        CupertinoIcons.game_controller_solid,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _register ? 'สร้างบัญชี' : 'Steam Favorite',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _register
                        ? 'สมัครเพื่อเก็บเกมโปรดบน Cloud'
                        : 'เข้าสู่ระบบเพื่อดูเกมโปรดของคุณ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('authEmail'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _input('อีเมล', CupertinoIcons.mail),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'กรุณากรอกอีเมล';
                            if (!text.contains('@') || !text.contains('.')) {
                              return 'รูปแบบอีเมลไม่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 1, indent: 52),
                        TextFormField(
                          key: const Key('authPassword'),
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _input(
                            'รหัสผ่าน',
                            CupertinoIcons.lock,
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                size: 20,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกรหัสผ่าน';
                            }
                            if (value.length < 6) {
                              return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (!_register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: _loading ? null : _resetPassword,
                        child: const Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('authSubmit'),
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            _register ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                    child: Text(
                      _register
                          ? 'มีบัญชีแล้ว? เข้าสู่ระบบ'
                          : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.lock_shield,
                        size: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ข้อมูลส่วนตัวปกป้องด้วย Firebase',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      );
}

String authErrorMessage(String code) => switch (code) {
  'weak-password' => 'รหัสผ่านสั้นเกินไป ใช้อย่างน้อย 6 ตัวอักษร',
  'email-already-in-use' => 'อีเมลนี้สมัครสมาชิกแล้ว',
  'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
  'user-disabled' => 'บัญชีนี้ถูกระงับ',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
  'too-many-requests' => 'ลองหลายครั้งเกินไป กรุณารอสักครู่',
  'network-request-failed' => 'ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
  _ => 'เข้าสู่ระบบไม่สำเร็จ ($code)',
};
