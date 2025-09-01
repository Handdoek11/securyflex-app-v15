import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;

/// Keyboard shortcuts service for bulk operations in company dashboard
/// 
/// Provides professional keyboard shortcuts for:
/// - Bulk job management operations
/// - Quick navigation and search
/// - Data export and refresh operations
/// - Multi-selection actions
/// - Application review workflows
class KeyboardShortcutsService {
  static const String _tag = 'KeyboardShortcutsService';
  static bool _isInitialized = false;
  static final Map<String, VoidCallback> _registeredCallbacks = {};
  
  /// Initialize keyboard shortcuts service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Register system-wide shortcuts
      _registerSystemShortcuts();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        developer.log('$_tag: Keyboard shortcuts service initialized', name: 'KeyboardShortcuts');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to initialize keyboard shortcuts: $e', name: 'KeyboardShortcuts');
      }
    }
  }
  
  /// Register system-wide keyboard shortcuts
  static void _registerSystemShortcuts() {
    // Standard shortcuts that should work globally in the company dashboard
    final systemShortcuts = {
      'Ctrl+N': 'Create new job posting',
      'Ctrl+F': 'Focus search field',
      'Ctrl+K': 'Quick search/command palette',
      'Ctrl+R': 'Refresh current view',
      'F5': 'Refresh current view',
      'Ctrl+A': 'Select all (in multi-select contexts)',
      'Delete': 'Delete selected items',
      'Ctrl+E': 'Export current data',
      'Ctrl+P': 'Print current view',
      'Escape': 'Cancel operation/close modal',
      'Ctrl+Z': 'Undo last action',
      'Ctrl+Y': 'Redo last action',
      'Ctrl+S': 'Save current changes',
    };
    
    if (kDebugMode) {
      developer.log('$_tag: Registered ${systemShortcuts.length} system shortcuts', 
                   name: 'KeyboardShortcuts');
    }
  }
  
  /// Register callback for specific shortcut
  static void registerCallback(String shortcutId, VoidCallback callback) {
    _registeredCallbacks[shortcutId] = callback;
    
    if (kDebugMode) {
      developer.log('$_tag: Registered callback for $shortcutId', name: 'KeyboardShortcuts');
    }
  }
  
  /// Unregister callback for shortcut
  static void unregisterCallback(String shortcutId) {
    _registeredCallbacks.remove(shortcutId);
  }
  
  /// Handle keyboard event and execute appropriate callback
  static KeyEventResult handleKeyEvent(KeyEvent event) {
    if (!_isInitialized) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    
    // Build shortcut key string
    String shortcutKey = '';
    if (isControlPressed) shortcutKey += 'Ctrl+';
    if (isShiftPressed) shortcutKey += 'Shift+';
    if (isAltPressed) shortcutKey += 'Alt+';
    
    // Add the main key
    final mainKey = _getKeyString(event.logicalKey);
    if (mainKey.isNotEmpty) {
      shortcutKey += mainKey;
      
      // Execute registered callback if exists
      final callback = _registeredCallbacks[shortcutKey];
      if (callback != null) {
        callback();
        
        if (kDebugMode) {
          developer.log('$_tag: Executed callback for $shortcutKey', name: 'KeyboardShortcuts');
        }
        
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }
  
  /// Convert LogicalKeyboardKey to string representation
  static String _getKeyString(LogicalKeyboardKey key) {
    // Letters
    if (key == LogicalKeyboardKey.keyA) return 'A';
    if (key == LogicalKeyboardKey.keyB) return 'B';
    if (key == LogicalKeyboardKey.keyC) return 'C';
    if (key == LogicalKeyboardKey.keyD) return 'D';
    if (key == LogicalKeyboardKey.keyE) return 'E';
    if (key == LogicalKeyboardKey.keyF) return 'F';
    if (key == LogicalKeyboardKey.keyG) return 'G';
    if (key == LogicalKeyboardKey.keyH) return 'H';
    if (key == LogicalKeyboardKey.keyI) return 'I';
    if (key == LogicalKeyboardKey.keyJ) return 'J';
    if (key == LogicalKeyboardKey.keyK) return 'K';
    if (key == LogicalKeyboardKey.keyL) return 'L';
    if (key == LogicalKeyboardKey.keyM) return 'M';
    if (key == LogicalKeyboardKey.keyN) return 'N';
    if (key == LogicalKeyboardKey.keyO) return 'O';
    if (key == LogicalKeyboardKey.keyP) return 'P';
    if (key == LogicalKeyboardKey.keyQ) return 'Q';
    if (key == LogicalKeyboardKey.keyR) return 'R';
    if (key == LogicalKeyboardKey.keyS) return 'S';
    if (key == LogicalKeyboardKey.keyT) return 'T';
    if (key == LogicalKeyboardKey.keyU) return 'U';
    if (key == LogicalKeyboardKey.keyV) return 'V';
    if (key == LogicalKeyboardKey.keyW) return 'W';
    if (key == LogicalKeyboardKey.keyX) return 'X';
    if (key == LogicalKeyboardKey.keyY) return 'Y';
    if (key == LogicalKeyboardKey.keyZ) return 'Z';
    
    // Numbers
    if (key == LogicalKeyboardKey.digit1) return '1';
    if (key == LogicalKeyboardKey.digit2) return '2';
    if (key == LogicalKeyboardKey.digit3) return '3';
    if (key == LogicalKeyboardKey.digit4) return '4';
    if (key == LogicalKeyboardKey.digit5) return '5';
    if (key == LogicalKeyboardKey.digit6) return '6';
    if (key == LogicalKeyboardKey.digit7) return '7';
    if (key == LogicalKeyboardKey.digit8) return '8';
    if (key == LogicalKeyboardKey.digit9) return '9';
    if (key == LogicalKeyboardKey.digit0) return '0';
    
    // Function keys
    if (key == LogicalKeyboardKey.f1) return 'F1';
    if (key == LogicalKeyboardKey.f2) return 'F2';
    if (key == LogicalKeyboardKey.f3) return 'F3';
    if (key == LogicalKeyboardKey.f4) return 'F4';
    if (key == LogicalKeyboardKey.f5) return 'F5';
    if (key == LogicalKeyboardKey.f6) return 'F6';
    if (key == LogicalKeyboardKey.f7) return 'F7';
    if (key == LogicalKeyboardKey.f8) return 'F8';
    if (key == LogicalKeyboardKey.f9) return 'F9';
    if (key == LogicalKeyboardKey.f10) return 'F10';
    if (key == LogicalKeyboardKey.f11) return 'F11';
    if (key == LogicalKeyboardKey.f12) return 'F12';
    
    // Special keys
    if (key == LogicalKeyboardKey.escape) return 'Escape';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.arrowUp) return 'ArrowUp';
    if (key == LogicalKeyboardKey.arrowDown) return 'ArrowDown';
    if (key == LogicalKeyboardKey.arrowLeft) return 'ArrowLeft';
    if (key == LogicalKeyboardKey.arrowRight) return 'ArrowRight';
    
    return '';
  }
  
  /// Get list of available shortcuts for help/documentation
  static Map<String, String> getAvailableShortcuts() {
    return {
      'Ctrl+N': 'Create new job posting',
      'Ctrl+F': 'Focus search field',
      'Ctrl+K': 'Quick search/command palette',
      'Ctrl+R / F5': 'Refresh current view',
      'Ctrl+A': 'Select all items',
      'Delete': 'Delete selected items',
      'Ctrl+E': 'Export current data',
      'Ctrl+P': 'Print current view',
      'Escape': 'Cancel operation',
      'Ctrl+Z': 'Undo last action',
      'Ctrl+Y': 'Redo last action',
      'Ctrl+S': 'Save changes',
    };
  }
  
  /// Clear all registered callbacks
  static void clearCallbacks() {
    _registeredCallbacks.clear();
  }
  
  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get number of registered callbacks
  static int get registeredCallbacksCount => _registeredCallbacks.length;
}

/// Widget wrapper that provides keyboard shortcut handling
class KeyboardShortcutProvider extends StatefulWidget {
  final Widget child;
  final Map<String, VoidCallback> shortcuts;
  final bool enableSystemShortcuts;
  
  const KeyboardShortcutProvider({
    super.key,
    required this.child,
    this.shortcuts = const {},
    this.enableSystemShortcuts = true,
  });
  
  @override
  State<KeyboardShortcutProvider> createState() => _KeyboardShortcutProviderState();
}

class _KeyboardShortcutProviderState extends State<KeyboardShortcutProvider> {
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _registerShortcuts();
  }
  
  @override
  void didUpdateWidget(KeyboardShortcutProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortcuts != widget.shortcuts) {
      _registerShortcuts();
    }
  }
  
  void _registerShortcuts() {
    // Register widget-specific shortcuts
    for (final entry in widget.shortcuts.entries) {
      KeyboardShortcutsService.registerCallback(entry.key, entry.value);
    }
  }
  
  @override
  void dispose() {
    // Unregister widget-specific shortcuts
    for (final shortcutKey in widget.shortcuts.keys) {
      KeyboardShortcutsService.unregisterCallback(shortcutKey);
    }
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        return KeyboardShortcutsService.handleKeyEvent(event);
      },
      child: widget.child,
    );
  }
}

/// Mixin for widgets that need keyboard shortcut support
mixin KeyboardShortcutMixin<T extends StatefulWidget> on State<T> {
  final Map<String, VoidCallback> _shortcuts = {};
  
  /// Register a keyboard shortcut
  void registerShortcut(String shortcutKey, VoidCallback callback) {
    _shortcuts[shortcutKey] = callback;
    KeyboardShortcutsService.registerCallback(shortcutKey, callback);
  }
  
  /// Unregister a keyboard shortcut
  void unregisterShortcut(String shortcutKey) {
    _shortcuts.remove(shortcutKey);
    KeyboardShortcutsService.unregisterCallback(shortcutKey);
  }
  
  /// Dispose all registered shortcuts
  void disposeShortcuts() {
    for (final shortcutKey in _shortcuts.keys) {
      KeyboardShortcutsService.unregisterCallback(shortcutKey);
    }
    _shortcuts.clear();
  }
  
  @override
  void dispose() {
    disposeShortcuts();
    super.dispose();
  }
}