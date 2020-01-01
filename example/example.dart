import 'package:nodeify/event_emitter.dart';

/// note the usage of the [data] parameter,
/// even though there is no other parameter used
void test([data]) {
  print('Hello world.');
}

/// note the usage of the [data] parameter, as it is the last
/// parameter in the list, after the parameter that is actually
/// needed
void test1([counter, data]) {
  print('$data has been called $counter times.');
}

/// note the async usage
/// for consistency, ALL methods in this library should be await-ed
/// however, it is most important for `.emit()` and `.removeListener()`
void main() async {
  var evt = EventEmitter();

  //no user-defined args, as only data was provided in the function definition
  await evt.on('test', test);

  /// one user-defined arg, for the [counter] param. This should be
  /// an array with parameters you defined - everything except for data
  await evt.on('test1', test1, [5]);

  await evt.emit('test');

  /// prints: Hello world.
  await evt.emit('test');

  /// prints: Hello world.
  await evt.removeListener('test', test);

  /// returns nothing
  await evt.emit('test');

  /// returns nothing
  print(
      'test Listener has been removed - 3 emits were called, but only 2 were executed because of the .removeListener()');

  await evt.emit('test1');

  /// prints: test1 has been called 5 times.
  await evt.emit('test1');

  /// prints: test1 has been called 5 times.
  await evt.emit('test1');

  /// prints: test1 has been called 5 times.
  await evt.removeListener('test1', test1);

  /// returns nothing
  await evt.emit('test1');

  /// returns nothing
  print(
      'test1 Listener has been removed - 4 emits were called, but only 3 were executed because of the .removeListener()');
}
