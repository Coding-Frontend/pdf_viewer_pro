import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// Rx<T> — lightweight reactive value with auto-tracking for Obx
// ---------------------------------------------------------------------------

/// A reactive value that notifies listeners when changed.
/// Supports auto-tracking: when [value] is read inside an [Obx] builder,
/// the widget automatically subscribes to future changes.
class Rx<T> extends ChangeNotifier implements ValueListenable<T> {
  Rx(this._value);

  // --- auto-tracking bookkeeping ---
  static final List<Set<Rx>> _trackerStack = [];

  static void _startTracking(Set<Rx> bucket) => _trackerStack.add(bucket);
  static Set<Rx> _stopTracking() => _trackerStack.removeLast();

  // --- value ---
  T _value;

  @override
  T get value {
    if (_trackerStack.isNotEmpty) _trackerStack.last.add(this);
    return _value;
  }

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  /// Force-notify even if the value is the same reference (useful for
  /// mutable collections).
  void refresh() => notifyListeners();

  /// Listen to value changes; returns a dispose callback.
  VoidCallback listen(void Function(T value) callback) {
    void listener() => callback(_value);
    addListener(listener);
    return () => removeListener(listener);
  }

  @override
  String toString() => 'Rx<$T>($value)';
}

// ---------------------------------------------------------------------------
// RxList<E> — reactive list that notifies on mutation
// ---------------------------------------------------------------------------

class RxList<E> extends Rx<List<E>> implements List<E> {
  RxList(super.initial);

  // Trigger rebuild after every mutation
  void _notify() => refresh();

  @override
  int get length {
    // Track access so Obx picks it up
    if (Rx._trackerStack.isNotEmpty) Rx._trackerStack.last.add(this);
    return value.length;
  }

  @override
  set length(int newLength) {
    value.length = newLength;
    _notify();
  }

  @override
  E operator [](int index) => value[index];

  @override
  void operator []=(int index, E val) {
    value[index] = val;
    _notify();
  }

  @override
  void add(E element) {
    value.add(element);
    _notify();
  }

  @override
  void addAll(Iterable<E> iterable) {
    value.addAll(iterable);
    _notify();
  }

  @override
  bool remove(Object? element) {
    final result = value.remove(element);
    if (result) _notify();
    return result;
  }

  @override
  void clear() {
    value.clear();
    _notify();
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    value.sort(compare);
    _notify();
  }

  @override
  void insert(int index, E element) {
    value.insert(index, element);
    _notify();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    value.insertAll(index, iterable);
    _notify();
  }

  @override
  E removeAt(int index) {
    final result = value.removeAt(index);
    _notify();
    return result;
  }

  @override
  E removeLast() {
    final result = value.removeLast();
    _notify();
    return result;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    value.removeWhere(test);
    _notify();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    value.retainWhere(test);
    _notify();
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacements) {
    value.replaceRange(start, end, replacements);
    _notify();
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    value.fillRange(start, end, fillValue);
    _notify();
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable,
      [int skipCount = 0]) {
    value.setRange(start, end, iterable, skipCount);
    _notify();
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    value.setAll(index, iterable);
    _notify();
  }

  @override
  void shuffle([math.Random? random]) {
    value.shuffle(random);
    _notify();
  }

  // --- delegated read-only members ---
  @override
  bool get isEmpty => value.isEmpty;
  @override
  bool get isNotEmpty => value.isNotEmpty;
  @override
  Iterator<E> get iterator => value.iterator;
  @override
  E get first => value.first;
  @override
  set first(E val) {
    value.first = val;
    _notify();
  }

  @override
  E get last => value.last;
  @override
  set last(E val) {
    value.last = val;
    _notify();
  }

  @override
  E get single => value.single;
  @override
  Iterable<E> get reversed => value.reversed;
  @override
  bool contains(Object? element) => value.contains(element);
  @override
  int indexOf(E element, [int start = 0]) => value.indexOf(element, start);
  @override
  int lastIndexOf(E element, [int? start]) =>
      value.lastIndexOf(element, start);
  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      value.indexWhere(test, start);
  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) =>
      value.lastIndexWhere(test, start);
  @override
  E elementAt(int index) => value.elementAt(index);
  @override
  Iterable<E> where(bool Function(E element) test) => value.where(test);
  @override
  Iterable<T> whereType<T>() => value.whereType<T>();
  @override
  Iterable<T> map<T>(T Function(E e) toElement) => value.map(toElement);
  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      value.expand(toElements);
  @override
  E reduce(E Function(E value, E element) combine) => value.reduce(combine);
  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      value.fold(initialValue, combine);
  @override
  bool every(bool Function(E element) test) => value.every(test);
  @override
  bool any(bool Function(E element) test) => value.any(test);
  @override
  String join([String separator = '']) => value.join(separator);
  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.firstWhere(test, orElse: orElse);
  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.lastWhere(test, orElse: orElse);
  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.singleWhere(test, orElse: orElse);
  @override
  List<E> toList({bool growable = true}) => value.toList(growable: growable);
  @override
  Set<E> toSet() => value.toSet();
  @override
  Iterable<E> skip(int count) => value.skip(count);
  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
      value.skipWhile(test);
  @override
  Iterable<E> take(int count) => value.take(count);
  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
      value.takeWhile(test);
  @override
  Iterable<E> followedBy(Iterable<E> other) => value.followedBy(other);
  @override
  void forEach(void Function(E element) action) => value.forEach(action);
  @override
  List<E> operator +(List<E> other) => value + other;
  @override
  List<E> sublist(int start, [int? end]) => value.sublist(start, end);
  @override
  Map<int, E> asMap() => value.asMap();
  @override
  Iterable<E> getRange(int start, int end) => value.getRange(start, end);
  @override
  void removeRange(int start, int end) {
    value.removeRange(start, end);
    _notify();
  }

  @override
  List<R> cast<R>() => value.cast<R>();
}

// ---------------------------------------------------------------------------
// RxMap<K,V> — reactive map that notifies on mutation
// ---------------------------------------------------------------------------

class RxMap<K, V> extends Rx<Map<K, V>> implements Map<K, V> {
  RxMap(super.initial);

  void _notify() => refresh();

  @override
  V? operator [](Object? key) => value[key];

  @override
  void operator []=(K key, V val) {
    value[key] = val;
    _notify();
  }

  @override
  void clear() {
    value.clear();
    _notify();
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final result = value.putIfAbsent(key, ifAbsent);
    _notify();
    return result;
  }

  @override
  V? remove(Object? key) {
    final result = value.remove(key);
    _notify();
    return result;
  }

  @override
  void addAll(Map<K, V> other) {
    value.addAll(other);
    _notify();
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    value.addEntries(newEntries);
    _notify();
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    value.removeWhere(test);
    _notify();
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final result = value.update(key, update, ifAbsent: ifAbsent);
    _notify();
    return result;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    value.updateAll(update);
    _notify();
  }

  // --- delegated read-only members ---
  @override
  bool get isEmpty => value.isEmpty;
  @override
  bool get isNotEmpty => value.isNotEmpty;
  @override
  int get length => value.length;
  @override
  Iterable<K> get keys => value.keys;
  @override
  Iterable<V> get values => value.values;
  @override
  Iterable<MapEntry<K, V>> get entries => value.entries;
  @override
  bool containsKey(Object? key) => value.containsKey(key);
  @override
  bool containsValue(Object? val) => value.containsValue(val);
  @override
  void forEach(void Function(K key, V value) action) => value.forEach(action);
  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) =>
      value.map(convert);
  @override
  Map<RK, RV> cast<RK, RV>() => value.cast<RK, RV>();
}

// ---------------------------------------------------------------------------
// Type aliases (match GetX naming)
// ---------------------------------------------------------------------------

typedef RxBool = Rx<bool>;
typedef RxInt = Rx<int>;
typedef RxDouble = Rx<double>;
typedef RxString = Rx<String>;
typedef RxnString = Rx<String?>;

// ---------------------------------------------------------------------------
// .obs extensions — create Rx values from literals
// ---------------------------------------------------------------------------

extension IntRxExt on int {
  RxInt get obs => RxInt(this);
}

extension DoubleRxExt on double {
  RxDouble get obs => RxDouble(this);
}

extension BoolRxExt on bool {
  RxBool get obs => RxBool(this);
}

extension StringRxExt on String {
  RxString get obs => RxString(this);
}

extension ListRxExt<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);
}

extension MapRxExt<K, V> on Map<K, V> {
  RxMap<K, V> get obs => RxMap<K, V>(this);
}

extension ColorRxExt on Color {
  Rx<Color> get obs => Rx<Color>(this);
}

// Convenience getters for RxString
extension RxStringExt on Rx<String> {
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

// firstWhereOrNull extension (replaces GetX collection extension)
extension ListFirstWhereOrNull<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Obx — auto-tracking reactive builder widget
// ---------------------------------------------------------------------------

class Obx extends StatefulWidget {
  final Widget Function() builder;
  const Obx(this.builder, {super.key});

  @override
  State<Obx> createState() => _ObxState();
}

class _ObxState extends State<Obx> {
  Set<Rx> _tracked = {};

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _unsubscribeAll() {
    for (final rx in _tracked) {
      rx.removeListener(_rebuild);
    }
  }

  @override
  Widget build(BuildContext context) {
    _unsubscribeAll();

    final bucket = <Rx>{};
    Rx._startTracking(bucket);
    final child = widget.builder();
    Rx._stopTracking();

    _tracked = bucket;
    for (final rx in _tracked) {
      rx.addListener(_rebuild);
    }

    return child;
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// ever() — listen to an Rx and return a dispose handle
// ---------------------------------------------------------------------------

VoidCallback ever<T>(Rx<T> rx, void Function(T value) callback) {
  return rx.listen(callback);
}

// ---------------------------------------------------------------------------
// PluginController — base controller with lifecycle hooks
// ---------------------------------------------------------------------------

abstract class PluginController {
  bool _initialized = false;
  bool _disposed = false;

  void onInit() {
    _initialized = true;
  }

  void onClose() {
    _disposed = true;
  }

  bool get isInitialized => _initialized;
  bool get isDisposed => _disposed;

  /// Call from the widget's initState (after construction).
  void initialize() {
    if (!_initialized) onInit();
  }

  /// Call from the widget's dispose.
  void dispose() {
    if (!_disposed) onClose();
  }
}
