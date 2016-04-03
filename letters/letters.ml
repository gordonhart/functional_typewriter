#load "str.cma";;

open Printf;;
open Str;;


type point = float * float * float;;
type letter = point list;;
type sentence = letter list;;

(* print testers for relevant structures of the point type *)
(* let print_letter (pl : letter) : unit =
	List.iter (fun (a,b,c) -> printf "(%f, %f, %f)\n" a b c) pl;;
let print_sentence (pll : sentence) : unit =
	List.iter (fun pl -> List.iter (fun (a,b,c) -> printf "(%f, %f, %f)\n" a b c) pl) pll;; *)

class alphabet = 
	(* append ^$ / prepend $^ a char to a string *)
	(* let (^$) c s = s ^ Char.escaped c in *)
	let ($^) c s = Char.escaped c ^ s in


	(* retrieve the entire contents of a filename rooted in the current directory *)
	let load_file (filename : string) : string =
		try
			let ic = open_in filename in
			let n = in_channel_length ic in
			let s = Bytes.create n in
			really_input ic s 0 n;
			close_in ic; s
		with _ -> failwith "couldn't read from file"
	in


	let get_letter_from_file (filename : string) : letter = 
		let fos s = try float_of_string s with _ -> -3273.1 in
		
		let data_raw = load_file filename in
		let data_split = Str.split (Str.regexp "\n") data_raw in

		let data_sep = List.filter (fun x -> 
			(* double backslash on . to shut the interpreter warnings up *)
			Str.string_match (Str.regexp "v -?[0-9]+\\.[0-9]+ -?[0-9]+\\.[0-9]+ -?[0-9]+\\.[0-9]+") x 0
		) data_split in (* at this point we've isolated the lines with vertex information *)

		let vertex_data = List.map (fun x ->
			List.map (fun p -> fos p) (List.tl (Str.split (Str.regexp "[v ]") x))
		) data_sep in

		let vertex_triplets = List.map (fun x ->
			match x with
			| x::z::ny::r -> (x,(-1.)*.ny,z)
			| _ -> failwith "in get_points_from_file: bad data"
		) vertex_data in 

		vertex_triplets (* finally we have a list of points in the proper order for letter *)
	in


	let get_letter (ltr : char) : letter =
		try get_letter_from_file ("Alphabet/"^(ltr $^ ".obj"))
		with _ -> failwith "in get_letter: couldn't load this letter"
	in


	let get_sentence (stc : string) : sentence = 
		try let the_sentence = ref [] in (* ghetto imperative string fold *)
			String.iter (fun c -> the_sentence := (get_letter c)::!the_sentence) stc;
			!the_sentence
		with _ -> failwith "in get_sentence: couldn't do that sentence"
	in


	object
		method letter (l : char) : letter = get_letter l
		method sentence (s : string) : sentence = get_sentence s
	end;;





