import 'package:check_in_point/providers/auth_provider.dart';
import 'package:check_in_point/screens/register_screen.dart';
import 'package:check_in_point/utils/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;
    final result = await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    await showMessageDialog(
      context: context,
      title: result.success ? 'Success' : 'Sign-in failed',
      message: result.message,
    );
    if (result.success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 600;
              final double cardWidth = isWide
                  ? 420
                  : constraints.maxWidth * 0.9;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardWidth),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // App Icon/Logo
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF667eea,
                                            ).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.login,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Welcome Back!',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2D3748),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sign in to continue your journey',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    if (authProvider.errorMessage != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                authProvider.errorMessage!,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          Colors.red.shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          // Email Field
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                hintText: 'you@example.com',
                                                prefixIcon: Container(
                                                  margin: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          colors: [
                                                            Color(0xFF667eea),
                                                            Color(0xFF764ba2),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.email_outlined,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 16,
                                                    ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Email is required';
                                                }
                                                final emailRegex = RegExp(
                                                  r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                                                );
                                                if (!emailRegex.hasMatch(
                                                  value.trim(),
                                                )) {
                                                  return 'Enter a valid email';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Password Field
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ValueListenableBuilder<bool>(
                                              valueListenable: _obscurePassword,
                                              builder: (context, obscure, __) {
                                                return TextFormField(
                                                  controller:
                                                      _passwordController,
                                                  obscureText: obscure,
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  onFieldSubmitted: (_) =>
                                                      _submit(authProvider),
                                                  decoration: InputDecoration(
                                                    labelText: 'Password',
                                                    prefixIcon: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFf093fb,
                                                                ),
                                                                Color(
                                                                  0xFFf5576c,
                                                                ),
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.lock_outline,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    suffixIcon: IconButton(
                                                      tooltip: obscure
                                                          ? 'Show password'
                                                          : 'Hide password',
                                                      icon: Icon(
                                                        obscure
                                                            ? Icons.visibility
                                                            : Icons
                                                                  .visibility_off,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      onPressed: () =>
                                                          _obscurePassword
                                                                  .value =
                                                              !obscure,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 16,
                                                        ),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Password is required';
                                                    }
                                                    if (value.length < 6) {
                                                      return 'At least 6 characters';
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Sign In Button
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: authProvider.isLoading
                                            ? LinearGradient(
                                                colors: [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400,
                                                ],
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFF667eea),
                                                  Color(0xFF764ba2),
                                                ],
                                              ),
                                        boxShadow: authProvider.isLoading
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF667eea,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : () => _submit(authProvider),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.login,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Sign In',
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Register Button
                                    Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF667eea,
                                          ).withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const RegisterScreen(),
                                                  ),
                                                );
                                              },
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_add,
                                              color: authProvider.isLoading
                                                  ? Colors.grey.shade400
                                                  : const Color(0xFF667eea),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Don't have an account? Create one",
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        authProvider.isLoading
                                                        ? Colors.grey.shade400
                                                        : const Color(
                                                            0xFF667eea,
                                                          ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
