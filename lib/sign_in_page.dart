import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Sikeres bejelentkezés esetén navigálj a főoldalra
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _errorMessage = 'No such user found.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Incorrect password.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'Invalid email address.';
          } else {
            _errorMessage = 'Issue: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Unexpected issue: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegistering = true;
        _errorMessage = null;
      });

      try {
        // Új felhasználó létrehozása Firebase Authentication segítségével
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Opcionálisan küldhetünk email megerősítést
        await userCredential.user?.sendEmailVerification();

        if (mounted) {
          // Sikeres regisztráció üzenet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successful registration, please log in.'),
              backgroundColor: Colors.green,
            ),
          );

          // Töröljük a jelszó mezőt a regisztráció után
          _passwordController.clear();
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'weak-password') {
            _errorMessage = 'Password too weak.';
          } else if (e.code == 'email-already-in-use') {
            _errorMessage = 'This email is already in use.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'Invalid email address.';
          } else {
            _errorMessage = 'Registration issue: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Unexpected issue during registration: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.jpg'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Min 6 caracter long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIGN IN',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isLoading || _isRegistering) ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'REGISTRATION',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text(
                    'Use without login',
                    style: TextStyle(
                      color: Colors.brown,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
