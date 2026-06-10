// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:psycho_chat/domain/usecases/login.dart';
import 'package:psycho_chat/presentation/pages/psikiater_conversations_page.dart';

class PsikiaterLoginPage extends StatefulWidget {
  const PsikiaterLoginPage({super.key, required this.loginUseCase});
  final LoginUseCase loginUseCase;

  @override
  State<PsikiaterLoginPage> createState() => _PsikiaterLoginPageState();
}

class _PsikiaterLoginPageState extends State<PsikiaterLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _usernameText = "";
  String _passwordText = "default password";

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      // 3. Extract the string value using the .text property
      _usernameText = _usernameController.text;
      _passwordText = _passwordController.text;
    });
    // 4. Print the extracted string value to the console
    print("Username: $_usernameText");
    print("Password: $_passwordText");
    // Implement login logic here, for example, using the AuthRepository to authenticate the user
    // If login is successful, navigate to the conversations page
    await widget.loginUseCase.call(_usernameText, _passwordText);
    navigateToChatPage();
  }

  void navigateToChatPage() {
    // Implement navigation to chat page here
    // For example, using Navigator.push:
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PsikiaterConversationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Psikiater Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 20.0,

            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                  hintText: "Enter your username",
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                  hintText: "Enter your password",
                ),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                child: Text("Login"),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
