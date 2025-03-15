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
      _sideScroll.jumpTo(_editorScroll.offset);
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
          _buildSide(),
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

  Widget _buildSide() => ScrollConfiguration(
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

          return _portal(option: option);

          return PopupMenuButton(
            tooltip: '',
            itemBuilder: (BuildContext context) {
              return option.checkBoxes.map((e) {
                return PopupMenuItem<void>(child: Text(e.label), onTap: () {});
              }).toList();
            },
            borderRadius: BorderRadius.circular(2),
            child: const Icon(Icons.more_horiz, color: Colors.grey),
          );
        },
      ),
    ),
  );

  Widget _portal({required Option option}) {
    final portalController = OverlayPortalController();
    final layerLink = LayerLink();
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
              onTapOutside: (event) => portalController.hide(),
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  // width: 350,
                  child: Material(
                    surfaceTintColor: context.theme.colorScheme.surfaceTint,
                    elevation: 2,
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in option.checkBoxes)
                            CheckboxListTile(
                              value: e.value,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => e.onChange(v!),
                              title: Text(e.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: InkWell(
          onTap: portalController.toggle,
          child: const Icon(Icons.more_horiz, color: Colors.grey),
        ),
      ),
    );
  }
}
