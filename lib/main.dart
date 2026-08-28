import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blueGrey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'Expense Tracker',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: const Text(
                    'Hello World',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(179, 32, 214, 4),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: const Text(
                    'Track your expenses easily',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(179, 5, 62, 249),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                Expanded(
                  child: const Text(
                    'Track your  goals',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(179, 240, 4, 4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20, width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello World',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(179, 57, 4, 214),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Track your expenses easily',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(179, 5, 62, 249),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Track your  goals',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(179, 240, 4, 4),
                  ),
                ),
                Container(
                  width: 200,
                  height: 100,
                  margin: const EdgeInsets.only(top: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueGrey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: const Text(
                          'Hello World',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(179, 57, 4, 214),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Image(
                          image: AssetImage('assets/profile.png'),
                          width: 40,
                          height: 40,
                        ),
                      ),

                      Positioned(
                        top: 80,
                        left: 80,
                        child: const Text(
                          'Track your goals',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(179, 240, 4, 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
