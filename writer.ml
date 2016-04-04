#use "gcode.ml";;
(* #use "letters.ml";; *)

open Printf;;
open Unix;;


(* send a single packet (usually a single letter) to the machine and 
pause execution of the program long enough for it to execute. *)
let rec send_packet (l : gcode_packet) : unit = 
	(* verbose packet sending response *)
	printf "sending packet: %s" (List.hd l);
	List.iter (printf "\t\t%s") (List.tl l);
	flush_all ();

	let minisleep (sec : float) : unit = ignore (Unix.select [] [] [] sec) in

	let instr = List.fold_left (fun acc x -> acc^x) "" l in
	let result = 
		(* try Unix.system ("./sender.sh \'"^instr^"\'\n")  *)
		try Unix.system ("java -cp \"serial/jssc-2.8.0.jar:serial\" Sender \""^instr^"\"\n")
		with _ -> failwith "write failed" 
	in
	
	(* sleep for a time dependent on how long this input is expected to take to write.
	should probably have a more robust solution but the machine is slow enough that this 
	doens't have an impact on execution time, only keeps the driver queue from overflowing *)
	minisleep (0.25 *. (float_of_int (List.length l)));

	match result with
	| WEXITED i | WSIGNALED i -> () (* printf "sent %d characters and exited.\n" i *)
	| WSTOPPED i -> failwith "in send_packet: send attempt stopped unsuccessfully";;


(* for sending commands directly to the driver board *)
let raw_command () : unit = 
	printf "\n enter a tinyg command: ";
	let this_str = read_line () in
	send_packet [this_str];;


(* this is effectively the "main" *)
let talk ?(sets=None) () : int = 
	let gc = match sets with (* optionally add custom settings to session *)
		| Some s -> new gcode_translator ~settings:s ()
		| None -> new gcode_translator ()
	in 
	let rec talkloop i = 
		printf "\n==> ";
		let this_str = read_line() in
		if this_str = "quit" then i 
		else if this_str = "raw" then let () = raw_command () in talkloop (i+1)
		else if this_str = "home" then let () = send_packet ["G28.3X0Y0Z0\n"] in talkloop (i+1)
		else if this_str = "kill" then let () = send_packet ["$md\n"] in talkloop (i+1)
		else
			let () = (* try sending the translated letters to the machine one at a time *)
				try let pktseq = gc#translate this_str in List.iter send_packet pktseq
				with _ -> printf "Not able to write that.\n\n" 
			in talkloop (i+1)
	in talkloop 0;;




(* main runtime loop *)
printf "\nsaid %d things\n" (talk ())


