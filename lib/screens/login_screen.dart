import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool isLogin = true;
  String errorMessage = '';
  bool _obscure = true;
  bool _isResettingPassword = false;

  Future<bool> _hasUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Silakan masukkan email terlebih dahulu")),
        );
      }
      return;
    }

    try {
      setState(() => _isResettingPassword = true);
      await _auth.sendPasswordResetEmail(email: email.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Email reset password telah dikirim. Cek inbox Anda."),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Gagal mengirim email reset password";
      if (e.code == 'user-not-found') {
        errorMsg = "Email tidak ditemukan";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Format email tidak valid";
      } else if (e.code == 'too-many-requests') {
        errorMsg = "Terlalu banyak permintaan. Coba lagi nanti.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      setState(() => _isResettingPassword = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lupa Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan email Anda untuk menerima link reset password",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: "nama@email.com",
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: _isResettingPassword
                ? null
                : () => _resetPassword(resetEmailController.text),
            child: _isResettingPassword
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Kirim Link"),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validasi input
    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Email dan password tidak boleh kosong");
      return;
    }

    try {
      final startTime = DateTime.now();
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user?.uid;
      if (uid == null) {
        setState(() => errorMessage = "Login gagal: user tidak valid");
        return;
      }

      final profileExists = await _hasUserProfile(uid);
      if (!profileExists) {
        await _auth.signOut();
        setState(() {
          errorMessage =
              "Akun belum selesai registrasi (profil tidak ditemukan). Silakan daftar ulang.";
        });
        return;
      }

      final elapsed = DateTime.now().difference(startTime);

      if (!mounted) return;

      // Show bottom popup for 2 seconds with elapsed time, then navigate
      final seconds = (elapsed.inMilliseconds / 1000).toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil login dalam $seconds detik'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        setState(() {
          errorMessage =
              "Login gagal karena Firestore Rules menolak baca profil user.";
        });
        return;
      }

      setState(
          () => errorMessage = "Terjadi kesalahan: ${e.message ?? e.code}");
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Login gagal";
      if (e.code == 'user-not-found') {
        errorMsg = "Email tidak terdaftar";
      } else if (e.code == 'wrong-password') {
        errorMsg = "Password salah";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Format email tidak valid";
      } else if (e.code == 'user-disabled') {
        errorMsg = "Akun telah dinonaktifkan";
      }
      setState(() => errorMessage = errorMsg);
    } catch (e) {
      setState(() => errorMessage = "Terjadi kesalahan: $e");
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Validasi input
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() => errorMessage = "Semua field harus diisi");
      return;
    }

    if (password.length < 6) {
      setState(() => errorMessage = "Password minimal 6 karakter");
      return;
    }

    if (name.length < 2) {
      setState(() => errorMessage = "Nama minimal 2 karakter");
      return;
    }

    try {
      // Buat akun baru
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        // Simpan data pengguna ke Firestore
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'onboarding_seen': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseException catch (firestoreError) {
        // ⚠️ ROLLBACK: Jika Firestore gagal, hapus akun di Authentication
        debugPrint(
            "❌ Firestore error [${firestoreError.code}]: ${firestoreError.message}");
        debugPrint("🔄 Melakukan rollback - menghapus akun Authentication...");

        try {
          await userCred.user!.delete();
          debugPrint("✅ Akun berhasil dihapus");
        } catch (deleteError) {
          debugPrint("⚠️ Gagal menghapus akun: $deleteError");
        }

        await _auth.signOut();

        String firestoreMsg = "Gagal menyimpan data profil. Silakan coba lagi.";
        if (firestoreError.code == 'permission-denied') {
          firestoreMsg =
              "Registrasi gagal karena Firestore Rules menolak akses (permission-denied).";
        }

        setState(() => errorMessage = firestoreMsg);
      } catch (firestoreError) {
        debugPrint("❌ Firestore unknown error: $firestoreError");

        try {
          await userCred.user!.delete();
        } catch (_) {}

        await _auth.signOut();

        setState(() =>
            errorMessage = "Gagal menyimpan data profil. Silakan coba lagi.");
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Registrasi gagal";
      if (e.code == 'email-already-in-use') {
        errorMsg = "Email sudah terdaftar";
      } else if (e.code == 'weak-password') {
        errorMsg = "Password terlalu lemah";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Format email tidak valid";
      } else if (e.code == 'operation-not-allowed') {
        errorMsg = "Operasi tidak diizinkan";
      }
      setState(() => errorMessage = errorMsg);
    } catch (e) {
      setState(() => errorMessage = "Terjadi kesalahan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primary.withOpacity(0.1),
              color.secondary.withOpacity(0.07),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Selamat datang",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kelola kesehatan mental dengan tenang dan aman.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text("Login"),
                              selected: isLogin,
                              onSelected: (_) => setState(() => isLogin = true),
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text("Daftar"),
                              selected: !isLogin,
                              onSelected: (_) =>
                                  setState(() => isLogin = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!isLogin) ...[
                          Text(
                            "Nama lengkap",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: "Isi nama Anda",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          "Email",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: "nama@email.com",
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Password",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: "••••••••",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: isLogin ? _signIn : _register,
                          child: Text(isLogin ? "Masuk" : "Buat akun"),
                        ),
                        const SizedBox(height: 12),
                        if (isLogin)
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text("Lupa password?"),
                          ),
                        if (isLogin) const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin
                                ? "Belum punya akun? Daftar"
                                : "Sudah punya akun? Login",
                          ),
                        ),
                        if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_moon_outlined,
                        color: color.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Data Anda terenkripsi & aman",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
