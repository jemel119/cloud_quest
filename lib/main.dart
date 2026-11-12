import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(demoProjectId: 'demo-cloud-quest');

  const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  final auth = FirebaseAuth.instance;
  await auth.useAuthEmulator(emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);

  runApp(CloudQuestApp(home: AuthGate(auth: auth)));
}

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key, this.home = const SignInScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Cloud Quest', home: home);
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});

  final FirebaseAuth auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cloud Quest')),
            body: const Center(child: Text('Could not check your sign-in.')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(
            onSignIn: (email, password) async {
              await auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cloud Quest'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await auth.signOut();
                  } on FirebaseAuthException {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not sign out.')),
                    );
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
          body: Center(child: Text('Signed in as ${user.email ?? 'learner'}')),
        );
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.onSignIn});

  final Future<void> Function(String email, String password)? onSignIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final onSignIn = widget.onSignIn;
    if (_submitting || onSignIn == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await onSignIn(_email.text.trim(), _password.text);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == 'network-request-failed'
            ? 'Could not connect. Check your connection and try again.'
            : 'Unable to sign in. Check your email and password.';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Quest')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Sign in to start your quest.'),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@')
                          ? null
                          : 'Enter a valid email address.';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting || widget.onSignIn == null
                        ? null
                        : _signIn,
                    child: Text(_submitting ? 'Signing in…' : 'Sign in'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
