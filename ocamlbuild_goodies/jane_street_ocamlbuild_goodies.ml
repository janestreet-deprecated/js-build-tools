open Ocamlbuild_plugin

let alt_cmxs_of_cmxa_rule = function
  | After_rules ->
    rule "Generate a cmxs from a cmxa"
      ~dep:"%.cmxa"
      ~prod:"%.cmxs"
      ~insert:`top
      (fun env _ ->
         Cmd (S [ !Options.ocamlopt
                ; A "-shared"
                ; A "-linkall"
                ; A "-I"; A (Pathname.dirname (env "%"))
                ; A (env "%.cmxa")
                ; A "-o"
                ; A (env "%.cmxs")
                ]))
  | _ -> ()

let pass_predicates_to_ocamldep = function
  | After_rules ->
    pflag ["ocaml"; "ocamldep"] "predicate" (fun s -> S [A "-predicates"; A s])
  | _ ->
    ()

(* Tracking of external dependencies *)
let track_external_deps = function
  | Before_hygiene ->
    (* Force ocamlbuild to redo listings and stats on each run *)
    let build_dir = !Options.build_dir in
    if Sys.file_exists build_dir then
      let files_to_remove =
        Pathname.readdir build_dir
        |> Array.to_list
        |> ListLabels.filter ~f:(fun s ->
          Pathname.check_extension s "stats" ||
          Pathname.check_extension s "files")
        |> ListLabels.map ~f:((/) build_dir)
        |> Command.atomize
      in
      Command.execute (Cmd (S [A"rm"; A"-f"; files_to_remove]))

  | After_rules ->
    let open Findlib in
    let package_and_deps pkg_name =
      let pkg = Findlib.query pkg_name in
      pkg :: pkg.dependencies
    in

    (* ocamldep depends on the listing of the dependencies directories only *)
    pdep ["ocaml"; "ocamldep"] "package" (fun pkg_name ->
      ListLabels.map (package_and_deps pkg_name) ~f:(fun pkg ->
        Printf.sprintf ".%s.files" pkg.name));

    pdep ["ocaml"; "compile"] "package" (fun pkg_name ->
      ListLabels.map (package_and_deps pkg_name) ~f:(fun pkg ->
        Printf.sprintf ".%s.md5sums" pkg.name));

    rule "Package listing"
      ~prod:".%.files"
      (fun env _ ->
         let pkg = Findlib.query (env "%") in
         Cmd (S [A "find"; A pkg.location; A "-type"; A "f";
                 Sh ">"; A (env ".%.files")]));

    let stat, md5sum =
      match run_and_read "uname" |> String.trim with
      | "Darwin" ->
        (S [A "stat"; A "-f"; A "%d:%i:%m"],
         A "md5")
      | _ ->
        (S [A "stat"; A "-c"; A "%d:%i:%Y"],
         A "md5sum")
    in

    rule "Package files stats"
      ~deps:[".%.files"]
      ~prod:".%.stats"
      (fun env _ ->
         Cmd (S [A "xargs"; stat;
                 Sh "<"; A (env ".%.files");
                 Sh ">"; A (env ".%.stats")
                ]));

    rule "Package checksum"
      ~deps:[".%.files"; ".%.stats"]
      ~prod:".%.md5sums"
      (fun env _ ->
         Cmd (S [A "xargs"; md5sum;
                 Sh "<"; A (env ".%.files");
                 Sh ">"; A (env ".%.md5sums")]))

  | _ -> ()
