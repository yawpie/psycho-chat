import 'package:flutter/material.dart';
import 'package:psycho_chat/domain/usecases/login.dart';
import 'package:psycho_chat/presentation/pages/chat_page.dart';
import 'package:psycho_chat/presentation/pages/psikiater_login_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  // final LoginUseCase loginUseCase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Text("This is Intro Page"),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // background
                foregroundColor: Colors.white, // foreground
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
              child: Text('Pasien'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // backgroundColor: Colors.blue, // background
                foregroundColor: Colors.white, // foreground
                side: const BorderSide(
                  color: Colors.blue,
                  width: 2.0
                )
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PsikiaterLoginPage()),
                );
              },
              child: Text('Psikiater',style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            Spacer()
          ],
        ),
      ),
    );
  }
}
