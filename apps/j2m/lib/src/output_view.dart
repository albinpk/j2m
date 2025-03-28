import 'package:flutter/material.dart';

import 'converter/base.dart';
import 'extensions/context_extensions.dart';

class OutputView extends StatefulWidget {
  const OutputView({required this.converter, this.wrapText = false, super.key});

  /// The language converter.
  final ConverterBase converter;

  /// If true, the text will be wrapped to fit the available width.
  final bool wrapText;

  @override
  State<OutputView> createState() => _OutputViewState();
}

class _OutputViewState extends State<OutputView> {
  final _editorScroll = ScrollController();
  final _sideScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _editorScroll.addListener(() {
      if (_sideScroll.hasClients) _sideScroll.jumpTo(_editorScroll.offset);
    });
  }

  @override
  void dispose() {
    _editorScroll.dispose();
    _sideScroll.dispose();
    super.dispose();
  }

  static const _padding = 8.0;
  static const _fontSize = 16.0;
  static const _height = 1.5;
  static const _lineHeight = _fontSize * _height;

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: widget.converter.controller,
      readOnly: true,
      scrollController: _editorScroll,
      scrollPhysics: const ClampingScrollPhysics(),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(_padding),
      ),
      maxLines: null,
      expands: true,
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: _fontSize,
        height: _height,
        //
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.converter.lineOptions.isNotEmpty && !widget.wrapText)
            _buildSideOption(),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (widget.wrapText) return textField;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: IntrinsicWidth(child: textField),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideOption() => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
    child: SizedBox(
      width: 25,
      child: ListView.builder(
        controller: _sideScroll,
        itemExtent: _lineHeight,
        padding: const EdgeInsets.symmetric(vertical: _padding),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.converter.lines,
        itemBuilder: (context, index) {
          final option = widget.converter.lineOptions[index];
          if (option == null) return const SizedBox.shrink();
          return _MenuButton(
            option: option,
            onChange: () {
              widget.converter.convert();
              setState(() {});
            },
          );
        },
      ),
    ),
  );
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.option, required this.onChange});

  final Option option;
  final VoidCallback onChange;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  Option get option => widget.option;

  final portalController = OverlayPortalController();
  final layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return CompositedTransformTarget(
      link: layerLink,
      child: OverlayPortal(
        controller: portalController,
        overlayChildBuilder: (context) {
          return CompositedTransformFollower(
            link: layerLink,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topRight,
            showWhenUnlinked: false,
            child: TapRegion(
              onTapOutside: (_) => portalController.hide(),
              child: Align(
                alignment: Alignment.topRight,
                child: Material(
                  surfaceTintColor: context.theme.colorScheme.surfaceTint,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(4),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Line options',
                                style: context.tt.labelMedium?.copyWith(
                                  color: context.cs.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: context.cs.error,
                              ),
                              onPressed:
                                  option.reset == null
                                      ? null
                                      : () {
                                        option.reset!();
                                        widget.onChange();
                                      },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        for (final e in option.checkBoxes)
                          CheckboxListTile(
                            value: e.value,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) {
                              e.onChange(v!);
                              widget.onChange();
                            },
                            title: Text(e.label),
                          ),
                        if (option.checkBoxes.isNotEmpty)
                          const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: InkWell(
          onTap: portalController.toggle,
          child: ColoredBox(
            color:
                option.reset == null
                    ? Colors.transparent
                    : cs.primary.withValues(alpha: 0.3),
            child: Icon(
              Icons.more_horiz,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
