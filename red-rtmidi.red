Red [		
	needs: 'view
]	

partial-midi-message: copy []
midi-message: copy []

partial-input-port-name: copy []
input-port-names: copy []

; Retrieve last two bytes of midi message value
to-string-byte: function [value [integer!]][
	;get last byte as string
	at tail form to-hex	value -2
]

; Function that builds a midi message sent from R/S RtMidi code
build-message: func [value [integer!] last [logic!]][		
	append partial-midi-message to-string-byte value	
	append partial-midi-message " "
	if (last) [		
		clear midi-message
		midi-message: append partial-midi-message		
		partial-midi-message: copy []		
		either none? message-field/text [			
			message-field/text: to-string midi-message
		][			
			append message-field/text #"^(line)"			
			append message-field/text to-string midi-message
		]		
	]
]

#system [

	; Midi in callback type definition
	callback!: alias function! [
		timestamp	[float!]
		message 	[c-string!]
		size		[integer!]			
		user-data-pointer [integer!]
	]

	; RtMidi bindings definition
	#switch OS [
		Windows		[
			#define RtMidi-library "librtmidi.dll"
			#define RtMidi-API 4
		]
		macOS		[
			#define RtMidi-library "librtmidi.dylib"
			#define RtMidi-API 1
		]
	]	
	#import [
		;Platform specific code: no switch depending on platform made here
		RtMidi-library cdecl [			
			native-midi-in-pointer: "rtmidi_in_create" [api [integer!] client [c-string!] queue-size [integer!] return: [integer!]]
			native-midi-count: "rtmidi_get_port_count" [midi-pointer [integer!] return: [integer!]]			
			native-port-name: "rtmidi_get_port_name" [midi-pointer [integer!] port-number [integer!] return: [c-string!]]
			native-open-port: "rtmidi_open_port" [midi-pointer [integer!] port-number [integer!] port-name [c-string!]]
			native-close-port: "rtmidi_close_port" [midi-pointer [integer!]]
			native-set-callback: "rtmidi_in_set_callback" [midi-pointer [integer!] callback [callback!] data [c-string!]]
			native-midi-in-ignore-types: "rtmidi_in_ignore_types" [midi-pointer [integer!] sysex [logic!] time [logic!] sense [logic!]]
		]
	]		

	; Callback to be used on incoming midi messages. The message is stored as local variable.
	midi-in-callback: function [
		[cdecl]
		timestamp	[float!]
		message 	[c-string!]
		size		[integer!]			
		user-data-pointer [integer!]
		/local i
	][
		i: 1		
		while [i <= size] [			
			#call [							
				build-message as integer! message/i (i = size)			
			]
			i: i + 1
		]		
	]		
]	

; Routine to retrieve a pointer to a RtMidi device
get-midi-in-pointer: routine [return: [integer!]][
	;Platform specific code: 4 is for WINMM Api
	native-midi-in-pointer RtMidi-API "REDMIDI" 100	
]

; Routine that opens a midi port (device pointer is returned)
open-midi-port: routine [	
	port-number [integer!] 		
	return: [integer!]
	/local midi-pointer	
][
	;Platform specific code: 4 is for WINMM Api
	midi-pointer: native-midi-in-pointer RtMidi-API "REDMIDI" 100
	native-open-port midi-pointer port-number ""	
	native-set-callback midi-pointer :midi-in-callback ""
	native-midi-in-ignore-types midi-pointer false false false
	midi-pointer
]

; Routine that closes a midi port
close-midi-port: routine [
	midi-pointer [integer!] 	
][	
	native-close-port midi-pointer
]


; Routine to change ignored types
set-ignore-types: routine [
	midi-pointer [integer!] 
	sysex [logic!]
	time [logic!]
	sense [logic!]	
][	
	native-midi-in-ignore-types midi-pointer sysex time sense
]


; Routine that retrieves the midi ports count
midi-in-port-count: routine [
	midi-pointer [integer!] 
	return: [integer!]
][
	native-midi-count midi-pointer
]

; Routine to get the port name for the midi device pointed by midi-pointer
get-port-name: routine [
	midi-pointer [integer!] 
	port-number [integer!] 	
	/local c-port-name red-port-name
][		
	c-port-name: native-port-name midi-pointer port-number ""	
	red-port-name: string/load c-port-name length? c-port-name UTF-8
	SET_RETURN(red-port-name)	
]

; Get a device pointer
midi-in-pointer: get-midi-in-pointer

; Retrieve number of ports
port-count: midi-in-port-count midi-in-pointer

; Populate a block with midi inputs
input-port-names: copy []

repeat i port-count [
	port-name: get-port-name midi-in-pointer (i - 1)	
	append input-port-names to-string port-name
]


midi-pointer: none!

view [
	title "Midi Input"
	text 200x32 "Midi inputs"
	text "Received messages" return
	midi-inputs: text-list 200x400 data input-port-names on-change [		
		if (midi-pointer <> none!) [			
			close-midi-port midi-pointer
		]		
		midi-pointer: open-midi-port (midi-inputs/selected - 1)
	]
	message-field: area 400x400
]
