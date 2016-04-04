#use "gcode.ml";;

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
		try Unix.system ("java -cp \"serial/jssc-2.8.0.jar:serial\" Sender \""^instr^"\" &\n")
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
	printf "------- enter a tinyg command: ";
	let this_str = read_line () in
	send_packet [this_str];;


(* this is effectively the "main". accepts an optional argument for custom settings,
otherwise will write with the defaults (stored in the gcode_translator class) *)
let talk ?(sets=None) () : int = 
	let gc = match sets with (* optionally add custom settings to session *)
		| Some s -> new gcode_translator ~settings:s ()
		| None -> new gcode_translator ()
	in 
	let rec talkloop i = 
		printf "\n==> ";
		let this_str = read_line() in

		let special_commands = [  (* mapping for each special command *)  
			( "quit", fun i -> i );
			( "raw" , fun i -> raw_command(); talkloop (i+1) );
			( "home", fun i -> send_packet ["G28.3X0Y0Z0\n"]; talkloop (i+1) );
			( "kill", fun i -> send_packet ["$md\n"]; talkloop (i+1) );
			(* ( "~"   , fun i -> printf "cmd %d is a tilde\n" i; talkloop (i+1)) *)
		] in

		if List.exists (fun (s,c) -> s=this_str) special_commands then (* perform special cmd *)
 			let (c,action) = List.find (fun (sc,sa) -> sc=this_str) special_commands in action i
 		else
			let () = (* try sending the translated letters to the machine one at a time *)
				try let pktseq = gc#translate this_str in 
					(* send_packet (List.fold_left (@) [] pktseq) *)
					List.iter send_packet pktseq
				with _ -> printf "Not able to write that.\n\n" 
			in talkloop (i+1)
	in talkloop 0;;




(* main runtime loop *)
printf "\nsaid %d things\n" (talk ())
(* printf "\nsaid %d things\n" (talk ~sets:(Some {
	font		= "serif";
	width 		= 3.;
	height 		= 4.;
	kerning 	= 1.;
	linespace 	= 6.;
	sc_ratio	= 0.7;
}) ()) *)


