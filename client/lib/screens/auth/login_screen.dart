import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  static const _mobileLength = 10;

  @override
  Widget build(BuildContext context) {
    final auth = Get.put(AuthController());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 480 ? 420.0 : constraints.maxWidth - 32;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.05),
                      Center(
                        child: Image.asset(
                          'lib/assets/authLogo.jpeg',
                          height: 96,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to\nLoagma PMS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your mobile number',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: _mobileLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Mobile number',
                            hintText: 'Enter 10-digit number',
                            prefixIcon: Icon(
                              Icons.phone_android_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your mobile number';
                            }
                            if (v.length != _mobileLength) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                          onChanged: (_) => auth.setMobile(_mobileController.text),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(() {
                        final loading = auth.isLoading.value;
                        return SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading ? null : () => _requestOtp(auth),
                            child: loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Get OTP'),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          "We'll send a one-time password to this number.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _requestOtp(AuthController auth) {
    if (!_formKey.currentState!.validate()) return;
    auth.setMobile(_mobileController.text.trim());
    auth.isLoading.value = true;
    // Simulate API call; replace with real OTP send.
    Future.delayed(const Duration(milliseconds: 800), () {
      auth.isLoading.value = false;
      Get.toNamed(AppRoutes.otp);
    });
  }
}
