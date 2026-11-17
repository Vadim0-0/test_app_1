import 'package:flutter/material.dart';

// ── Настройки анимации и вида меню ─────────────────────────────
// Меняйте значения здесь — они применяются ко всему виджету.

// Длительность открытия/закрытия.
const _kDuration = Duration(milliseconds: 250);
// Кривая открытия. Попробуйте Curves.easeOutBack — лёгкая "пружинка".
const _kOpenCurve = Curves.easeOutBack;
// Кривая закрытия.
const _kCloseCurve = Curves.easeOutBack;
// На сколько оборотов поворачивается стрелка (0.5 = 180°).
const _kArrowTurns = 0.5;
// Зазор между кнопкой и меню, в пикселях.
const _kMenuGap = 6.0;
// Высота тени меню.
const _kMenuElevation = 4.0;
// Скругление углов меню.
const _kMenuRadius = 12.0;
// Максимальная высота меню; если пунктов больше — появится прокрутка.
const _kMenuMaxHeight = 300.0;
// ───────────────────────────────────────────────────────────────

class AnimatedDropdown<T> extends StatefulWidget {
  const AnimatedDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.label = '',
  });

  final T value; // что выбрано сейчас
  final List<T> items; // все варианты
  final String Function(T) labelOf; // как превратить вариант в текст
  final ValueChanged<T> onChanged; // что делать при выборе
  final String label; // подпись над полем

  @override
  State<AnimatedDropdown<T>> createState() => _AnimatedDropdownState<T>();
}

// SingleTickerProviderStateMixin даёт "тикер" — сигнал каждого кадра для анимации.
class _AnimatedDropdownState<T> extends State<AnimatedDropdown<T>>
    with SingleTickerProviderStateMixin {
  // Управляет показом меню в слое Overlay (поверх всего экрана).
  final _portal = OverlayPortalController();
  // Связывает меню с кнопкой, чтобы меню знало, где она находится.
  final _link = LayerLink();

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: _kDuration,
  );
  // Кривая делает движение мягким: быстро в начале, плавно в конце.
  late final Animation<double> _curve = CurvedAnimation(
    parent: _anim,
    curve: _kOpenCurve,
    reverseCurve: _kCloseCurve,
  );

  double _width = 0;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get _isOpen =>
      _anim.status == AnimationStatus.forward ||
      _anim.status == AnimationStatus.completed;

  void _open() {
    _portal.show(); // сначала показываем меню...
    _anim.forward(); // ...и запускаем анимацию 0 → 1
  }

  Future<void> _close() async {
    await _anim.reverse(); // анимация 1 → 0
    // Убираем меню только когда анимация закончилась.
    if (mounted && _anim.isDismissed) _portal.hide();
  }

  void _toggle() => _isOpen ? _close() : _open();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth; // меню будет той же ширины, что и кнопка

        return CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: (_) => _buildMenu(colors),
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.label,
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.labelOf(widget.value))),
                    // Стрелка поворачивается на пол-оборота вместе с анимацией.
                    RotationTransition(
                      turns: Tween(
                        begin: 0.0,
                        end: _kArrowTurns,
                      ).animate(_curve),
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenu(ColorScheme colors) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Невидимый слой на весь экран: нажатие мимо меню закрывает его.
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close),
        Align(
          alignment: Alignment.topLeft,
          // Следует за кнопкой: левый верх меню = левый низ кнопки + зазор.
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, _kMenuGap),
            child: SizedBox(
              width: _width,
              child: FadeTransition(
                opacity: _curve,

                child: Material(
                  elevation: _kMenuElevation,
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(_kMenuRadius),
                  clipBehavior: Clip.antiAlias,

                  // Раскрывается по высоте сверху вниз (topCenter = от верха).
                  child: SizeTransition(
                    sizeFactor: _curve,
                    alignment: Alignment.topCenter,
                    child: Material(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _kMenuMaxHeight,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final item in widget.items)
                                ListTile(
                                  title: Text(widget.labelOf(item)),
                                  selected: item == widget.value,
                                  trailing: item == widget.value
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    widget.onChanged(item);
                                    _close();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
