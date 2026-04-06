import 'package:flutter/material.dart';
import 'package:uz_license_plate/uz_license_plate.dart';

void main() {
  runApp(const UzLicensePlateExampleApp());
}

/// Sample numbers covering main [UzPlateCategory] cases from the parser.
const List<({String label, String number})> _demoPlates = [
  (label: 'Standard (8)', number: '01A123456'),
  (label: 'Standard (01G style)', number: '01G604CC'),
  (label: '5+3', number: '12345ABC'),
  (label: '5+2', number: '12345AB'),
  (label: 'Taxi', number: '01H000069'),
  (label: 'Truck', number: '01M123456'),
  (label: 'Electric (yur)', number: '12345ABEEEE'),
  (label: 'Electric (fiz)', number: '01A123AEEEEE'),
  (label: 'Police (PAA)', number: 'PAA001'),
  (label: 'Government (T+6)', number: 'A123456'),
  (label: 'UN diplomatic', number: 'UN1234'),
  (label: 'CMD diplomatic', number: 'CMD5678'),
  (label: 'Unknown / fallback', number: 'XYZ99'),
];

class UzLicensePlateExampleApp extends StatelessWidget {
  const UzLicensePlateExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UZ license plate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _DemoHomePage(),
    );
  }
}

class _DemoHomePage extends StatefulWidget {
  const _DemoHomePage();

  @override
  State<_DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<_DemoHomePage> {
  final TextEditingController _controller = TextEditingController(
    text: '01A123456',
  );
  UzPlateSize _size = UzPlateSize.large;
  bool _showFlag = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('uz_license_plate example')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Plate number',
              border: OutlineInputBorder(),
              hintText: 'e.g. 01A123456',
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Size:'),
              SegmentedButton<UzPlateSize>(
                segments: const [
                  ButtonSegment(value: UzPlateSize.small, label: Text('S')),
                  ButtonSegment(value: UzPlateSize.medium, label: Text('M')),
                  ButtonSegment(value: UzPlateSize.large, label: Text('L')),
                ],
                selected: {_size},
                onSelectionChanged: (s) => setState(() => _size = s.first),
              ),
              FilterChip(
                label: const Text('Flag'),
                selected: _showFlag,
                onSelected: (v) => setState(() => _showFlag = v),
              ),
              FilledButton(
                onPressed: () => setState(() {}),
                child: const Text('Preview'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Custom preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Center(
            child: UzLicensePlate(
              plateNumber: _controller.text,
              size: _size,
              showFlag: _showFlag,
            ),
          ),
          if (parseUzPlate(_controller.text) case final r?) ...[
            const SizedBox(height: 8),
            Text(
              'Parsed: ${r.category.name} · normalized ${r.normalized}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 28),
          Text('Gallery', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._demoPlates.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.label}: ${e.number}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: UzLicensePlate(
                      plateNumber: e.number,
                      size: _size,
                      showFlag: _showFlag,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
