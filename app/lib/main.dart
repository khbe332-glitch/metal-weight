import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'shapes.dart'; // ملفك الحالي (ShapeKind, kMaterials, calcWeightKg)

void main() => runApp(const MetalWeightApp());

const _steel = Color(0xFF3E6A8A);
const _amber = Color(0xFFE8A317);

class MetalWeightApp extends StatelessWidget {
  const MetalWeightApp({super.key});

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        brightness: b,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _steel,
          secondary: _amber,
          brightness: b,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حاسبة وزن المعادن',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const _units = {'مم': 1.0, 'سم': 10.0, 'م': 1000.0};

  ShapeKind kind = ShapeKind.roundBar;
  MaterialItem material = kMaterials.first;
  String lengthUnit = 'مم';
  final Map<String, TextEditingController> ctrl = {};
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    for (final c in ctrl.values) {
      c.dispose();
    }
    qty.dispose();
    price.dispose();
    super.dispose();
  }

  void _loadDefaults() {
    ctrl.clear();
    lengthUnit = 'مم';
    for (final f in kind.fields) {
      ctrl[f.key] = TextEditingController(text: _fmt(f.defaultMm));
    }
  }

  static String _fmt(double x) {
    if (x == x.roundToDouble()) return x.toInt().toString();
    return x.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
  }

  static double _num(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  Map<String, double> get _values => {
        for (final f in kind.fields)
          f.key: _num(ctrl[f.key]!.text) * (f.isLength ? _units[lengthUnit]! : 1),
      };

  String? _warning(Map<String, double> v) {
    double? w(String k) => v[k];
    bool bad(double? t, List<double?> dims) =>
        (t ?? 0) > 0 && dims.any((d) => d != null && d > 0 && 2 * t! >= d);
    switch (kind) {
      case ShapeKind.roundTube:
        if (bad(w('t'), [w('OD')])) return 'سماكة الجدار كبيرة جداً بالنسبة للقطر.';
      case ShapeKind.squareTube:
        if (bad(w('t'), [w('a')])) return 'سماكة الجدار كبيرة جداً بالنسبة للضلع.';
      case ShapeKind.rectTube:
        if (bad(w('t'), [w('W'), w('H')])) return 'سماكة الجدار كبيرة جداً بالنسبة للأبعاد.';
      case ShapeKind.ring:
        if ((w('ID') ?? 0) >= (w('OD') ?? 0)) return 'القطر الداخلي يجب أن يكون أصغر من الخارجي.';
      default:
    }
    return null;
  }

  void _changeUnit(String u) {
    final f = kind.fields.firstWhere((f) => f.isLength);
    final c = ctrl[f.key]!;
    final converted = _num(c.text) * _units[lengthUnit]! / _units[u]!;
    setState(() {
      c.text = _fmt(double.parse(converted.toStringAsFixed(4)));
      lengthUnit = u;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final v = _values;
    final volume = kind.volumeMm3(v);
    final q = _num(qty.text);
    final one = calcWeightKg(volumeMm3: volume, densityKgM3: material.density, quantity: 1);
    final total = calcWeightKg(volumeMm3: volume, densityKgM3: material.density, quantity: q);
    final cost = total * _num(price.text);
    final warning = _warning(v);

    final inputFormatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    const keyboard = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة وزن المعادن')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // اختيار الشكل
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final k in ShapeKind.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(k.name),
                      selected: k == kind,
                      onSelected: (_) => setState(() {
                        kind = k;
                        _loadDefaults();
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(kind.category, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(kind.formula, style: tt.titleMedium),
            ),
          ),
          const SizedBox(height: 16),

          // المادة
          DropdownMenu<MaterialItem>(
            expandedInsets: EdgeInsets.zero,
            initialSelection: material,
            label: const Text('المادة'),
            dropdownMenuEntries: [
              for (final m in kMaterials)
                DropdownMenuEntry(
                  value: m,
                  label: '${m.name} (${m.density.toStringAsFixed(0)} كغ/م³)',
                ),
            ],
            onSelected: (m) {
              if (m != null) setState(() => material = m);
            },
          ),
          const SizedBox(height: 16),

          // الأبعاد
          for (final f in kind.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                key: ValueKey('${kind.index}-${f.key}'),
                controller: ctrl[f.key],
                keyboardType: keyboard,
                inputFormatters: inputFormatters,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: f.label,
                  suffixText: f.isLength ? null : 'مم',
                  suffix: f.isLength
                      ? DropdownButton<String>(
                          value: lengthUnit,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final u in _units.keys)
                              DropdownMenuItem(value: u, child: Text(u)),
                          ],
                          onChanged: (u) => _changeUnit(u!),
                        )
                      : null,
                ),
              ),
            ),

          // الكمية والسعر
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: price,
                  keyboardType: keyboard,
                  inputFormatters: inputFormatters,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'سعر الكيلو',
                    helperText: 'اختياري',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // النتيجة
          if (warning != null)
            Card(
              color: cs.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
                title: Text(warning, style: TextStyle(color: cs.onErrorContainer)),
              ),
            )
          else
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('الوزن الإجمالي',
                        style: tt.titleMedium?.copyWith(color: cs.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text(
                      '${total.toStringAsFixed(3)} كغ',
                      style: tt.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _line('وزن القطعة', '${one.toStringAsFixed(3)} كغ', cs),
                    _line('الحجم', '${(volume / 1e6).toStringAsFixed(2)} سم³', cs),
                    if (cost > 0) _line('التكلفة', cost.toStringAsFixed(2), cs),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: cs.onPrimaryContainer)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
          ],
        ),
      );
}
