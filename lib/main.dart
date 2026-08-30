import 'package:flutter/material.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  List<String> names = [
    "Ali",
    "Ahmed",
    "Ahsan",
    "Ali",
    "Ahmed",
    "Ahsan",
    "Ali",
    "Ahmed",
    "Ahsan",
    "Ali",
    "Ahmed",
    "Ahsan",
  ];

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

                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image(
                            image: AssetImage('assets/profile.png'),
                            width: 40,
                            height: 40,
                          ),
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
            SizedBox(height: 20, width: 20),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 100,
                      height: 100,

                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20, width: 20),
            Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Hello i am going to work do not disturb me untill i come back and i will be back in 2 hours so please wait for me and do not disturb me',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(179, 57, 4, 214),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: names.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.purpleAccent, Colors.yellow],
                      ),

                      border: Border.all(
                        color: const Color.fromARGB(255, 245, 243, 243),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            242,
                            238,
                            238,
                          ).withValues(alpha: 0.5),
                          spreadRadius: 12,
                          blurRadius: 5,
                          offset: Offset(0, 5),
                        ),
                      ],
                      color: const Color.fromARGB(255, 0, 6, 10),
                    ),

                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(2),

                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage('assets/profile.png'),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(5),
                            child: Text(
                              names[index],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
