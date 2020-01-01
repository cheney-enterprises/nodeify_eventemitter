# EventEmitter

An asynchronous, Broadcast Stream-based implementation of the basic NodeJS EventEmitter API.

---

This library provides an asynchronous, Stream-based API for registering for, listening to, and emitting Events, thereby allowing one to take action, via a provided named callback, once an Event is received.

The important distinction here is that this is an asynchronous library, with all Stream-based operations fully asynchronous under the hood, and almost all of the work has been abstracted away - all one need do is use the api with async/await, provide unique Event strings, and write EventCallbacks that have an optional positional arguments list, that includes a _data_ param as either the only argument, or the last argument - depending on whether you provide user-defined parameters or not.

## Example

```Dart

    // EventCallbacks:

    // 1a. providing the _data_ parameter, but not using it - this is the minimum EventCallback structure - you must include the _data_ param, even if you are not using it.
    EventCallback<void> test = ([data]) {
        print('I have been called!');
    }

    // 1b. providing and utilizing the _data_ param.
    EventCallback<void> test1 = ([data]) {
        print('$data has been called!');
    };

    // 2. providing user-defined parameter as well as _data_, and calling both.
    EventCallback<void> test2 = ([counter, data]) {
        print('$data has been called $counter times');
    };

    void main() async {
        // standard EventEmitter
        var evt = EventEmitter();
        // customized EventListener with maxListeners set to 10
        var evt_2 = EventEmitter(maxListeners: 10);
        // customized EventListener with maxListeners set to 1
        var evt_3 = EventEmitter(maxListeners: 1);

        // registering the 'test' Event with the _test_ EventCallback on the evt instance
        await evt.on('test', test);
        // registering the 'test1' Event with the _test1_ EventCallback on the evt_2 instance
        await evt_2.on('test1', test1);
        // registering the 'test2' Event with the _test2_ EventCallback on the evt_3 instance
        await evt_3.on('test2', test2, [5] // positional parameter added, this is the counter parameter
        );

        // because evt_3 was constructed with a maxListener count of 1, this will NOT work, and it will throw an exception
        try {
            await evt_3.on('test3', test);
        } catch (e) {
            print(e); // returns: 'Exception: Too many listeners assigned: Max Listeners - 1, total listeners: 1. You can adjust by either using the Setter [maxListeners(int max)], or setting the {maxListener: } optional named parameter setting on the EventEmitter constructor.'
        }

        await evt.emit('test'); // returns: I have been called!
        await evt_2.emit('test1'); // returns: test1 has been called!
        await evt_3.emit('test2'); // returns: test2 has been called 5 times
        await evt_3
            .emit('test3'); // return nothing, because the listener was not added

        await evt_2.removeListener('test1', test1);

        await evt.emit('test'); // returns: I have been called!
        await evt_2.emit('test1'); // returns nothing, since it has been removed
        await evt_3.emit('test2'); // returns: test2 has been called 5 times
        await evt_3
            .emit('test3'); // returns nothing, because the listener was not added

        await evt.destroy();
        await evt_3.removeAllListeners('test2');
        await evt_3.on('test3', test1);

        await evt.emit(
            'test'); // returns: This Stream is likely closed. Please see this Error Message for further details: Bad state: Cannot add new events after calling close
        await evt_2.emit('test1'); // returns nothing, since it has been removed
        await evt_3.emit('test2'); // returns nothing, since it has been removed
        await evt_3.emit('test3'); // returns: test3 has been called!

        await evt_2.destroy();
        await evt_3.destroy();

        await evt.emit('test'); // returns: This Stream is likely closed. Please see this Error Message for further details: Bad state: Cannot add new events after calling close
        await evt_2.emit('test1'); // returns: This Stream is likely closed. Please see this Error Message for further details: Bad state: Cannot add new events after calling close
        await evt_3.emit('test2'); // returns: This Stream is likely closed. Please see this Error Message for further details: Bad state: Cannot add new events after calling close
        await evt_3.emit('test3'); // returns: This Stream is likely closed. Please see this Error Message for further details: Bad state: Cannot add new events after calling close

    }



```

---

**README and Package are still in progress - this is a beta release, and we are looking for input on the package**

Please feel free to submit feedback on our github.

this package is meant to simulate the EventEmitter built-in for node - currently implemented are .on(String eventId,Function callback,[optional callback parameters List]) in order to LISTEN to events, and act on them as they come in (with the callback), .emit(String eventId) to EMIT those events for the LISTENER to act upon, .removeListener(String eventId,Function callback). .destroy() closes the stream completely.

Several important notes: 

    - this package performs best when using `async` for any function that implements these methods, and all methods should be prepended with `await`.

    - ALL CALLBACKS USED MUST BE NAMED. Do not use anonymous closures, as the package uses hashCodes to track and therefore remove callbacks, as needed.

    - All callbacks should have a `data` parameter as 1.) it's only parameter, or 2.) as it's last parameter.

    - All paramaters in your named function should be held within a List (an optional parameter List)
