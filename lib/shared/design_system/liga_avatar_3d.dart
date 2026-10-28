import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/avatar.dart';
import 'liga_game.dart';

/// Avatar 3D da criança, em blocos (como Roblox e Minecraft).
///
/// O boneco é montado com caixas em 3D de verdade e desenhado com um
/// pequeno renderizador próprio (projeção, luz e ordem de pintura), sem
/// motor de jogo: fica leve até em celular simples e gira com o dedo.
class LigaAvatar3D extends StatefulWidget {
  const LigaAvatar3D({
    super.key,
    required this.look,
    required this.size,
    this.bust = false,
    this.yaw = -0.45,
    this.interactive = false,
    this.sway = false,
  });

  final AvatarLook look;

  /// Altura do desenho; a largura acompanha a proporção do enquadramento.
  final double size;

  /// Só cabeça e ombros (para listas e o HUD).
  final bool bust;

  /// Ângulo inicial, em radianos (0 = de frente).
  final double yaw;

  /// Gira arrastando o dedo para os lados.
  final bool interactive;

  /// Balança devagar de um lado para o outro (desliga com [LigaMotion]).
  final bool sway;

  @override
  State<LigaAvatar3D> createState() => _LigaAvatar3DState();
}

class _LigaAvatar3DState extends State<LigaAvatar3D> {
  late double _yaw = widget.yaw;

  @override
  Widget build(BuildContext context) {
    final width = widget.size * (widget.bust ? 1 : 0.8);
    Widget paint(double yaw) => CustomPaint(
      size: Size(width, widget.size),
      painter: AvatarPainter(widget.look, yaw: yaw, bust: widget.bust),
    );

    Widget child;
    if (widget.interactive) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) =>
            setState(() => _yaw -= details.delta.dx * 0.014),
        child: paint(_yaw),
      );
    } else if (widget.sway) {
      child = LigaLoop(
        duration: const Duration(milliseconds: 4200),
        reverse: true,
        builder: (context, t, _) =>
            paint(widget.yaw + 0.55 * Curves.easeInOut.transform(t) - 0.15),
      );
    } else {
      child = paint(_yaw);
    }
    return Semantics(
      label: 'Avatar',
      image: true,
      child: SizedBox(width: width, height: widget.size, child: child),
    );
  }
}

/// Desenha o avatar. Público para os testes e para miniaturas.
class AvatarPainter extends CustomPainter {
  AvatarPainter(this.look, {this.yaw = -0.45, this.bust = false});

  final AvatarLook look;
  final double yaw;
  final bool bust;

  static const _pitch = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    final boxes = _buildAvatarBoxes(look);
    // Enquadramento: corpo inteiro ou só cabeça e ombros.
    final (double low, double high, double halfWidth) = bust
        ? (1.45, 3.2, 0.95)
        : (-0.1, 3.25, 1.25);
    final scale = math.min(
      size.height / (high - low),
      size.width / (halfWidth * 2),
    );
    final view = _View(
      yaw: yaw,
      pitch: _pitch,
      scale: scale,
      origin: Offset(size.width / 2, size.height / 2),
      centerY: (low + high) / 2,
    );

    if (bust) canvas.clipRect(Offset.zero & size);

    // Sombra no chão.
    if (!bust) {
      final floor = view.project(const _V(0, 0, 0));
      canvas.drawOval(
        Rect.fromCenter(
          center: floor + Offset(0, scale * 0.04),
          width: scale * 1.5,
          height: scale * 0.36,
        ),
        Paint()..color = const Color(0x40000000),
      );
    }

    final sorted = [...boxes]
      ..sort((a, b) => view.depth(a).compareTo(view.depth(b)));
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(0.8, scale * 0.022)
      ..color = LigaColors.ink.withValues(alpha: 0.9);
    final fill = Paint();
    for (final box in sorted) {
      for (final face in _Face.values) {
        final normal = view.rotate(face.normal);
        if (normal.z <= 0.001) continue;
        final corners = box.corners(face);
        final path = view.polygon(corners);
        final light = _light(normal);
        fill.color = _shade(box.color, light);
        canvas.drawPath(path, fill);
        if (box.outlined) canvas.drawPath(path, outline);
        for (final decal in box.decals[face] ?? const <_Decal>[]) {
          final points = [
            for (final p in decal.points)
              corners[0] +
                  (corners[1] - corners[0]) * p.dx +
                  (corners[3] - corners[0]) * p.dy,
          ];
          fill.color = _shade(decal.color, light);
          canvas.drawPath(view.polygon(points), fill);
        }
      }
    }
  }

  static double _light(_V normal) {
    const l = _V(-0.42, 0.72, 0.55);
    final dot = normal.x * l.x + normal.y * l.y + normal.z * l.z;
    return 0.66 + 0.46 * dot.clamp(0.0, 1.0);
  }

  static Color _shade(Color color, double light) {
    if (color.a == 0) return color;
    if (light <= 1) {
      return Color.lerp(
        const Color(0xFF0A0F2E),
        color,
        light,
      )!.withValues(alpha: color.a);
    }
    return Color.lerp(
      color,
      Colors.white,
      (light - 1) * 1.4,
    )!.withValues(alpha: color.a);
  }

  @override
  bool shouldRepaint(AvatarPainter old) =>
      old.look != look || old.yaw != yaw || old.bust != bust;
}

// ---------------------------------------------------------------------------
// Geometria básica.

class _V {
  const _V(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _V operator +(_V o) => _V(x + o.x, y + o.y, z + o.z);
  _V operator -(_V o) => _V(x - o.x, y - o.y, z - o.z);
  _V operator *(double k) => _V(x * k, y * k, z * k);
}

/// As seis faces de uma caixa. `normal` aponta para fora.
enum _Face {
  front(_V(0, 0, 1)),
  back(_V(0, 0, -1)),
  right(_V(1, 0, 0)),
  left(_V(-1, 0, 0)),
  top(_V(0, 1, 0)),
  bottom(_V(0, -1, 0));

  const _Face(this.normal);

  final _V normal;
}

/// Desenho chapado em cima de uma face (olhos, boca, estampas...).
/// Os pontos vão de (0, 0) no canto de cima à esquerda a (1, 1), olhando a
/// face de fora.
class _Decal {
  const _Decal(this.points, this.color);

  final List<Offset> points;
  final Color color;
}

class _Box {
  _Box(
    double x0,
    double y0,
    double z0,
    double x1,
    double y1,
    double z1,
    this.color, {
    this.outlined = true,
    this.bias = 0,
  }) : min = _V(math.min(x0, x1), math.min(y0, y1), math.min(z0, z1)),
       max = _V(math.max(x0, x1), math.max(y0, y1), math.max(z0, z1));

  final _V min;
  final _V max;
  final Color color;
  final bool outlined;

  /// Empurra a caixa para trás (negativo) ou para a frente na ordem de
  /// pintura, para peças que encostam em outras.
  final double bias;

  final Map<_Face, List<_Decal>> decals = {};

  _V get center => (min + max) * 0.5;

  void decal(_Face face, List<Offset> points, Color color) =>
      (decals[face] ??= []).add(_Decal(points, color));

  /// Mesma figura nas quatro faces de lado (faixas, listras).
  void around(List<Offset> points, Color color) {
    for (final face in const [
      _Face.front,
      _Face.back,
      _Face.left,
      _Face.right,
    ]) {
      decal(face, points, color);
    }
  }

  /// Cantos da face: origem (em cima à esquerda), direita, baixo-direita,
  /// baixo-esquerda, olhando de fora.
  List<_V> corners(_Face face) {
    final a = min;
    final b = max;
    final (_V o, _V u, _V v) = switch (face) {
      _Face.front => (
        _V(a.x, b.y, b.z),
        _V(b.x - a.x, 0, 0),
        _V(0, a.y - b.y, 0),
      ),
      _Face.back => (
        _V(b.x, b.y, a.z),
        _V(a.x - b.x, 0, 0),
        _V(0, a.y - b.y, 0),
      ),
      _Face.right => (
        _V(b.x, b.y, b.z),
        _V(0, 0, a.z - b.z),
        _V(0, a.y - b.y, 0),
      ),
      _Face.left => (
        _V(a.x, b.y, a.z),
        _V(0, 0, b.z - a.z),
        _V(0, a.y - b.y, 0),
      ),
      _Face.top => (
        _V(a.x, b.y, a.z),
        _V(b.x - a.x, 0, 0),
        _V(0, 0, b.z - a.z),
      ),
      _Face.bottom => (
        _V(a.x, a.y, b.z),
        _V(b.x - a.x, 0, 0),
        _V(0, 0, a.z - b.z),
      ),
    };
    return [o, o + u, o + u + v, o + v];
  }
}

class _View {
  _View({
    required double yaw,
    required double pitch,
    required this.scale,
    required this.origin,
    required this.centerY,
  }) : _cy = math.cos(yaw),
       _sy = math.sin(yaw),
       _cp = math.cos(pitch),
       _sp = math.sin(pitch);

  final double scale;
  final Offset origin;
  final double centerY;
  final double _cy;
  final double _sy;
  final double _cp;
  final double _sp;

  _V rotate(_V p) {
    final x = p.x * _cy + p.z * _sy;
    final z = -p.x * _sy + p.z * _cy;
    return _V(x, p.y * _cp - z * _sp, p.y * _sp + z * _cp);
  }

  Offset project(_V p) {
    final r = rotate(_V(p.x, p.y - centerY, p.z));
    return origin + Offset(r.x * scale, -r.y * scale);
  }

  double depth(_Box box) => rotate(box.center).z + box.bias;

  Path polygon(List<_V> points) {
    final path = Path()..moveTo(project(points[0]).dx, project(points[0]).dy);
    for (var i = 1; i < points.length; i++) {
      final p = project(points[i]);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}

// ---------------------------------------------------------------------------
// Formas para as decalques.

List<Offset> _rect(double u0, double v0, double u1, double v1) => [
  Offset(u0, v0),
  Offset(u1, v0),
  Offset(u1, v1),
  Offset(u0, v1),
];

List<Offset> _ellipse(
  double cu,
  double cv,
  double ru,
  double rv, [
  int n = 14,
]) => [
  for (var i = 0; i < n; i++)
    Offset(
      cu + ru * math.cos(2 * math.pi * i / n),
      cv + rv * math.sin(2 * math.pi * i / n),
    ),
];

/// Faixa curva de [a0] a [a1] (radianos, 0 = direita, pi/2 = embaixo).
List<Offset> _arc(
  double cu,
  double cv,
  double ru,
  double rv,
  double thick,
  double a0,
  double a1, [
  int n = 9,
]) {
  final outer = [
    for (var i = 0; i <= n; i++)
      Offset(
        cu + ru * math.cos(a0 + (a1 - a0) * i / n),
        cv + rv * math.sin(a0 + (a1 - a0) * i / n),
      ),
  ];
  final inner = [
    for (var i = n; i >= 0; i--)
      Offset(
        cu + (ru - thick) * math.cos(a0 + (a1 - a0) * i / n),
        cv + (rv - thick) * math.sin(a0 + (a1 - a0) * i / n),
      ),
  ];
  return [...outer, ...inner];
}

List<Offset> _star(double cu, double cv, double r) => [
  for (var i = 0; i < 10; i++)
    Offset(
      cu + (i.isEven ? r : r * 0.45) * math.cos(-math.pi / 2 + math.pi * i / 5),
      cv + (i.isEven ? r : r * 0.45) * math.sin(-math.pi / 2 + math.pi * i / 5),
    ),
];

Color _darker(Color color, [double amount = 0.25]) =>
    Color.lerp(color, const Color(0xFF000000), amount)!;

Color _lighter(Color color, [double amount = 0.3]) =>
    Color.lerp(color, const Color(0xFFFFFFFF), amount)!;

// ---------------------------------------------------------------------------
// O boneco. Unidades: pés em y = 0, frente do avatar para +z.

/// Monta as caixas do avatar com o visual escolhido.
List<_Box> _buildAvatarBoxes(AvatarLook look) {
  final skin = look[AvatarCategory.pele]!.color;
  final hairPart = look[AvatarCategory.cabelo]!;
  final hair = look[AvatarCategory.corCabelo]!.color;
  final shirt = look[AvatarCategory.camisa]!;
  final pants = look[AvatarCategory.calca]!;
  final shoes = look[AvatarCategory.tenis]!;
  final hat = look[AvatarCategory.chapeu];
  final glasses = look[AvatarCategory.oculos];
  final back = look[AvatarCategory.costas];

  final boxes = <_Box>[];

  // Pés.
  final boot = shoes.style == 'bota';
  final shoeTop = boot ? 0.42 : 0.2;
  for (final side in const [-1.0, 1.0]) {
    final cx = 0.24 * side;
    final shoe = _Box(
      cx - 0.23,
      0,
      -0.22,
      cx + 0.23,
      shoeTop,
      0.3,
      shoes.color,
    );
    shoe.around(_rect(0, boot ? 0.78 : 0.62, 1, 1), shoes.detail);
    if (boot) shoe.around(_rect(0, 0, 1, 0.16), _lighter(shoes.color, 0.2));
    if (!boot) {
      shoe.decal(_Face.top, _rect(0.3, 0.72, 0.7, 0.8), shoes.detail);
    }
    boxes.add(shoe);
  }

  // Pernas.
  for (final side in const [-1.0, 1.0]) {
    final cx = 0.24 * side;
    switch (pants.style) {
      case 'shorts':
        boxes
          ..add(_Box(cx - 0.19, shoeTop, -0.18, cx + 0.19, 0.6, 0.18, skin))
          ..add(
            _Box(cx - 0.22, 0.6, -0.21, cx + 0.22, 0.95, 0.21, pants.color),
          );
      case 'saia':
        boxes.add(_Box(cx - 0.19, shoeTop, -0.18, cx + 0.19, 0.6, 0.18, skin));
      default:
        final leg = _Box(
          cx - 0.21,
          shoeTop,
          -0.2,
          cx + 0.21,
          0.95,
          0.2,
          pants.color,
        );
        if (pants.style == 'esportiva') {
          leg.decal(
            side > 0 ? _Face.right : _Face.left,
            _rect(0.4, 0, 0.6, 1),
            pants.detail,
          );
          leg.decal(
            _Face.front,
            _rect(0.15, 0.42, 0.85, 0.56),
            _lighter(pants.color, 0.25),
          );
        } else {
          leg.decal(
            _Face.front,
            _rect(0.15, 0.04, 0.32, 0.18),
            _darker(pants.color, 0.15),
          );
        }
        boxes.add(leg);
    }
  }
  if (pants.style == 'saia') {
    final skirt = _Box(
      -0.56,
      0.6,
      -0.29,
      0.56,
      0.95,
      0.29,
      pants.color,
      bias: 0.6,
    );
    skirt.around(_rect(0, 0.8, 1, 1), _lighter(pants.color, 0.35));
    boxes.add(skirt);
  }

  // Tronco.
  final longSleeves = const {
    'moletom',
    'jaqueta',
    'heroi',
    'armadura',
  }.contains(shirt.style);
  final torso = _Box(-0.5, 0.95, -0.25, 0.5, 1.9, 0.25, shirt.color);
  // Gola mostrando o pescoço.
  torso.decal(_Face.front, const [
    Offset(0.34, 0),
    Offset(0.66, 0),
    Offset(0.57, 0.11),
    Offset(0.43, 0.11),
  ], skin);
  torso.decal(_Face.top, _rect(0.3, 0.3, 0.7, 0.7), skin);
  switch (shirt.style) {
    case 'liga':
      torso.decal(_Face.front, _star(0.5, 0.45, 0.2), shirt.detail);
    case 'listrada':
      for (var v = 0.18; v < 1; v += 0.24) {
        torso.around(_rect(0, v, 1, v + 0.1), shirt.detail);
      }
    case 'moletom':
      torso.decal(
        _Face.front,
        _rect(0.25, 0.62, 0.75, 0.88),
        _darker(shirt.color, 0.12),
      );
      torso.decal(_Face.front, _rect(0.4, 0.1, 0.43, 0.36), shirt.detail);
      torso.decal(_Face.front, _rect(0.57, 0.1, 0.6, 0.36), shirt.detail);
      torso.around(_rect(0, 0.92, 1, 1), _darker(shirt.color, 0.15));
    case 'jaqueta':
      torso.decal(_Face.front, _rect(0.42, 0.08, 0.58, 1), shirt.detail);
      torso.decal(
        _Face.front,
        _rect(0.1, 0.6, 0.32, 0.78),
        _darker(shirt.color, 0.18),
      );
      torso.decal(
        _Face.front,
        _rect(0.68, 0.6, 0.9, 0.78),
        _darker(shirt.color, 0.18),
      );
    case 'heroi':
      torso.decal(_Face.front, const [
        Offset(0.5, 0.18),
        Offset(0.76, 0.42),
        Offset(0.5, 0.66),
        Offset(0.24, 0.42),
      ], shirt.detail);
      torso.decal(_Face.front, _star(0.5, 0.42, 0.11), shirt.color);
      torso.around(_rect(0, 0.86, 1, 0.96), shirt.detail);
    case 'galaxia':
      const stars = [
        (0.2, 0.3, 0.06),
        (0.7, 0.22, 0.05),
        (0.48, 0.55, 0.09),
        (0.82, 0.7, 0.05),
        (0.25, 0.78, 0.04),
      ];
      for (final (u, v, r) in stars) {
        torso.decal(_Face.front, _star(u, v, r), shirt.detail);
        torso.decal(_Face.back, _star(1 - u, v, r), shirt.detail);
      }
    case 'armadura':
      torso.decal(
        _Face.front,
        _rect(0.18, 0.16, 0.82, 0.62),
        _lighter(shirt.color, 0.25),
      );
      torso.decal(_Face.front, _ellipse(0.5, 0.39, 0.1, 0.1), shirt.detail);
      torso.around(_rect(0, 0.84, 1, 0.94), shirt.detail);
    default:
      torso.around(_rect(0, 0.92, 1, 1), _darker(shirt.color, 0.12));
  }
  boxes.add(torso);

  // Braços.
  for (final side in const [-1.0, 1.0]) {
    final x0 = side > 0 ? 0.5 : -0.88;
    final x1 = side > 0 ? 0.88 : -0.5;
    if (longSleeves) {
      final sleeve = _Box(x0, 1.12, -0.19, x1, 1.9, 0.19, shirt.color);
      sleeve.around(_rect(0, 0.88, 1, 1), _darker(shirt.color, 0.18));
      if (shirt.style == 'heroi' || shirt.style == 'armadura') {
        sleeve.around(_rect(0, 0.72, 1, 0.84), shirt.detail);
      }
      boxes
        ..add(sleeve)
        ..add(_Box(x0 + 0.02, 0.98, -0.17, x1 - 0.02, 1.12, 0.17, skin));
    } else {
      final sleeve = _Box(x0, 1.52, -0.19, x1, 1.9, 0.19, shirt.color);
      if (shirt.style == 'listrada') {
        sleeve.around(_rect(0, 0.45, 1, 0.7), shirt.detail);
      }
      boxes
        ..add(sleeve)
        ..add(_Box(x0 + 0.02, 0.98, -0.17, x1 - 0.02, 1.52, 0.17, skin));
    }
    if (shirt.style == 'armadura') {
      boxes.add(
        _Box(
          side > 0 ? 0.48 : -0.94,
          1.9,
          -0.23,
          side > 0 ? 0.94 : -0.48,
          2.02,
          0.23,
          shirt.detail,
        ),
      );
    }
  }

  // Cabeça e rosto.
  final head = _Box(-0.44, 1.92, -0.4, 0.44, 2.74, 0.4, skin);
  _face(head, look, hair, skin);
  if (glasses != null) _glasses(head, glasses);
  boxes.add(head);

  // Cabelo (o chapéu esconde a parte de cima).
  final coversTop =
      hat != null && const {'bone', 'gorro', 'explorador'}.contains(hat.style);
  boxes.addAll(_hair(hairPart.style, hair, coversTop: coversTop));

  // Coroa, orelhas e fone ficam em cima do cabelo volumoso.
  final lift = switch (hairPart.style) {
    'black' => 0.31,
    'cacheado' => 0.14,
    'espetado' || 'coque' => 0.08,
    _ => 0.0,
  };
  if (hat != null) boxes.addAll(_hat(hat, lift));
  if (back != null) boxes.addAll(_back(back, torso));

  return boxes;
}

void _face(_Box head, AvatarLook look, Color hair, Color skin) {
  final eyes = look[AvatarCategory.olhos]!.style;
  final iris = look[AvatarCategory.corOlhos]!.color;
  const ink = Color(0xFF1B1530);
  final brow = look[AvatarCategory.cabelo]!.style == 'careca'
      ? _darker(skin, 0.45)
      : _darker(hair, 0.1);

  for (final side in const [-1.0, 1.0]) {
    final cu = 0.5 + 0.2 * side;
    const cv = 0.53;
    // Sobrancelhas.
    if (eyes == 'determinados') {
      head.decal(_Face.front, [
        Offset(cu - 0.1, side < 0 ? 0.33 : 0.37),
        Offset(cu + 0.1, side < 0 ? 0.37 : 0.33),
        Offset(cu + 0.1, side < 0 ? 0.42 : 0.38),
        Offset(cu - 0.1, side < 0 ? 0.38 : 0.42),
      ], brow);
    } else {
      head.decal(_Face.front, _rect(cu - 0.09, 0.35, cu + 0.09, 0.39), brow);
    }
    switch (eyes) {
      case 'felizes':
        head.decal(
          _Face.front,
          _arc(cu, cv + 0.05, 0.08, 0.08, 0.035, math.pi, 2 * math.pi),
          ink,
        );
      case 'grandes':
        head.decal(_Face.front, _ellipse(cu, cv, 0.095, 0.11), Colors.white);
        head.decal(_Face.front, _ellipse(cu, cv + 0.01, 0.065, 0.085), iris);
        head.decal(_Face.front, _ellipse(cu, cv + 0.015, 0.035, 0.045), ink);
        head.decal(
          _Face.front,
          _ellipse(cu + 0.03, cv - 0.035, 0.022, 0.022, 8),
          Colors.white,
        );
      default:
        head.decal(_Face.front, _ellipse(cu, cv, 0.06, 0.08), iris);
        head.decal(_Face.front, _ellipse(cu, cv + 0.01, 0.032, 0.045), ink);
        head.decal(
          _Face.front,
          _ellipse(cu + 0.022, cv - 0.03, 0.018, 0.018, 8),
          Colors.white,
        );
    }
    // Bochechas.
    head.decal(
      _Face.front,
      _ellipse(0.5 + 0.3 * side, 0.7, 0.06, 0.035),
      const Color(0xFFFF8FA3).withValues(alpha: 0.45),
    );
  }

  switch (look[AvatarCategory.boca]!.style) {
    case 'sorrisao':
      final mouth = [
        for (var i = 0; i <= 10; i++)
          Offset(
            0.5 + 0.13 * math.cos(math.pi * i / 10),
            0.72 + 0.11 * math.sin(math.pi * i / 10),
          ),
      ];
      head.decal(_Face.front, mouth, ink);
      head.decal(_Face.front, _rect(0.41, 0.72, 0.59, 0.75), Colors.white);
      head.decal(
        _Face.front,
        _ellipse(0.5, 0.8, 0.06, 0.025),
        const Color(0xFFFF6F8E),
      );
    case 'tranquila':
      head.decal(_Face.front, _rect(0.42, 0.76, 0.58, 0.79), ink);
    case 'surpresa':
      head.decal(_Face.front, _ellipse(0.5, 0.78, 0.045, 0.055), ink);
    default:
      head.decal(
        _Face.front,
        _arc(0.5, 0.7, 0.12, 0.1, 0.035, 0.15 * math.pi, 0.85 * math.pi),
        ink,
      );
  }
}

void _glasses(_Box head, AvatarPart glasses) {
  final frame = glasses.color;
  switch (glasses.style) {
    case 'visor':
      head.decal(_Face.front, _rect(0.1, 0.42, 0.9, 0.64), glasses.detail);
      head.decal(
        _Face.front,
        _rect(0.14, 0.45, 0.86, 0.52),
        glasses.color.withValues(alpha: 0.8),
      );
      for (final face in const [_Face.left, _Face.right]) {
        head.decal(face, _rect(0.35, 0.47, 1, 0.58), glasses.detail);
      }
      return;
    case 'redondos':
      for (final side in const [-1.0, 1.0]) {
        head.decal(
          _Face.front,
          _arc(0.5 + 0.2 * side, 0.53, 0.12, 0.12, 0.03, 0, 2 * math.pi, 16),
          frame,
        );
      }
    case 'escuros':
      for (final side in const [-1.0, 1.0]) {
        head.decal(
          _Face.front,
          _rect(0.5 + 0.2 * side - 0.13, 0.44, 0.5 + 0.2 * side + 0.13, 0.62),
          frame,
        );
        head.decal(
          _Face.front,
          _rect(0.5 + 0.2 * side - 0.08, 0.47, 0.5 + 0.2 * side - 0.03, 0.5),
          Colors.white.withValues(alpha: 0.5),
        );
      }
    default:
      for (final side in const [-1.0, 1.0]) {
        final cu = 0.5 + 0.2 * side;
        head.decal(_Face.front, _rect(cu - 0.13, 0.43, cu + 0.13, 0.46), frame);
        head.decal(_Face.front, _rect(cu - 0.13, 0.61, cu + 0.13, 0.64), frame);
        head.decal(_Face.front, _rect(cu - 0.13, 0.43, cu - 0.1, 0.64), frame);
        head.decal(_Face.front, _rect(cu + 0.1, 0.43, cu + 0.13, 0.64), frame);
      }
  }
  head.decal(_Face.front, _rect(0.42, 0.5, 0.58, 0.53), frame);
  for (final face in const [_Face.left, _Face.right]) {
    head.decal(face, _rect(0.5, 0.5, 1, 0.54), frame);
  }
}

List<_Box> _hair(String style, Color color, {required bool coversTop}) {
  if (style == 'careca') return const [];
  final boxes = <_Box>[];
  final shine = _lighter(color, 0.18);

  _Box cap(double half, double y0, double y1, double z0, double z1) {
    final box = _Box(-half, y0, z0, half, y1, z1, color);
    box.decal(_Face.top, _rect(0.15, 0.2, 0.45, 0.3), shine);
    return box;
  }

  void sides(double low, double z1, [double out = 0.06]) {
    boxes
      ..add(_Box(0.44, low, -0.42, 0.44 + out, 2.66, z1, color))
      ..add(_Box(-0.44 - out, low, -0.42, -0.44, 2.66, z1, color));
  }

  final big = style == 'black' || style == 'cacheado';
  if (big) {
    final half = style == 'black' ? 0.68 : 0.56;
    final top = style == 'black' ? 3.15 : 2.98;
    if (!coversTop) boxes.add(cap(half, 2.6, top, -half - 0.02, 0.44));
    boxes.add(_Box(-half, 2.0, -half - 0.02, half, 2.6, -0.4, color));
    boxes
      ..add(_Box(0.44, 2.05, -0.4, half, 2.6, 0.22, color))
      ..add(_Box(-half, 2.05, -0.4, -0.44, 2.6, 0.22, color));
    return boxes;
  }

  if (!coversTop) boxes.add(cap(0.48, 2.62, 2.84, -0.46, 0.44));
  final long = style == 'longo';
  boxes.add(
    _Box(
      -0.48,
      long ? 1.62 : 2.18,
      -0.47,
      0.48,
      2.62,
      -0.4,
      color,
      bias: -0.05,
    ),
  );
  sides(long ? 1.92 : 2.34, long ? 0.26 : 0.08);

  switch (style) {
    case 'franja':
      final fringe = _Box(-0.44, 2.44, 0.4, 0.44, 2.62, 0.46, color);
      boxes.add(fringe);
    case 'espetado':
      if (!coversTop) {
        const spikes = [
          (-0.3, 0.2, 0.16),
          (0.0, 0.25, 0.2),
          (0.3, 0.18, 0.14),
          (-0.15, -0.15, 0.18),
          (0.18, -0.2, 0.16),
        ];
        for (final (x, z, h) in spikes) {
          boxes.add(
            _Box(x - 0.1, 2.84, z - 0.1, x + 0.1, 2.84 + h, z + 0.1, color),
          );
        }
      }
      boxes.add(_Box(-0.44, 2.5, 0.4, 0.1, 2.62, 0.46, color));
    case 'rabo':
      boxes
        ..add(
          _Box(-0.1, 2.38, -0.56, 0.1, 2.56, -0.47, const Color(0xFFFF6FB5)),
        )
        ..add(_Box(-0.12, 1.86, -0.66, 0.12, 2.48, -0.5, color, bias: -0.1));
    case 'coque':
      if (!coversTop) {
        boxes.add(_Box(-0.2, 2.84, -0.26, 0.2, 3.1, 0.1, color));
      }
    case 'trancas':
      for (final side in const [-1.0, 1.0]) {
        final x0 = side > 0 ? 0.5 : -0.62;
        final braid = _Box(x0, 1.96, -0.06, x0 + 0.12, 2.5, 0.08, color);
        braid.around(_rect(0, 0.3, 1, 0.36), _darker(color, 0.3));
        braid.around(_rect(0, 0.62, 1, 0.68), _darker(color, 0.3));
        boxes
          ..add(braid)
          ..add(
            _Box(
              x0 - 0.01,
              1.92,
              -0.07,
              x0 + 0.13,
              1.98,
              0.09,
              const Color(0xFFFFC233),
            ),
          );
      }
    case 'chiquinha':
      for (final side in const [-1.0, 1.0]) {
        final x0 = side > 0 ? 0.5 : -0.74;
        boxes
          ..add(
            _Box(
              side > 0 ? 0.5 : -0.56,
              2.38,
              -0.12,
              side > 0 ? 0.56 : -0.5,
              2.52,
              0.04,
              const Color(0xFFFF6FB5),
            ),
          )
          ..add(_Box(x0, 2.12, -0.14, x0 + 0.24, 2.52, 0.06, color));
      }
    default:
      boxes.add(_Box(-0.44, 2.56, 0.4, 0.44, 2.62, 0.45, color));
  }
  return boxes;
}

List<_Box> _hat(AvatarPart hat, double lift) {
  final c = hat.color;
  final d = hat.detail;
  switch (hat.style) {
    case 'bone':
      final crown = _Box(-0.5, 2.62, -0.47, 0.5, 2.96, 0.43, c);
      crown.decal(_Face.front, _ellipse(0.5, 0.45, 0.12, 0.2), d);
      crown.decal(_Face.top, _ellipse(0.5, 0.5, 0.06, 0.06, 8), d);
      return [
        crown,
        _Box(-0.38, 2.62, 0.43, 0.38, 2.68, 0.76, _darker(c, 0.1)),
      ];
    case 'gorro':
      final beanie = _Box(-0.5, 2.55, -0.47, 0.5, 3.0, 0.45, c);
      beanie.around(_rect(0, 0.72, 1, 1), d);
      beanie.around(_rect(0, 0.3, 1, 0.42), d);
      return [beanie, _Box(-0.1, 3.0, -0.11, 0.1, 3.18, 0.09, d)];
    case 'explorador':
      final crown = _Box(-0.46, 2.76, -0.44, 0.46, 3.06, 0.44, c);
      crown.around(_rect(0, 0.62, 1, 0.9), d);
      return [
        _Box(-0.76, 2.7, -0.74, 0.76, 2.76, 0.74, _darker(c, 0.08)),
        crown,
      ];
    case 'coroa':
      final base = _Box(-0.36, 2.84 + lift, -0.3, 0.36, 2.98 + lift, 0.3, c);
      base.decal(_Face.front, _ellipse(0.5, 0.5, 0.08, 0.3, 8), d);
      return [
        base,
        for (final (x, z) in const [
          (-0.28, 0.22),
          (0.28, 0.22),
          (-0.28, -0.22),
          (0.28, -0.22),
          (0.0, 0.22),
        ])
          _Box(
            x - 0.07,
            2.98 + lift,
            z - 0.07,
            x + 0.07,
            3.14 + lift,
            z + 0.07,
            c,
          ),
      ];
    case 'orelhas':
      return [
        for (final side in const [-1.0, 1.0])
          _Box(side * 0.18, 2.74 + lift, -0.06, side * 0.4, 3.0 + lift, 0.06, c)
            ..decal(_Face.front, const [
              Offset(0.5, 0.2),
              Offset(0.8, 0.95),
              Offset(0.2, 0.95),
            ], d),
      ];
    case 'fone':
      return [
        _Box(-0.5, 2.74 + lift, -0.07, 0.5, 2.82 + lift, 0.07, c, bias: 0.2),
        for (final side in const [-1.0, 1.0])
          _Box(
            side > 0 ? 0.44 : -0.58,
            2.15,
            -0.15,
            side > 0 ? 0.58 : -0.44,
            2.5,
            0.15,
            c,
          )..decal(
            side > 0 ? _Face.right : _Face.left,
            _ellipse(0.5, 0.5, 0.3, 0.3, 10),
            d,
          ),
      ];
  }
  return const [];
}

List<_Box> _back(AvatarPart part, _Box torso) {
  final c = part.color;
  final d = part.detail;
  switch (part.style) {
    case 'mochila':
      torso.decal(_Face.front, _rect(0.14, 0, 0.24, 0.62), d);
      torso.decal(_Face.front, _rect(0.76, 0, 0.86, 0.62), d);
      final bag = _Box(-0.36, 1.18, -0.5, 0.36, 1.82, -0.25, c);
      bag.decal(_Face.back, _rect(0.15, 0.5, 0.85, 0.85), _darker(c, 0.15));
      bag.decal(_Face.back, _rect(0.15, 0.48, 0.85, 0.53), d);
      return [bag];
    case 'capa':
      final cape = _Box(-0.48, 0.5, -0.34, 0.48, 1.88, -0.27, c, bias: -0.05);
      cape.decal(_Face.back, _star(0.5, 0.3, 0.16), d);
      return [cape];
    case 'jetpack':
      return [
        for (final x in const [-0.18, 0.18]) ...[
          _Box(x - 0.15, 1.15, -0.56, x + 0.15, 1.86, -0.26, c)
            ..around(_rect(0, 0.1, 1, 0.18), d),
          _Box(
            x - 0.08,
            0.92,
            -0.49,
            x + 0.08,
            1.15,
            -0.33,
            const Color(0xFFFFC233),
            outlined: false,
          ),
        ],
      ];
    case 'asas':
      return [
        for (final side in const [-1.0, 1.0]) ...[
          _Box(side * 0.1, 1.62, -0.37, side * 1.25, 2.3, -0.31, c, bias: -0.3)
            ..around(_rect(0, 0.55, 1, 0.68), d),
          _Box(side * 0.1, 1.1, -0.37, side * 0.88, 1.62, -0.31, d, bias: -0.3)
            ..around(_rect(0, 0.45, 1, 0.58), c),
        ],
      ];
  }
  return const [];
}

/// Avatar com pedestal e brilho, para a Base e o Perfil.
class LigaAvatarStage extends StatelessWidget {
  const LigaAvatarStage({
    super.key,
    required this.look,
    this.size = 220,
    this.interactive = false,
    this.sway = true,
    this.glow = LigaColors.cyanGlow,
  });

  final AvatarLook look;
  final double size;
  final bool interactive;
  final bool sway;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: size * 0.02,
          child: Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glow.withValues(alpha: 0.45),
                  glow.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        LigaAvatar3D(
          look: look,
          size: size,
          interactive: interactive,
          sway: sway && !interactive,
        ),
      ],
    );
  }
}
