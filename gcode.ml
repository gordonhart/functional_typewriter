#use "letters/letters.ml";;
(* #use "settings.ml";; *)


open Printf;;
open Str;;


(* string list containing only machine-ready gcode *)
type gcode_packet = string list;;
(* let print_packet gc : unit = List.iter (printf "%s") gc;; *)

(* sequence of gcode commands (grouped by letter) *)
type command_seq = gcode_packet list;;

type typewriter_settings = {
	width 		: float;
	height 		: float;
	kerning 	: float;
	linespace 	: float;
	sc_ratio 	: float;
};;


class gcode_translator (settings : typewriter_settings) = 

	(* helper function to test if a given character will be lowercase *)
	(* it's a brutish solution but it gets the job done *)
	let is_lowercase (l : char) : bool =
		let lowercase = ['a';'b';'c';'d';'e';'f';'g';'h';'i';
			'j';'k';'l';'m';'n';'o';'p';'q';'r';'s';'t';'u';'v';'w';'x';'y';'z'] in
		if (List.exists (fun x -> x=l) lowercase) then true else false
	in


	let letter_to_gcode_packet (pts : letter) (xpos : float) (lowercase : bool) : gcode_packet = 
		let mul = if lowercase then settings.sc_ratio else 1. in (* support lowercase at scratio size *)
		let meat = List.fold_left (fun acc (x,y,z) -> 
			let xp = ((mul*.x)*.(settings.width/.3.))+.xpos in
			let yp = (mul*.y)*.(settings.height/.4.) in (* letters are defined in .obj as 4x3 HxW *)
			acc @ [sprintf "G0X%fY%fZ%f\n" xp yp z]
		) [] pts in
		let suffix = sprintf "G0X%fY0Z1\n" ((mul*.settings.width)+.settings.kerning+.xpos) in (* go to start of next letter *)
		meat @ [suffix] 
	in


	(* this is also where we should handle lower case *)
	let words_to_command_seq (str : string) : command_seq = 
		try 
			let ltrs = new alphabet in
			let prefix = ["G90\n";"G28.3X0Y0\n"] in (* make sure to set local coord, home *)
	
			let acc = ref [prefix] in (* command_seq (gcode_packet list) *)
			let x_pos = ref 0.0 in (* currently lc,uc size are hardcoded but that will change *)
			let inc_xp lc = x_pos := !x_pos +. settings.kerning +. (if lc then settings.sc_ratio*.settings.width else settings.width) in

			String.iter (fun x ->
				let ilc = is_lowercase x in
				acc := !acc @ [(letter_to_gcode_packet (ltrs#letter x) (!x_pos) ilc)];
				inc_xp ilc
			) str;

			(* List.iter (fun x -> print_packet x) !acc; *)
			(* printf "newline len: %f\n" !x_pos; *)
			let suffix = [sprintf "G0X0Y-%fZ1\n" settings.linespace;"G28.3X0Y0\n"] in

			!acc @ [suffix]
		with _ -> failwith "in sentence_to_gcode: couldn't complete"
	in
	

	object
		method translate (sentence : string) : command_seq = words_to_command_seq sentence
	end;;




