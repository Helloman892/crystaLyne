# crystaLyne

Formally, this is an (almost) LL(1) parser hooked up to an interpreter for the esolang [Ly](https://github.com/LyricLy/Ly) ([see also](https://esolangs.org/wiki/Ly)), the full (read: comprehensive) documentation of which I have yet to write.

For those interested, the reason it isn't truly LL(1) is due to the existance of arbitrary-length strings and integers, making this technically LL(\*).

## Compilation

Under macOS/Linux/WSL, follow the instructions [here](https://crystal-lang.org/reference/installation/) to install the compiler, and then run `make.sh` in the top level of the repository.

Under Windows... it's probably best not to try, but it *is* possible to cross-compile to Windows from other platforms.

## Usage

```
crystalyne <filename> [-d] [-s] [-ti] [-t=0.0] [-b=0]
Note that `filename` may instead be a appropriately delimited string representing the Ly program to run

Flags:
-d, --debug     : Output the current stack along with various other debug information after the execution of each instruction
-s, --slow      : Wait for the Enter key to be pressed before advancing to the next instruction (step-through)
-ti, --timeit   : Display the total execution time after the program is finished [NB: yes, almost all the other flags break this]
-t TIME, 
  --time=TIME   : Set the amount of time to sleep between each instruction
-b N,
  --benchmark=N : Run the program N times and average the execution time [if this is passed, --timeit will do nothing]
-h, --help      : Show the help text (a more concise yet less informative version of this)
```

## Development

Again, just as with compiling on Windows, it's probably best not to try to decipher what I've written here - though efforts to make the huge case-when statement in `LyStack` more concise without sacrificing even more readability would be appreciated.

For those that wish to help out, the main interpreter source is in `lib/interpreter.cr`; the frontend (where I wrote the `OptionParser`, for those that know the language well enough) is in `src/ly_interpreter.cr`.

## Contributors

- [Helloman892](https://github.com/Helloman892) - overlord of crystaLyne
- [LyricLy](https://github.com/LyricLy) - creator of Ly

## Thanks to

- [mosop](https://github.com/mosop) for [stdio](https://github.com/mosop/stdio)
- [waterlink](https://github.com/waterlink) for [spec2.cr](https://github.com/waterlink/spec2.cr)

Both of these shards are used for tests, and crystaLyne doesn't depend on them.
