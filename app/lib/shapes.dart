import 'dart:math' as math;

enum ShapeKind {
  roundBar,
  squareBar,
  flatBar,
  hexBar,
  wire,
  roundTube,
  squareTube,
  rectTube,
  plate,
  angle,
  channel,
  beam,
  ring,
}

class ShapeField {
  final String key;
  final String label;
  final bool isLength;
  final double defaultMm;

  const ShapeField(this.key, this.label, {this.isLength = false, required this.defaultMm});
}

extension ShapeKindX on ShapeKind {
  String get name => switch (this) {
        ShapeKind.roundBar => 'قضيب دائري',
        ShapeKind.squareBar => 'قضيب مربع',
        ShapeKind.flatBar => 'قضيب مستطيل',
        ShapeKind.hexBar => 'قضيب سداسي',
        ShapeKind.wire => 'سلك',
        ShapeKind.roundTube => 'أنبوب دائري',
        ShapeKind.squareTube => 'أنبوب مربع',
        ShapeKind.rectTube => 'أنبوب مستطيل',
        ShapeKind.plate => 'لوح / صفيحة',
        ShapeKind.angle => 'زاوية',
        ShapeKind.channel => 'مجرى U',
        ShapeKind.beam => 'كمرة I/H',
        ShapeKind.ring => 'حلقة',
      };

  String get category => switch (this) {
        ShapeKind.roundBar ||
        ShapeKind.squareBar ||
        ShapeKind.flatBar ||
        ShapeKind.hexBar ||
        ShapeKind.wire =>
          'قضبان وأسلاك',
        ShapeKind.roundTube ||
        ShapeKind.squareTube ||
        ShapeKind.rectTube =>
          'مواسير وأنابيب',
        ShapeKind.plate => 'ألواح وصفائح',
        ShapeKind.angle || ShapeKind.channel || ShapeKind.beam => 'مقاطع إنشائية',
        ShapeKind.ring => 'حلقات',
      };

  String get formula => switch (this) {
        ShapeKind.roundBar || ShapeKind.wire => 'π/4 × d² × L',
        ShapeKind.squareBar => 'a² × L',
        ShapeKind.flatBar => 'W × t × L',
        ShapeKind.hexBar => '(√3/2) × AF² × L',
        ShapeKind.roundTube => 'π/4 × (OD² − (OD−2t)²) × L',
        ShapeKind.squareTube => '(a² − (a−2t)²) × L',
        ShapeKind.rectTube => '(W×H − (W−2t)(H−2t)) × L',
        ShapeKind.plate => 'L × W × t',
        ShapeKind.angle => '(A+B−t) × t × L',
        ShapeKind.channel => '(H×t + 2(W−t)t) × L',
        ShapeKind.beam => '(2B×tf + (H−2tf)tw) × L',
        ShapeKind.ring => 'π/4 × (OD² − ID²) × t',
      };

  List<ShapeField> get fields => switch (this) {
        ShapeKind.roundBar => const [
            ShapeField('d', 'القطر', defaultMm: 20),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.squareBar => const [
            ShapeField('a', 'ضلع المربع', defaultMm: 20),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.flatBar => const [
            ShapeField('W', 'العرض', defaultMm: 40),
            ShapeField('t', 'السماكة', defaultMm: 5),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.hexBar => const [
            ShapeField('AF', 'المسافة بين الضلعين', defaultMm: 20),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.wire => const [
            ShapeField('d', 'القطر', defaultMm: 2),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.roundTube => const [
            ShapeField('OD', 'القطر الخارجي', defaultMm: 50),
            ShapeField('t', 'سماكة الجدار', defaultMm: 3),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.squareTube => const [
            ShapeField('a', 'ضلع المربع', defaultMm: 50),
            ShapeField('t', 'سماكة الجدار', defaultMm: 3),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.rectTube => const [
            ShapeField('W', 'العرض', defaultMm: 60),
            ShapeField('H', 'الارتفاع', defaultMm: 40),
            ShapeField('t', 'سماكة الجدار', defaultMm: 3),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.plate => const [
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
            ShapeField('W', 'العرض', defaultMm: 500),
            ShapeField('t', 'السماكة', defaultMm: 5),
          ],
        ShapeKind.angle => const [
            ShapeField('A', 'الضلع A', defaultMm: 50),
            ShapeField('B', 'الضلع B', defaultMm: 50),
            ShapeField('t', 'السماكة', defaultMm: 5),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.channel => const [
            ShapeField('H', 'الارتفاع', defaultMm: 100),
            ShapeField('W', 'عرض الفلنجة', defaultMm: 50),
            ShapeField('t', 'السماكة', defaultMm: 5),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.beam => const [
            ShapeField('H', 'الارتفاع', defaultMm: 200),
            ShapeField('B', 'عرض الفلنجة', defaultMm: 100),
            ShapeField('tw', 'سماكة الويب', defaultMm: 6),
            ShapeField('tf', 'سماكة الفلنجة', defaultMm: 8),
            ShapeField('L', 'الطول', isLength: true, defaultMm: 1000),
          ],
        ShapeKind.ring => const [
            ShapeField('OD', 'القطر الخارجي', defaultMm: 100),
            ShapeField('ID', 'القطر الداخلي', defaultMm: 60),
            ShapeField('t', 'السماكة', defaultMm: 10),
          ],
      };

  double volumeMm3(Map<String, double> v) {
    final L = v['L'] ?? (this == ShapeKind.ring || this == ShapeKind.plate ? 1.0 : 0.0);

    double val(String key) => math.max(0.0, v[key] ?? 0.0);

    return switch (this) {
      ShapeKind.roundBar || ShapeKind.wire =>
        math.pi / 4 * math.pow(val('d'), 2) * L,
      ShapeKind.squareBar =>
        math.pow(val('a'), 2) * L,
      ShapeKind.flatBar =>
        val('W') * val('t') * L,
      ShapeKind.hexBar =>
        math.sqrt(3) / 2 * math.pow(val('AF'), 2) * L,
      ShapeKind.roundTube =>
        math.pi / 4 * (math.pow(val('OD'), 2) - math.pow(math.max(0.0, val('OD') - 2 * val('t')), 2)) * L,
      ShapeKind.squareTube =>
        (math.pow(val('a'), 2) - math.pow(math.max(0.0, val('a') - 2 * val('t')), 2)) * L,
      ShapeKind.rectTube =>
        (val('W') * val('H') - math.max(0.0, val('W') - 2 * val('t')) * math.max(0.0, val('H') - 2 * val('t'))) * L,
      ShapeKind.plate =>
        L * val('W') * val('t'),
      ShapeKind.angle =>
        math.max(0.0, val('A') + val('B') - val('t')) * val('t') * L,
      ShapeKind.channel =>
        (val('H') * val('t') + 2 * math.max(0.0, val('W') - val('t')) * val('t')) * L,
      ShapeKind.beam =>
        (2 * val('B') * val('tf') + math.max(0.0, val('H') - 2 * val('tf')) * val('tw')) * L,
      ShapeKind.ring =>
        math.pi / 4 * (math.pow(val('OD'), 2) - math.pow(val('ID'), 2)) * val('t'),
    };
  }
}

class MaterialItem {
  final String id;
  final String name;
  final double density;

  const MaterialItem(this.id, this.name, this.density);
}

const kMaterials = <MaterialItem>[
  MaterialItem('mild', 'فولاذ طري', 7850),
  MaterialItem('carbon', 'فولاذ كربوني', 7850),
  MaterialItem('ss304', 'ستانلس 304', 7930),
  MaterialItem('ss316', 'ستانلس 316', 8000),
  MaterialItem('castIron', 'حديد زهر', 7200),
  MaterialItem('aluminum', 'ألومنيوم', 2700),
  MaterialItem('copper', 'نحاس', 8960),
  MaterialItem('brass', 'براص', 8500),
  MaterialItem('bronze', 'برونز', 8800),
  MaterialItem('lead', 'رصاص', 11340),
  MaterialItem('zinc', 'زنك', 7130),
  MaterialItem('titanium', 'تيتانيوم', 4500),
  MaterialItem('nickel', 'نيكل', 8900),
];

double calcWeightKg({
  required double volumeMm3,
  required double densityKgM3,
  required double quantity,
}) {
  if (volumeMm3 <= 0 || densityKgM3 <= 0 || quantity <= 0) return 0;
  return (volumeMm3 / 1e9) * densityKgM3 * quantity;
}
