open Printf;;
open Str;;


type typewriter_settings = {
	width		: float;
	height		: float;
	kerning		: float;
	linespace	: float;
	sc_ratio	: float;
};;


let default_settings = {
	width 		= 3.0;
	height 		= 4.0;
	kerning 	= 1.0;
	linespace 	= 6.0;
	sc_ratio 	= 0.7;
} in