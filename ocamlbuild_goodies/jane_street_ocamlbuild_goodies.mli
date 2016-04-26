(** Goodies for ocamlbuild *)

(** Tracking external dependences. This allows you to modify external libraries you
    depends on, reinstall and recompile your package without having to do `make clean`. *)
val track_external_deps : Ocamlbuild_plugin.hook -> unit

(** Alternative rule to build a .cmxs from .cmxa. In some cases the default rule doesn't
    work properly.

    Reported upstream:
      https://github.com/ocaml/ocamlbuild/issues/77
*)
val alt_cmxs_of_cmxa_rule : Ocamlbuild_plugin.hook -> unit

(** Pass [-predicates] options to ocamldep as well.

    Accepted upstream but not yet released:
      https://github.com/ocaml/ocamlbuild/pull/74
*)
val pass_predicates_to_ocamldep : Ocamlbuild_plugin.hook -> unit
