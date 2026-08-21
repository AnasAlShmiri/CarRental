import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = AppScope.of(context).auth;
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('إنشاء حساب عميل'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ابدأ رحلتك',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أنشئ حسابك واحجز السيارة المناسبة لك.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.length < 2) return 'أدخل الاسم الكامل';
                      if (name.length > 100) return 'الاسم طويل جدًا';
                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      final valid = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email);
                      if (!valid) return 'أدخل بريدًا إلكترونيًا صحيحًا';
                      if (email.length > 150) {
                        return 'البريد الإلكتروني طويل جدًا';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      return RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(phone)
                          ? null
                          : 'رقم الهاتف يجب أن يحتوي على أرقام ورموز الاتصال فقط وبطول من 7 إلى 20 محرفًا';
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      final strong = RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z\s]).{8,100}$',
                      ).hasMatch(password);
                      return strong
                          ? null
                          : 'كلمة المرور: 8 أحرف على الأقل مع حرف كبير وصغير ورقم ورمز';
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? 'كلمتا المرور غير متطابقتين'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: auth,
                    builder: (context, _) => ElevatedButton.icon(
                      onPressed: auth.isLoading ? null : _submit,
                      icon: auth.isLoading
                          ? const SizedBox(
                              height: 19,
                              width: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(Icons.rocket_launch_outlined),
                      label: Text(
                        auth.isLoading
                            ? 'جارٍ إنشاء الحساب...'
                            : 'إنشاء الحساب',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('لديك حساب؟ تسجيل الدخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
