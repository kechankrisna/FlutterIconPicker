/// FlutterIconPicker
/// Author Rebar Ahmad
/// https://github.com/Ahmadre
/// rebar.ahmad@gmail.com

library flutter_iconpicker;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

part 'src/icon_data/material_icons.dart';
part 'src/icon_data/cupertino_icons.dart';
part 'src/icon_data/font_awesome_icons.dart';
part 'src/icon_data/line_awesome_icons.dart';

/// The IconPack defines which Icons are gonna be loaded
enum IconPack {
  /// The official Material Icons by Flutter
  material,

  /// The official Cupertino Icons (Apple Design)
  cupertino,

  /// The official font_awesome_flutter Icons by the Flutter Community (Brian Egan)
  fontAwesomeIcons,

  /// The official line_awesome_icons Icons by Phuc Chau
  lineAwesomeIcons,

  /// Use this to show your own custom provided IconPack
  custom
}

Map<String, dynamic>? serializeIcon(IconData icon, {IconPack? iconPack}) {
  if (iconPack == null) {
    if (icon.fontFamily == "MaterialIcons")
      iconPack = IconPack.material;
    else if (icon.fontFamily == "CupertinoIcons")
      iconPack = IconPack.cupertino;
    else if (icon.fontPackage == "font_awesome_flutter")
      iconPack = IconPack.fontAwesomeIcons;
    else if (icon.fontPackage == "line_awesome_flutter")
      iconPack = IconPack.lineAwesomeIcons;
    else
      iconPack = IconPack.custom;
  }
  switch (iconPack) {
    case IconPack.material:
      return {
        'pack': "material",
        'key': _getIconKey(_materialIcons, icon),
      };
    case IconPack.cupertino:
      return {
        'pack': "cupertino",
        'key': _getIconKey(_cupertinoIcons, icon),
      };
    case IconPack.fontAwesomeIcons:
      return {
        'pack': "fontAwesomeIcons",
        'key': _getIconKey(_fontAwesomeIcons, icon),
      };
    case IconPack.lineAwesomeIcons:
      return {
        'pack': "lineAwesomeIcons",
        'key': _getIconKey(_lineAwesomeIcons, icon),
      };
    case IconPack.custom:
      return {
        'pack': "custom",
        'iconData': {
          'codePoint': icon.codePoint,
          'fontFamily': icon.fontFamily,
          'fontPackage': icon.fontPackage,
          'matchTextDirection': icon.matchTextDirection,
        }
      };
    default:
      return null;
  }
}

IconData? deserializeIcon(Map<String, dynamic> iconMap) {
  try {
    final pack = iconMap['pack'];
    final iconKey = iconMap['key'];
    switch (pack) {
      case "material":
        return _materialIcons[iconKey];
      case "cupertino":
        return _cupertinoIcons[iconKey];
      case "fontAwesomeIcons":
        return _fontAwesomeIcons[iconKey];
      case "lineAwesomeIcons":
        return _lineAwesomeIcons[iconKey];
      case "custom":
        final iconData = iconMap['iconData'];
        return IconData(
          iconData['codePoint'],
          fontFamily: iconData['fontFamily'],
          fontPackage: iconData['fontPackage'],
          matchTextDirection: iconData['matchTextDirection'],
        );
      default:
        return null;
    }
  } catch (e) {
    return null;
  }
}

String _getIconKey(Map<String, IconData> icons, IconData icon) =>
    icons.entries.firstWhere((iconEntry) => iconEntry.value == icon).key;

class _IconManager {
  static Map<String, IconData> getSelectedPack(IconPack? pickedPack) {
    switch (pickedPack) {
      case IconPack.material:
        return _materialIcons;
      case IconPack.cupertino:
        return _cupertinoIcons;
      case IconPack.fontAwesomeIcons:
        return _fontAwesomeIcons;
      case IconPack.lineAwesomeIcons:
        return _lineAwesomeIcons;
      default:
        return <String, IconData>{};
    }
  }
}

class _ColorBrightness {
  late Color _color;

  _ColorBrightness(Color color) {
    _color = Color.fromARGB(color.alpha, color.red, color.green, color.blue);
  }

  bool isDark() {
    return getBrightness() < 128.0;
  }

  bool isLight() {
    return !isDark();
  }

  double getBrightness() {
    return (_color.red * 299 + _color.green * 587 + _color.blue * 114) / 1000;
  }
}

class _IconController with ChangeNotifier {
  _IconController();

  Map<String, IconData> _icons = {};

  Map<String, IconData> get icons => _icons;

  set icons(Map<String, IconData> val) {
    _icons = val;
    notifyListeners();
  }

  final TextEditingController searchTextController = TextEditingController();

  int get length => _icons.length;

  Iterable<MapEntry<String, IconData>> get entries => _icons.entries;

  void addAll(Map<String, IconData> pack) {
    _icons.addAll(pack);
    notifyListeners();
  }

  void removeAll() {
    _icons.clear();
    notifyListeners();
  }
}

class _IconPicker extends StatefulWidget {
  final _IconController iconController;
  final List<IconPack>? iconPack;
  final Map<String, IconData>? customIconPack;
  final double? iconSize;
  final Color? iconColor;
  final String? noResultsText;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final Color? backgroundColor;
  final bool? showTooltips;

  const _IconPicker({
    required this.iconController,
    required this.iconPack,
    required this.iconSize,
    required this.noResultsText,
    required this.backgroundColor,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.iconColor,
    this.showTooltips,
    this.customIconPack,
  });

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.customIconPack != null) {
        if (mounted) widget.iconController.addAll(widget.customIconPack ?? {});
      }

      if (widget.iconPack != null)
        for (var pack in widget.iconPack!) {
          if (mounted)
            widget.iconController.addAll(_IconManager.getSelectedPack(pack));
        }
    });
  }

  Widget _getListEmptyMsg() => Container(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child: RichText(
            text: TextSpan(
              text: widget.noResultsText! + ' ',
              style: TextStyle(
                color: _ColorBrightness(widget.backgroundColor!).isLight()
                    ? Colors.black
                    : Colors.white,
              ),
              children: [
                TextSpan(
                  text: widget.iconController.searchTextController.text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _ColorBrightness(widget.backgroundColor!).isLight()
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<_IconController>(
      builder: (ctx, controller, _) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Stack(
          children: <Widget>[
            if (controller.icons.length == 0)
              _getListEmptyMsg()
            else
              Positioned.fill(
                child: GridView.builder(
                    itemCount: controller.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      childAspectRatio: 1 / 1,
                      mainAxisSpacing: widget.mainAxisSpacing ?? 5,
                      crossAxisSpacing: widget.crossAxisSpacing ?? 5,
                      maxCrossAxisExtent:
                          widget.iconSize != null ? widget.iconSize! + 10 : 50,
                    ),
                    itemBuilder: (context, index) {
                      var item = controller.entries.elementAt(index);

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, item.value),
                        child: widget.showTooltips!
                            ? Tooltip(
                                message: item.key,
                                child: Icon(
                                  item.value,
                                  size: widget.iconSize,
                                  color: widget.iconColor,
                                ),
                              )
                            : Icon(
                                item.value,
                                size: widget.iconSize,
                                color: widget.iconColor,
                              ),
                      );
                    }),
              ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.lerp(
                          Alignment.topCenter, Alignment.center, .05)!,
                      colors: [
                        widget.backgroundColor!,
                        widget.backgroundColor!.withOpacity(.1),
                      ],
                      stops: [
                        0.0,
                        1.0
                      ]),
                ),
                child: Container(),
              ),
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.lerp(
                          Alignment.bottomCenter, Alignment.center, .05)!,
                      colors: [
                        widget.backgroundColor!,
                        widget.backgroundColor!.withOpacity(.1),
                      ],
                      stops: [
                        0.0,
                        1.0
                      ]),
                ),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSearchBar extends StatefulWidget {
  const _IconSearchBar({
    required this.iconController,
    required this.iconPack,
    required this.searchHintText,
    required this.searchIcon,
    required this.searchClearIcon,
    required this.backgroundColor,
    this.customIconPack,
  });

  final _IconController iconController;
  final List<IconPack>? iconPack;
  final Map<String, IconData>? customIconPack;
  final String? searchHintText;
  final Icon? searchIcon;
  final Icon? searchClearIcon;
  final Color? backgroundColor;

  @override
  State<_IconSearchBar> createState() => _IconSearchBarState();
}

class _IconSearchBarState extends State<_IconSearchBar> {
  _search(String searchValue) {
    Map<String, IconData> searchResult = Map<String, IconData>();

    for (var pack in widget.iconPack!) {
      _IconManager.getSelectedPack(pack).forEach((String key, IconData val) {
        if (key.toLowerCase().contains(searchValue.toLowerCase())) {
          searchResult.putIfAbsent(key, () => val);
        }
      });
    }

    if (widget.customIconPack != null) {
      widget.customIconPack!.forEach((String key, IconData val) {
        if (key.toLowerCase().contains(searchValue.toLowerCase())) {
          searchResult.putIfAbsent(key, () => val);
        }
      });
    }

    setState(() {
      if (searchResult.length != 0) {
        widget.iconController.icons = searchResult;
      } else {
        widget.iconController.removeAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<_IconController>(builder: (ctx, controller, _) {
      return TextField(
        onChanged: (val) => _search(val),
        controller: controller.searchTextController,
        style: TextStyle(
          color: _ColorBrightness(widget.backgroundColor!).isLight()
              ? Colors.black
              : Colors.white,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.only(top: 15),
          hintStyle: TextStyle(
            color: _ColorBrightness(widget.backgroundColor!).isLight()
                ? Colors.black54
                : Colors.white54,
          ),
          hintText: widget.searchHintText,
          prefixIcon: widget.searchIcon,
          suffixIcon: AnimatedSwitcher(
            child: controller.searchTextController.text.isNotEmpty
                ? IconButton(
                    icon: widget.searchClearIcon!,
                    onPressed: () => setState(() {
                      controller.searchTextController.clear();
                      if (widget.customIconPack != null)
                        controller.addAll(widget.customIconPack ?? {});

                      if (widget.iconPack != null)
                        for (var pack in widget.iconPack!) {
                          controller.addAll(_IconManager.getSelectedPack(pack));
                        }
                    }),
                  )
                : const SizedBox(
                    width: 10,
                  ),
            duration: const Duration(milliseconds: 300),
          ),
        ),
      );
    });
  }
}

class _AdaptiveDialog extends StatelessWidget {
  const _AdaptiveDialog({
    required this.child,
    required this.constraints,
    required this.shape,
  });

  final Widget child;
  final BoxConstraints? constraints;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, dimens) {
        if (dimens.maxWidth < constraints!.maxWidth ||
            dimens.maxHeight < constraints!.maxHeight) {
          return child;
        }
        return Center(
          child: ConstrainedBox(
            constraints: constraints!,
            child: Dialog(
              shape: shape,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenDialog extends StatelessWidget {
  const _FullScreenDialog({
    required this.iconController,
    required this.showSearchBar,
    required this.showTooltips,
    required this.backgroundColor,
    required this.title,
    required this.iconPackMode,
    required this.customIconPack,
    required this.searchIcon,
    required this.searchClearIcon,
    required this.searchHintText,
    required this.iconColor,
    required this.noResultsText,
    required this.iconSize,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  final _IconController iconController;
  final bool? showSearchBar;
  final bool? showTooltips;
  final Color? backgroundColor;
  final Widget? title;
  final List<IconPack>? iconPackMode;
  final Map<String, IconData>? customIconPack;
  final Icon? searchIcon;
  final Icon? searchClearIcon;
  final String? searchHintText;
  final Color? iconColor;
  final String? noResultsText;
  final double? iconSize;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: <Widget>[
              Container(
                height: kToolbarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: DefaultTextStyle(
                        child: title!,
                        style: TextStyle(
                          color: _ColorBrightness(backgroundColor!).isLight()
                              ? Colors.black
                              : Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: _ColorBrightness(backgroundColor!).isLight()
                            ? Colors.black
                            : Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (showSearchBar!)
                _IconSearchBar(
                  iconController: iconController,
                  iconPack: iconPackMode,
                  customIconPack: customIconPack,
                  searchIcon: searchIcon,
                  searchClearIcon: searchClearIcon,
                  searchHintText: searchHintText,
                  backgroundColor: backgroundColor,
                ),
              Expanded(
                child: _IconPicker(
                  iconController: iconController,
                  showTooltips: showTooltips,
                  iconPack: iconPackMode,
                  customIconPack: customIconPack,
                  iconColor: iconColor,
                  backgroundColor: backgroundColor,
                  noResultsText: noResultsText,
                  iconSize: iconSize,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultDialog extends StatelessWidget {
  const _DefaultDialog({
    required this.controller,
    this.showSearchBar,
    this.routedView = false,
    this.adaptive = false,
    this.showTooltips,
    this.barrierDismissible,
    this.iconSize,
    this.iconColor,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.iconPickerShape,
    this.backgroundColor,
    this.constraints,
    this.title,
    this.closeChild,
    this.searchIcon,
    this.searchHintText,
    this.searchClearIcon,
    this.noResultsText,
    this.iconPackMode,
    this.customIconPack,
  });

  final _IconController controller;
  final bool? showSearchBar;
  final bool routedView;
  final bool adaptive;
  final bool? showTooltips;
  final bool? barrierDismissible;
  final double? iconSize;
  final Color? iconColor;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final ShapeBorder? iconPickerShape;
  final Color? backgroundColor;
  final BoxConstraints? constraints;
  final Widget? title;
  final Widget? closeChild;
  final Icon? searchIcon;
  final String? searchHintText;
  final Icon? searchClearIcon;
  final String? noResultsText;
  final List<IconPack>? iconPackMode;
  final Map<String, IconData>? customIconPack;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_IconController>.value(
      value: controller,
      builder: (ctx, w) {
        if (adaptive) {
          if (routedView) {
            return _FullScreenDialog(
              iconController: controller,
              showSearchBar: showSearchBar,
              showTooltips: showTooltips,
              backgroundColor: backgroundColor,
              title: title,
              iconPackMode: iconPackMode,
              customIconPack: customIconPack,
              searchIcon: searchIcon,
              searchClearIcon: searchClearIcon,
              searchHintText: searchHintText,
              iconColor: iconColor,
              noResultsText: noResultsText,
              iconSize: iconSize,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
            );
          }
          return _AdaptiveDialog(
            constraints: constraints,
            shape: iconPickerShape,
            child: Scaffold(
              backgroundColor: backgroundColor,
              body: Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: kToolbarHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: DefaultTextStyle(
                              child: title!,
                              style: TextStyle(
                                color:
                                    _ColorBrightness(backgroundColor!).isLight()
                                        ? Colors.black
                                        : Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: _ColorBrightness(backgroundColor!).isLight()
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    if (showSearchBar!)
                      _IconSearchBar(
                        iconController: controller,
                        iconPack: iconPackMode,
                        customIconPack: customIconPack,
                        searchIcon: searchIcon,
                        searchClearIcon: searchClearIcon,
                        searchHintText: searchHintText,
                        backgroundColor: backgroundColor,
                      ),
                    Expanded(
                      child: _IconPicker(
                        iconController: controller,
                        showTooltips: showTooltips,
                        iconPack: iconPackMode,
                        customIconPack: customIconPack,
                        iconColor: iconColor,
                        backgroundColor: backgroundColor,
                        noResultsText: noResultsText,
                        iconSize: iconSize,
                        mainAxisSpacing: mainAxisSpacing,
                        crossAxisSpacing: crossAxisSpacing,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return AlertDialog(
            backgroundColor: backgroundColor,
            shape: iconPickerShape,
            title: DefaultTextStyle(
              child: title!,
              style: TextStyle(
                color: _ColorBrightness(backgroundColor!).isLight()
                    ? Colors.black
                    : Colors.white,
                fontSize: 20,
              ),
            ),
            content: Container(
              constraints: constraints,
              child: Column(
                children: <Widget>[
                  if (showSearchBar!)
                    _IconSearchBar(
                      iconController: controller,
                      iconPack: iconPackMode,
                      customIconPack: customIconPack,
                      searchIcon: searchIcon,
                      searchClearIcon: searchClearIcon,
                      searchHintText: searchHintText,
                      backgroundColor: backgroundColor,
                    ),
                  Expanded(
                    child: _IconPicker(
                      iconController: controller,
                      showTooltips: showTooltips,
                      iconPack: iconPackMode,
                      customIconPack: customIconPack,
                      iconColor: iconColor,
                      backgroundColor: backgroundColor,
                      noResultsText: noResultsText,
                      iconSize: iconSize,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: ButtonStyle(
                  padding: WidgetStateProperty.resolveWith(
                    (states) => const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: closeChild!,
              ),
            ],
          );
        }
      },
    );
  }
}

class FlutterIconPicker {
  static Future<IconData?> showIconPicker(
    BuildContext context, {

    /// Defines if the searchbar will be
    /// shown above the icons
    bool showSearchBar = true,

    /// Adapts the dialog to the screen size.
    /// Behaves like a "ModalDialog"
    /// Defaults to `false`
    bool adaptiveDialog = false,

    /// Shows the labels underneeth the proper icon
    /// WARNING ON FLUTTER WEB: Could slow down the performance unless SKIA is deactivated
    /// Defaults to `false`
    bool showTooltips = false,

    /// Declares if the AlertDialog should dismiss when tapping on the outer barrier
    /// Defaults to `true`
    bool barrierDismissible = true,

    /// Size for every icon as [double]
    /// Default: `40.0`
    double iconSize = 40,

    /// The color of every Icon to be picked
    /// Defaults to `Theme.of(context).iconTheme.color` settings
    Color? iconColor,

    /// How much space to place between children in a run in the main axis.
    /// For example, if [spacing] is 10.0, the children will be spaced at least 10.0 logical pixels apart in the main axis.
    /// Defaults to 5.0
    double mainAxisSpacing = 5.0,

    /// How much space to place between children in a run in the cross axis.
    /// For example, if [spacing] is 10.0, the children will be spaced at least 10.0 logical pixels apart in the cross axis.
    /// Defaults to 5.0
    double crossAxisSpacing = 5.0,

    /// The dialogs shape for the picker
    /// Defaults to AlertDialog shape
    ShapeBorder? iconPickerShape,

    /// The color for the AlertDialog's background color
    /// Defaults to `Theme.of(context).dialogBackgroundColor` settings
    Color? backgroundColor,

    /// The dialogs `BoxConstraints` for limiting/setting:
    /// `maxHeight`, `maxWidth`, `minHeight`, `minWidth`
    /// Defaults to:
    /// ```dart
    ///   const BoxConstraints(maxHeight: 350, minWidth: 450, maxWidth: 678)
    /// ```
    BoxConstraints? constraints,

    /// The title for the Picker.
    /// Sits above the [ip.SearchBar] and [Icons].
    /// Defaults to:
    /// ```dart
    ///   const Text('Pick an icon')
    /// ```
    Widget title = const Text('Pick an icon'),

    /// The child for the Widget `FlatButton`, which closes the dialog.
    /// Sits underneeth everything.
    /// Defaults to:
    /// ```dart
    ///   const Text(
    ///     'Close',
    ///     textScaleFactor: 1.25,
    ///   ),
    /// ```
    Widget closeChild = const Text(
      'Close',
      textScaleFactor: 1.25,
    ),

    /// The prefix icon before the search textfield
    /// Defaults to:
    /// ```dart
    ///   const Icon(Icons.search)
    /// ```
    Icon searchIcon = const Icon(Icons.search),

    /// The Text to show when Searchbar-Term is empty
    /// Default: `Search`
    String searchHintText = 'Search',

    /// The suffix icon after the search textfield
    /// Defaults to:
    /// ```dart
    ///   const Icon(Icons.close)
    /// ```
    Icon searchClearIcon = const Icon(Icons.close),

    /// The text to show when no results where found for the search term
    /// Default: `No results for:`
    String noResultsText = 'No results for:',

    /// The modes which Icons to show
    /// Modes: `material`,
    ///        `cupertino`,
    ///        `materialOutline`,
    ///        `fontAwesomeIcons`,
    ///        `lineAwesomeIcons`
    /// Default: `IconPack.material`
    List<IconPack> iconPackModes = const <IconPack>[IconPack.material],

    /// Provide here your custom IconPack in a [Map<String, IconData>]
    /// to show your own collection of Icons to pick from
    Map<String, IconData>? customIconPack,
  }) async {
    if (iconColor == null) iconColor = Theme.of(context).iconTheme.color;
    if (constraints == null) {
      if (adaptiveDialog) {
        constraints =
            const BoxConstraints(maxHeight: 500, minWidth: 450, maxWidth: 720);
      } else {
        constraints =
            const BoxConstraints(maxHeight: 350, minWidth: 450, maxWidth: 678);
      }
    }

    if (iconPickerShape == null)
      iconPickerShape =
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0));
    if (backgroundColor == null)
      backgroundColor = Theme.of(context).dialogBackgroundColor;

    IconData? iconPicked;

    final controller = _IconController();

    if (adaptiveDialog) {
      if (MediaQuery.of(context).size.width >= constraints.maxWidth) {
        iconPicked = await showDialog(
          barrierDismissible: barrierDismissible,
          context: context,
          builder: (BuildContext context) => _DefaultDialog(
            controller: controller,
            showSearchBar: showSearchBar,
            adaptive: adaptiveDialog,
            showTooltips: showTooltips,
            barrierDismissible: barrierDismissible,
            iconSize: iconSize,
            iconColor: iconColor,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            iconPickerShape: iconPickerShape,
            backgroundColor: backgroundColor,
            constraints: constraints,
            title: title,
            closeChild: closeChild,
            searchIcon: searchIcon,
            searchHintText: searchHintText,
            searchClearIcon: searchClearIcon,
            noResultsText: noResultsText,
            iconPackMode: iconPackModes,
            customIconPack: customIconPack,
          ),
        );
      } else {
        iconPicked = await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => _DefaultDialog(
              controller: controller,
              showSearchBar: showSearchBar,
              routedView: true,
              adaptive: adaptiveDialog,
              showTooltips: showTooltips,
              barrierDismissible: barrierDismissible,
              iconSize: iconSize,
              iconColor: iconColor,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              iconPickerShape: iconPickerShape,
              backgroundColor: backgroundColor,
              constraints: constraints,
              title: title,
              closeChild: closeChild,
              searchIcon: searchIcon,
              searchHintText: searchHintText,
              searchClearIcon: searchClearIcon,
              noResultsText: noResultsText,
              iconPackMode: iconPackModes,
              customIconPack: customIconPack,
            ),
          ),
        );
      }
    } else {
      iconPicked = await showDialog(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (BuildContext context) => _DefaultDialog(
          controller: controller,
          showSearchBar: showSearchBar,
          showTooltips: showTooltips,
          barrierDismissible: barrierDismissible,
          iconSize: iconSize,
          iconColor: iconColor,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          iconPickerShape: iconPickerShape,
          backgroundColor: backgroundColor,
          constraints: constraints,
          title: title,
          closeChild: closeChild,
          searchIcon: searchIcon,
          searchHintText: searchHintText,
          searchClearIcon: searchClearIcon,
          noResultsText: noResultsText,
          iconPackMode: iconPackModes,
          customIconPack: customIconPack,
        ),
      );
    }

    controller.searchTextController.clear();

    if (iconPicked != null) {
      return iconPicked;
    }
    return null;
  }
}
