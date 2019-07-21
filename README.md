# RedRtMidiPoC
Simple PoC that shows Midi IN messages handling with Red language. RtMidi version 4.0 is used.

This code provides some bindings for the RtMidi library as well as RtMidi binaries for Windows and MacOS. The purpose of this code is to test a "callback" from external library. It is not extensively tested and may contain bugs.

At the time of writing, the macOS version does not behave exactly like the Windows. On macOS, messages are not written to the text area, however they are still received correctly by the application.

![Screenshot](https://github.com/Softknobs/RedRtMidiPoC/blob/master/red-rtmidi-ui.png)

## Compilation or Cross compilation

### Windows
```
red.exe -t Windows red-rtmidi.red
```
`librtmidi.dll` is required in the executable folder

### MacOS
```
./red -t macOS red-rtmidi.red
```
`librtmidi.dylib`must be present in the `red-rtmidi.app\Contents\MacOS` application folder
