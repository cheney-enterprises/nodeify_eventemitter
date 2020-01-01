part of nodeify.event_emitter;

///
/// [EventCallback] `typedef` to assist in enforcing the callback style needed
/// for the [EventEmitter] library to work properly.
///
/// All event callbacks __MUST__ have the following items:
/// 1. It must have, at least, a single `dynamic` _param_, enclosed within an 
/// optional positional list, with a minimum of a __data__ parameter.
///  * If you are _not_ adding your own _param_, __data__ should be added as the
/// __only__ argument in the optional _param_ list, held within an unnamed
/// optional list. You may use the __data__ _param_ as you wish - it will be 
/// resolved to the [eventId] that you assign to each `Listener`- or leave it 
/// alone. See example below.
///  * If you _are_ adding your own _param_, __data__ should be added as the
/// __LAST__`element` in the _param_ [List]. Again, you may use it as you wish,
/// or leave it be. The library processes it as if you are using it, so it
/// should be accounted for in your  [EventCallback] function creation.
/// 2. __ALL CALLBACKS__ _MUST_ __BE NAMED FUNCTION'S! __
///  * The library uses [Function.hashCode] to register and search for
/// `Listener's` so that each `Listener` can be removed if and when required.
/// For this reason, an anonymous [Function] without being assigned to a named 
/// variable cannot be used.
/// 3. Your placeholder params should _not_ be statically typed.
///  * In order to use the `typedef`, we cannot statically type the individual
/// [List] _params_.
///
/// Example [EventCallback] [Function]'s:
///
///
///     EventCallback<void> test = ([data]){ // no user-defined param
///       print('Hello World!');
///     }
///
///     EventCallback<void> test_2 = ([counter,data]){ // a single user-defined param
///       print('$data has been called $counter times');
///     }
///
///
typedef EventCallback<T> = T Function([dynamic]);

/// [EventEmitter] [Class] - an asynchronous, `broadcast`[Stream]-based [Class]
/// that allows multiple `Listeners` on each `instance`, providing notification
/// to each `Listener` when [emit] is called on an [Event]. Each `Listener` has
/// a coinciding [EventCallback] [Function] that is called each time it
/// received notification of an [Event] being `emitted`.
///
/// Example provides two instances of [EventEmitter] - `evt`, & `evt_2`:
///
///     var evt = EventEmitter(); /// no optional args, maxListeners set to 50
///     var evt_2 = EventEmitter(maxListeners:10); /// maxListeners set to 10
///
/// 1. [on] method provides the registration/subscription aspect of the
/// [EventEmitter] [Class] - explained further in the documetation for that
/// method below.
/// 2. [emit] method provides a means of publishing the event so that any
/// `Listeners` registered by [on] can process the event and decide if it should
/// run it's [EventCallback] - explained further in the documetation for that
/// method below.
/// 3. [removeListener] method removes the specified [EventCallback] from the
/// [_active_events] [Map], and puts it into the the [_removed_events] [Map] -
/// thereby preventing this specific [EventCallback] being called by this
/// specific [Event].
/// 4. [removeListeners] method removes multiple [EventCallback]'s, specified
/// via a [Set] argument, from the [_active_events] [Map], and puts the
/// specified removed [EventCallback]'s into the [_removed_events] [Map] -
/// thereby preventing these specific [EventCallback]'s from being called by
/// this specific [Event].
/// 5. [removeAllListeners] method removes __ALL__ [EventCallback]'s from
/// a given [Event].
/// 6. [destroy] method closes this instance's [Stream] and prevents all [Event]
/// 's that were assigned to this [Stream] from publishing, and listening, any
/// further, and prevents new subscribers from being added as well. For all
/// intents and purposes, this instance is no longer usable, and therefore
/// destroyed.
///
/// Example [EventEmitter] flow:
///
///
///     void test ([data]){ // no user-defined param, and `data` is not used - but it could be
///       print('Hello World!');
///     }
///
///     void test_2 ([counter,data]){ // a single user-defined param
///       print('$data has been called $counter times');
///     }
///
///     void main() async {
///       var evt = EventEmitter();
///
///       /// no user-defined args, as only data was provided in the function
///           definition
///       await evt.on('test', test);
///
///       /// one user-defined arg, for the [counter] param. This should be
///       /// an array with parameters you defined - everything except for data
///       await evt.on('test_2', test_2, [5]);
///
///       await evt.emit('test');
///
///       /// prints: Hello world.
///       await evt.emit('test');
///
///       /// prints: Hello world.
///       await evt.removeListener('test', test);
///
///       /// returns nothing
///       await evt.emit('test');
///
///       /// returns nothing
///       print('test Listener has been removed - 3 emits were called, but only 2 were executed because of the .removeListener()');
///
///       await evt.emit('test_2');
///
///       /// prints: test_2 has been called 5 times.
///       await evt.emit('test_2');
///
///       /// prints: test_2 has been called 5 times.
///       await evt.emit('test_2');
///
///       /// prints: test_2 has been called 5 times.
///       await evt.removeListener('test_2', test_2);
///
///       /// returns nothing
///       await evt.emit('test_2');
///
///       /// returns nothing
///       print('test_2 Listener has been removed - 4 emits were called, but only 3 were executed because of the .removeListener()');
///
///     }
class EventEmitter {
  /// internal counter keeping track of the number of event notifications made
  int _eventCount = 0;

  /// internal counter keeping track of the number of `Listeners` on each
  /// instance.
  int _listenerCount = 0;

  /// internal counter that limits the number of `Listeners` on each instance.
  ///
  /// This is automatically set at 50 if nothing is provided to the constructor,
  /// but can be set by providing that customized number to the constructor, or
  /// by using the [maxListeners] [Setter].
  int _maxListeners;

  /// internal [Map] that tracks the current active [event]s being tracked,
  /// along with every [Function.hashCode] assigned to each [Event].
  final Map<String, Set<int>> _active_events = {};

  /// internal [Map] that tracks all of the events that have been removed
  /// by calling [removeListener] for each [Event]. This means that even if a
  /// single [Event] has removed a hashCode from it's [Set], another [Event]
  /// could still use that [EventCallback].
  final Map<String, Set<int>> _removed_events = {};

  /// a [StreamController.broadcast] that provides the broadcast [Stream] that
  /// allows multiple `Listeners` to listen on.
  final StreamController _controller = StreamController.broadcast();

  /// `get` [_eventCount]
  int get eventCount => _eventCount;

  /// `get` [_maxListeners]
  int get maxListeners => _maxListeners;

  /// `get` [_listenerCount]
  int get listenerCount => _listenerCount;

  /// `set` [_maxListeners]
  set maxListeners(int max) {
    _maxListeners = max;
  }

  /// `set` [_listenerCount]
  set listenerCount(int initial) {
    _listenerCount = initial;
  }

  /// `set` [_eventCount]
  set eventCount(int initial) {
    _eventCount = initial;
  }

  /// [Class] [Constructor] - automatically sets [_maxListeners] to 50 via an
  /// optional named parameter
  EventEmitter({maxListeners = 50}) {
    _maxListeners = maxListeners;
  }

  /// [on] registers and subscribes new `listeners` and their [EventCallback]'s
  /// for future use.
  ///
  /// [on] takes 2 required parameters, and 4 optional positional
  /// parameters.They are as follows:
  ///
  /// 1. [eventId], of `Type` [String], should be a unique string that you want
  /// to use to identify each new [Event]. [eventId] will be used to [emit]
  /// each event as well, so it is best to make it memorable and related to the
  /// operation you are performing.
  /// 2. [callback], of `typedef` [EventCallback], must be a traditional named
  /// [Function]. No anonymous closures should be used, inline or named, as
  /// each named [Function] will be tracked, and subsequently called and
  /// removed (with [removeListener]) by using the unique [hashCode]
  /// of each named [Function]. When writing your callback, it should have a
  /// minimum of 1 - optional positional argument, and convention for this
  /// package dictates that this argument be named `data`. If you wish to add
  /// your own parameters, place them at the begining of your optional
  /// positional argument List, and then place `data` at the end.
  /// 3. [args] is a [List] of positional arguments for your [callback]. Any
  /// user-defined [callback]'s should be added here when calling [on]. `data`
  /// is automatically added by [on], so do not include it - [Function.apply]
  /// will throw an [Exception] if you do.
  /// 4.,5.,6. are all optional parameters provided by [Stream.listen]. Please
  /// refer to [Stream.listen] for their usages. For this library, [onError]
  /// and [onDone] are automatically initialized to [Null] if they are not
  /// provided by the user. [cancelOnError] is `true` by default, but can be
  /// changed if needed.
  ///
  /// Refer to [EventEmitter] for further examples.
  void on(String eventId, EventCallback callback,
      [List<dynamic> args,
      void Function(Error error, [StackTrace stacktrace]) onError,
      void Function() onDone,
      bool cancelOnError = true]) async {
    /// body will only run if the [Stream] is not closed. Else block [print]'s
    /// that the [Stream] is closed.
    if (!_controller.isClosed) {
      /// check to ensure that adding a new Listener will not exceed
      /// [_maxListeners] count. Throws an [Exception] if it dones not pass.
      if ((_listenerCount + 1) <= _maxListeners) {
        /// adds 1 to [_listenerCount]
        _listenerCount++;

        /// adds [hashCode] for [callback] to the [_active_events] if it is not
        /// alreadhy there
        _active_events.putIfAbsent(eventId, () {
          var temp = <int>{};
          temp.add(callback.hashCode);
          return temp;
        });

        /// adds a listener to the [Stream]
        await _controller.stream.listen((data) {
          /// this will only run if [data], in this context, matches [eventId]
          if (data == eventId) {
            /// temporary [List] to hold positional arguments
            var _args = [];

            /// if the provided [args] (from [on]) is [Null], [data] is added
            /// to [_args] immediately. Otherwise, all user-defined [args] are
            /// added to [_args].
            args == null ? _args.add(data) : _args.addAll(args);

            /// if there are user defined arguments, add [data] to the end of
            /// [_args].
            _args[0] != data ? _args.add(data) : null;

            /// as long as the [callback] provided isn't included in
            /// [_removed_events], run the rest of the [Function].
            if (_removed_events[eventId]?.contains(callback.hashCode) == null ||
                _removed_events[eventId].contains(callback.hashCode) == false) {
              /// check to see if the callback has already been added to
              /// [_active_events]. If it hasn't already been added, then add
              /// it.
              !_active_events[eventId].contains(callback.hashCode)
                  ? _active_events[eventId].add(callback.hashCode)
                  : null;

              /// if the [callback] made it this far, `call` the [callback]
              /// with the positional arguments added to [_args].
              Function.apply(callback, _args);
            }
          }
        },

            /// call [Stream.listen] arguments as either user-defined args, or
            /// [Null]/[False].
            onDone: onDone ??= null,
            onError: onError ??= null,
            cancelOnError: cancelOnError);
      } else {
        /// [Exception] thrown if too many listeners
        throw Exception(
            'Too many listeners assigned: Max Listeners - $maxListeners, total listeners: $_listenerCount. You can adjust by either using the Setter [maxListeners(int max)], or setting the {maxListener: } optional named parameter setting on the EventEmitter constructor.');
      }
    } else {
      /// [print] if [Stream] is closed.
      print('This Stream is closed.');
    }
  }

  /// [emit] adds an [Event] to the [Stream], notifying all listeners of the
  /// action.
  void emit(String eventId) async {
    /// [Stream.add] will throw an [Exception] if it's [Stream] is closed. [try]
    /// /[catch] used to ensure that it is caught.
    try {
      /// [Stream.add]
      await _controller.add(eventId);

      /// add 1 to _eventCount
      _eventCount++;
    } catch (e) {
      /// if [emit] fails, it is likely due to the [Stream] being closed, but
      /// the [Error] is also printed, just in case. This can be changed to an [Exception]/[Error] if one would like to [catch] their own and send to a `logger`, etc.
      print(
          'This Stream is likely closed. Please see this Error Message for further details: $e');
    }
  }

  /// [removeListener] removes a single, specified [callback] from this
  /// specific [eventId].
  void removeListener(String eventId, Function callback) async {
    /// remove [callback] from this [Event]'s [_active_events]
    await _active_events[eventId].remove(callback.hashCode);

    /// check to see if [_removed_events] contains this [Event] already. If it
    /// is, add this [callback] to this [Event]'s [Set]. Otherwise, create the
    /// entry, and add the [callback].
    await _removed_events.containsKey(eventId)
        ? await _removed_events[eventId].add(callback.hashCode)
        : await (_removed_events[eventId] = {}).add(callback.hashCode);

    _listenerCount -= 1;
  }

  /// [removeListener], but will remove a [Set] of specified [callbacks]
  void removeListeners(String eventId, Set<EventCallback> callbacks) {
    callbacks.forEach((callback) {
      _active_events[eventId].remove(callback.hashCode);
      _removed_events.containsKey(eventId)
          ? _removed_events[eventId].add(callback.hashCode)
          : (_removed_events[eventId] = {}).add(callback.hashCode);
    });
    _listenerCount -= callbacks.length;
  }

  /// [removeListener], but removes all [callback]'s instead of specified
  /// [callback]s
  void removeAllListeners(String eventId) {
    _active_events[eventId].forEach((fn) {
      _removed_events.containsKey(eventId)
          ? _removed_events[eventId].add(fn.hashCode)
          : (_removed_events[eventId] = {}).add(fn.hashCode);
    });
    _listenerCount -= _active_events[eventId].length;
    _active_events[eventId] = <int>{};
  }

  /// [destroy] closes the [Stream] and prevents any further use of this
  /// instance of [EventEmitter].
  void destroy() async {
    try {
      await _controller.close();
    } catch (e) {
      _controller.isClosed
          ? null
          : throw Exception(
              'Error in closing this Stream. Please see the Error Message: $e');
    }
  }
}

