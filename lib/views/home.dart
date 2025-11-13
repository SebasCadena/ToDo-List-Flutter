import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('To Do List'),
        actions: [
          Icon(Icons.person)
        ],
        
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              Text("Tus Tareas", style: TextStyle(fontSize: 20),),
              SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Checkbox(
                        // Asigna el valor de la variable al estado del checkbox
                        value: _isChecked,
                        
                        // Usa onChanged para cambiar el estado cuando se hace clic
                        onChanged: (bool? newValue) {
                          // Actualiza el estado dentro de una función setState
                          setState(() {
                            _isChecked = newValue!;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text("Item 1"),
                      )
                    ],
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
