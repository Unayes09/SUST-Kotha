import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'recording_screen.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _nameCtrl = TextEditingController(text: 'Unayes');
  String _selectedRegion = 'Sylhet';
  String _selectedGender = 'Male';

  final List<String> regions = ['Sylhet', 'Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 'Barisal'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Thread')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Speaker Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
              items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedRegion = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
              items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGender = val!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_nameCtrl.text.isEmpty) return;
                final provider = Provider.of<AppProvider>(context, listen: false);
                await provider.createNewThread(_selectedRegion, _selectedGender, _nameCtrl.text);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Create Thread'),
            ),
          ],
        ),
      ),
    );
  }
}