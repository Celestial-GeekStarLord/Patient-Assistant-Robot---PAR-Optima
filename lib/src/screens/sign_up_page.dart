import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // 1. Import AuthService
import 'home_page.dart'; // 2. Import the Role-Based Router

class SignUpPage extends StatefulWidget {
  // Renamed the class to SignUpPage for clarity
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // --- Controllers ---
  final TextEditingController _nameController = TextEditingController(); // Added Name
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- Form Key for Validation ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- State for Loading ---
  bool _isLoading = false;

  // --- Theme Colors ---
  final Color skyBlue = const Color(0xFF87CEEB);
  final Color offWhite = const Color(0xFFFAF9F6);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- SIGN UP LOGIC ---
  Future<void> _handleSignup() async {
    // 1. Validate all fields using the FormKey
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // 2. Call the AuthService signUp method
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        customId: _userIdController.text.trim(),
      );

      // 3. On success, navigate to the Role-Based Router (HomePage)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Logging you in...')),
        );
        // Navigate to the router, which will determine the correct interface
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      // 4. Handle and display errors (e.g., Invalid ID prefix, Email already in use)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', 'Registration Failed: ')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- VALIDATION HELPERS ---

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  String? _validateCustomId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Custom ID is required.';
    }
    final upperId = value.toUpperCase();
    if (!upperId.startsWith('PAT') && !upperId.startsWith('STF') && !upperId.startsWith('RBT')) {
      return 'ID must start with PAT, STF, or RBT.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      // AppBar to allow users to go back to Login
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: skyBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form( // Wrap everything in a Form for validation
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Icon / Logo
                  Icon(Icons.person_add_rounded, size: 80, color: skyBlue),
                  const SizedBox(height: 10),

                  // 2. Title
                  Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- NEW: Full Name Field ---
                  _buildTextField(
                    controller: _nameController,
                    hint: "Full Name",
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    validator: (v) => _validateRequired(v, 'Full Name'),
                  ),
                  const SizedBox(height: 15),

                  // 3. Email Field
                  _buildTextField(
                    controller: _emailController,
                    hint: "Email Address",
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || !v.contains('@')) return 'Enter a valid email.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // 4. User ID Field (Custom ID)
                  _buildTextField(
                    controller: _userIdController,
                    hint: "User ID (e.g. PAT402_JohnSmith)",
                    icon: Icons.badge_rounded,
                    validator: _validateCustomId, // Validate role prefix
                  ),
                  const SizedBox(height: 15),

                  // 5. Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hint: "Password",
                    icon: Icons.lock_rounded,
                    isPassword: true,
                    // Use the secure validation helper from AuthService
                    validator: (v) => AuthService.validatePassword(v ?? ''),
                  ),
                  const SizedBox(height: 15),

                  // 6. Confirm Password Field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: "Confirm Password",
                    icon: Icons.lock_clock_rounded,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm password is required.';
                      if (v != _passwordController.text) return 'Passwords do not match.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // 7. Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup, // Disable if loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: skyBlue.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : const Text(
                        "SIGN UP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method updated to use TextFormField for validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: skyBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        // Style for error state
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
    );
  }
}