import 'package:flutter/material.dart';

import '../personas/persona_data.dart';

class PersonaPage extends StatelessWidget {
  const PersonaPage({super.key});

  String? _routeForPersona(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('partner')) return '/partner';
    if (normalized.contains('admin')) return '/admin';
    if (normalized.contains('investor')) return '/investor';
    if (normalized.contains('shopper')) return '/customer';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Personas")),
      body: ListView.builder(
        itemCount: personas.length,
        itemBuilder: (context, index) {
          final persona = personas[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Persona name
                  Text(
                    persona.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Goals section
                  Text(
                    "Goals:",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (var goal in persona.goals) Text("• $goal"),

                  const SizedBox(height: 12),

                  // Frustrations section
                  Text(
                    "Frustrations:",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (var frustration in persona.frustrations)
                    Text("• $frustration"),

                  const SizedBox(height: 12),

                  // Needs section
                  Text(
                    "Needs:",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (var need in persona.needs) Text("• $need"),
                  if (_routeForPersona(persona.name) != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          _routeForPersona(persona.name)!,
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Open workflow'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
