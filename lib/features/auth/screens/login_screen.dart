import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(String email, String password) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check user role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String?;
          
          if (role == 'musician') {
            if (mounted) context.go('/musician-home');
          } else if (role == 'client') {
            if (mounted) context.go('/client-home');
          } else {
            if (mounted) context.go('/role-select');
          }
        } else {
          if (mounted) context.go('/role-select');
        }
      }
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          default:
            errorMessage = e.message ?? 'Login failed';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C0800), Color(0xFF07080E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  _buildHeading(),
                  const SizedBox(height: 8),
                  _buildSubtitle(),
                  const SizedBox(height: 24),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 8),
                  _buildForgotPassword(),
                  const SizedBox(height: 20),
                  _buildLoginButton(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildSocialButtons(),
                  const SizedBox(height: 30),
                  _buildBottomText(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in to',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF4EFEA),
            height: 1.2,
          ),
        ),
        Text(
          'continue',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF4EFEA),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Log in to your GigSugo account',
      style: TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 13,
        color: Color(0xFF7E8BA8),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Color(0xFFF4EFEA),
        fontSize: 14,
        fontFamily: 'sans-serif',
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Color(0xFF7E8BA8),
          size: 20,
        ),
        hintText: 'Email address',
        hintStyle: const TextStyle(
          color: Color(0xFF7E8BA8),
          fontSize: 14,
          fontFamily: 'sans-serif',
        ),
        filled: true,
        fillColor: const Color(0xFF0F1424),
        errorStyle: const TextStyle(
          color: Color(0xFFFF5A5F),
          fontSize: 11,
          fontFamily: 'sans-serif',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1C2338),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1C2338),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1C2338),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFF5A5F),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFF5A5F),
            width: 1,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        color: Color(0xFFF4EFEA),
        fontSize: 14,
        fontFamily: 'sans-serif',
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF7E8BA8),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: const Color(0xFF7E8BA8),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        hintText: 'Password',
        hintStyle: const TextStyle(
          color: Color(0xFF7E8BA8),
          fontSize: 14,
          fontFamily: 'sans-serif',
        ),
        filled: true,
        fillColor: const Color(0xFF0F1424),
        errorStyle: const TextStyle(
          color: Color(0xFFFF5A5F),
          fontSize: 11,
          fontFamily: 'sans-serif',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1C2338),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1C2338),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF5A623),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFF5A5F),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFF5A5F),
            width: 1.5,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implement forgot password
        },
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            color: Color(0xFFF5A623),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFE8863A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  _login(
                    _emailController.text.trim(),
                    _passwordController.text,
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF07080E),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Log In',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF07080E),
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFF3A3A3A),
            thickness: 0.5,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Color(0xFF7E8BA8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFF3A3A3A),
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: SignInButton(
              Buttons.google,
              text: 'Google',
              onPressed: () {
                // TODO: Implement Google login
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const FaIcon(
                FontAwesomeIcons.facebook,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Facebook',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                // TODO: Implement Facebook login
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomText() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'New here? ',
          style: const TextStyle(
            color: Color(0xFF7E8BA8),
            fontSize: 14,
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  context.go('/register');
                },
                child: const Text(
                  'Create account',
                  style: TextStyle(
                    color: Color(0xFFF5A623),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
