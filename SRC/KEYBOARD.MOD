(* Abbreviation: Keyboard *)
(* Version 1.10, Nov 1984 *)
(* comments modified Feb 7, 1985 *)
IMPLEMENTATION MODULE Keyboard;
(*
   Default driver for terminal input.
   [Private module of the MODULA-2/86 system]

Derived from the Lilith Modula-2 system developed by the
group of Prof. N. Wirth at ETH Zurich, Switzerland.
*)




PROCEDURE Read (VAR ch: CHAR);
END Read;

PROCEDURE KeyPressed (): BOOLEAN;
END KeyPressed;

END Keyboard.
