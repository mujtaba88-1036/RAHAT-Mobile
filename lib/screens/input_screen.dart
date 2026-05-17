import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crisis_provider.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  bool _includeWeather = true;
  bool _includeTraffic = true;

  @override
  void dispose() {
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  void _analyzeCrisis() {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the crisis')),
      );
      return;
    }

    List<Map<String, dynamic>> inputs = [
      {"source": "social", "text": "${_locController.text.trim()} - ${_descController.text.trim()}"}
    ];

    if (_includeWeather) {
      inputs.add({"source": "weather", "text": "Heavy rainfall alert Islamabad Rawalpindi region"});
    }
    if (_includeTraffic) {
      inputs.add({"source": "traffic", "text": "High congestion detected in Islamabad"});
    }

    // Navigate to home FIRST
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // THEN start analysis (home screen will show the overlay)
    context.read<CrisisProvider>().analyze(inputs);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CrisisProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Text('Report Crisis', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: Colors.red[900], height: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe the Crisis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E2329),
                hintText: 'G-10 mein pani bhar gaya hai... or type in English',
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF1E2329),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud, color: Colors.blue),
                          const SizedBox(height: 4),
                          const Text('Weather Data', style: TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Switch(
                            value: _includeWeather,
                            onChanged: (val) => setState(() => _includeWeather = val),
                            activeColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: const Color(0xFF1E2329),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Column(
                        children: [
                          const Icon(Icons.traffic, color: Colors.orange),
                          const SizedBox(height: 4),
                          const Text('Traffic Data', style: TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Switch(
                            value: _includeTraffic,
                            onChanged: (val) => setState(() => _includeTraffic = val),
                            activeColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Affected Area', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E2329),
                hintText: 'e.g. G-10, Faizabad, F-8 Markaz',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _analyzeCrisis,
                icon: const Text('🚨', style: TextStyle(fontSize: 20)),
                label: const Text(
                  'Analyze Crisis',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
