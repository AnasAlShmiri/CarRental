import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = AppScope.of(context).auth;
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return Scaffold(
      backgroundColor: AppTheme.midnight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _brandMark(),
                const SizedBox(height: 52),
                const Text(
                  'رحلتك تبدأ من هنا.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'اكتشف سياراتك المفضلة واحجز رحلتك بسهولة وأمان.',
                  style: TextStyle(
                    color: Color(0xA8FFFFFF),
                    height: 1.7,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 35),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'دخول العميل',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'استخدم بريدك الإلكتروني للمتابعة',
                          style: TextStyle(color: AppTheme.muted, fontSize: 11),
                        ),
                        const SizedBox(height: 22),
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
                            if (email.isEmpty || !email.contains('@')) {
                              return 'أدخل بريدًا إلكترونيًا صحيحًا';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
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
                          validator: (value) => value == null || value.length < 6
                              ? 'كلمة المرور يجب ألا تقل عن 6 أحرف'
                              : null,
                        ),
                        const SizedBox(height: 21),
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
                                      color: AppTheme.primaryLight,
                                    ),
                                  )
                                : const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              auth.isLoading ? 'جارٍ الدخول...' : 'دخول آمن',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.pushNamed(context, '/register'),
                          child: const Text('ليس لديك حساب؟ أنشئ حساب عميل'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'بياناتك محمية باتصال آمن',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _brandMark() => Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppTheme.midnight,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAR RENTAL',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 15,
                  letterSpacing: 2.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your premium journey',
                style: TextStyle(
                  color: Color(0x88FFFFFF),
                  fontSize: 10,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ],
      );
}
