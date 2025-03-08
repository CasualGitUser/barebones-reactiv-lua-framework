# barebones-reactiv-lua-framework
A barebones framework for roblox that contains reactive streams and signals. The signals have the same operators (map, filter etc.) as streams and also have onEvent function (which you can think of as a onChange function).

### Importing
A code example best demonstrates this:

```lua
local ReactiveModule = require(PathToReactiveModule)
local Reactive = Reactive.Reactive -- reactive streams
local Signal = Reactive.Signal -- signals, aka variables with a :onEvent function to react to changes

-- here comes your code
```

### Constructors
Those are the constructor functions of reactive streams:
- `Reactive.new()`: doesn't emit anything, you need to :emit() yourself
- `Reactive.fromInstance(instance)`: everytime a property of instance changes it emits the changed property (for                                        example it would emit `"Position"` when the Position property changes).
- `Reactive.fromInterval(seconds)`: emits nil every `seconds` seconds.
- `Reactive.fromRBXScriptSignal(rbx_script_signal)`: Everytime the `rbx_script_signal` emits, the returned stream emits too together with the values. That holds true even for multiple values. That simply means when using operators/onevent the function you pass in takes 2 or more values.
- 

### Emitting and Reacting
- `Reactive:emit(value1, value2, ...)`: Used to emit values. Takes 0 or more arguments.
- `Reactive:onEvent(listener: <T>(T) -> ())`: Takes a listener takes the value that the stream emits and returns nothing.

### Operators
Operators always return new streams (operators are pure methods).

As in the name of this github mentioned, there aren't many operators.
- `Reactive:map(f: <A, B>(A) -> B)`: Returns a new `Reactive` stream that emits the mapped values.
- `Reactive:flatMap(f: <A, B>(A) -> Reactive<B>)`: Returns a new `Reactive` stream that flatmaps the returned values. Aka, everytime the value f returned (which is a stream) emits, it emits the value in the flatMapped stream too.
- `Reactive:filter(predicate: <T>(T) -> boolean)`: Returns a new `Reactive stream` that emits only values that pass the given predicate.
- `Reactive:scan(init, f: <T>(acc, T) -> acc`: <p> - init: the value acc has on the first emit. <p> - f: Takes the accumulator as the first argument and the emitted value as the second argument. Returns the new value of the accumulator, which gets emitted in the stream returned from :scan.
- `Reactive:merge(...)`: Merges the given streams. Everytime one of the merged streams (or self) emits a value, it emits the value in the returned stream too.
- `Reactive:skipUntil(predicate: <T>(T) -> boolean)`: Doesn't emit the itmes in the returned stream until one passes the predicate, after which it emits all items the original stream emits.
- `Reactive:buffer(duration)`: Returns a stream that emits every `duration` seconds a array of all the values emitted in `duration` seconds or nothing if nothing got emitted in `duration` seconds.

## Signals
I don't advise using the Signals provided by this module. They work, but if you think about it: what does filtering or buffering a signal really mean? In the case of buffering, it really just emits x references to signal.value. The usefulness is questionable, but i provide it anyway since i coded it already.

### Signal specific constructors
- `Reactive.fromValueBase(value_base: ValueBase)`: Returns a Signal that changes everytime the value_base object changes.
- `Reactive.fromAttribute(object: Instance, attribute: string)`: Returns a signal that changes everytime the attribute value changes.
