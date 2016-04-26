(** Generate an opam .install file from the oasis build log *)

(** A description item from the install *)
type item

(** An oasis library. The argument is the same name as what comes just after the [Library]
    keyword in the _oasis file.

    If [sub_dir] is given, files will be installed in [lib/<sub_dir>].
*)
val oasis_lib : ?sub_dir:string -> string -> item

(** An oasis object. The argument is the same name as what comes just after the [Object]
    keyword in the _oasis file.

    If [sub_dir] is given, files will be installed in [lib/<sub_dir>].
*)
val oasis_obj : ?sub_dir:string -> string -> item

(** An oasis library. The argument is the same name as what comes just after the [Library]
    keyword in the _oasis file.

    [section] defaults to ["bin"], you can put ["libexec"] to install the executable in
    the ["lib/<package>"] directory instead (for ppx rewriters for instance).
*)
val oasis_exe : ?dest:string -> ?section:string -> string -> item

(** A single file. *)
val file : ?dest:string -> section:string -> string -> item

(** Produces a [package ^ ".install"] file *)
val generate : package:string -> item list -> unit
