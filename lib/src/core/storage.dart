/// Callback-based local storage abstraction.
///
/// Instead of depending on `get_storage` or `shared_preferences`, the viewer
/// plugins accept read/write callbacks through the service config so the
/// host app can provide any storage implementation.
///
/// The plugin provides a default no-op implementation that simply keeps
/// values in memory for the lifetime of the controller.
class PluginStorage {
  final T? Function<T>(String key) _readFn;
  final void Function(String key, dynamic value) _writeFn;
  final void Function(String key) _removeFn;

  const PluginStorage._({
    required T? Function<T>(String key) read,
    required void Function(String key, dynamic value) write,
    required void Function(String key) remove,
  })  : _readFn = read,
        _writeFn = write,
        _removeFn = remove;

  /// Create a storage backed by the given callbacks.
  factory PluginStorage({
    required T? Function<T>(String key) read,
    required void Function(String key, dynamic value) write,
    required void Function(String key) remove,
  }) = PluginStorage._;

  /// In-memory only storage (default when host app provides nothing).
  factory PluginStorage.memory() {
    final map = <String, dynamic>{};
    return PluginStorage(
      read: <T>(key) {
        final val = map[key];
        if (val is T) return val;
        return null;
      },
      write: (key, value) => map[key] = value,
      remove: (key) => map.remove(key),
    );
  }

  /// Read a value by key. Returns null if not found or wrong type.
  T? read<T>(String key) => _readFn<T>(key);

  /// Write a value by key.
  void write(String key, dynamic value) => _writeFn(key, value);

  /// Remove a value by key.
  void remove(String key) => _removeFn(key);
}
