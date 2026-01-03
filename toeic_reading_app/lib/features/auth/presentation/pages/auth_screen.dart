import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthMode { signIn, signUp }

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _authMode = AuthMode.signIn;
  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Reset form khi chuyển đổi chế độ
  void _switchAuthMode() {
    if (_authMode == AuthMode.signIn) {
      setState(() {
        _authMode = AuthMode.signUp;
      });
    } else {
      setState(() {
        _authMode = AuthMode.signIn;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final authBloc = context.read<AuthBloc>();

    if (_authMode == AuthMode.signIn) {
      // Gửi sự kiện Đăng nhập
      authBloc.add(SignInEvent(email: email, password: password));
    } else {
      // Gửi sự kiện Đăng ký
      authBloc.add(SignUpEvent(email: email, password: password, name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // 1. XỬ LÝ LỖI
        if (state is AuthError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }

        // 2. XỬ LÝ THÀNH CÔNG (QUAN TRỌNG)
        // Khi đăng nhập/đăng ký thành công -> Đóng màn hình này để quay lại trang trước
        if (state is Authenticated) {
          Navigator.of(context).pop(); // Đóng AuthScreen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xin chào, ${state.user.name ?? "bạn"}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Colors.blueGrey[50],
          appBar: AppBar(
            title: Text(_authMode == AuthMode.signIn ? 'Đăng Nhập' : 'Đăng Ký'),
            backgroundColor: Colors.blueGrey[800],
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // --- FORM FIELDS ---
                        if (_authMode == AuthMode.signUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Họ và Tên', prefixIcon: Icon(Icons.person)),
                            validator: (val) => val!.isEmpty ? 'Vui lòng nhập tên' : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => !val!.contains('@') ? 'Email không hợp lệ' : null,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock)),
                          obscureText: true,
                          validator: (val) => val!.length < 6 ? 'Mật khẩu quá ngắn' : null,
                        ),

                        if (_authMode == AuthMode.signUp) ...[
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(labelText: 'Xác nhận Mật khẩu', prefixIcon: Icon(Icons.lock)),
                            obscureText: true,
                            validator: (val) => val != _passwordController.text ? 'Mật khẩu không khớp' : null,
                          ),
                        ],

                        const SizedBox(height: 25),

                        // --- BUTTONS ---
                        if (isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            ),
                            child: Text(_authMode == AuthMode.signIn ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ'),
                          ),

                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: isLoading ? null : _switchAuthMode,
                          child: Text(
                            _authMode == AuthMode.signIn
                                ? 'Chưa có tài khoản? Đăng ký ngay!'
                                : 'Đã có tài khoản? Đăng nhập!',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}