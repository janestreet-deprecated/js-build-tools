(* OASIS_START *)
(* OASIS_STOP *)
# 3 "myocamlbuild.ml"


let () =
  Ocamlbuild_plugin.dispatch (fun hook ->
    dispatch_default hook)
