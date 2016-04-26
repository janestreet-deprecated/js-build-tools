(* Generate <package>.install from setup.log *)

module String_map = Map.Make(String)
let string_map_of_list l =
  List.fold_left
    (fun acc (k, v) ->
       assert (not (String_map.mem k acc));
       String_map.add k v acc)
    String_map.empty l

let lines_of_file fn =
  let ic = open_in fn in
  let rec loop acc =
    match input_line ic with
    | exception End_of_file ->
      close_in ic;
      List.rev acc
    | line ->
      loop (line :: acc)
  in
  loop []

let read_setup_log () =
  lines_of_file "setup.log"
  |> List.map (fun line -> Scanf.sscanf line "%S %S" (fun tag arg -> (tag, arg)))

let read_setup_data () =
  lines_of_file "setup.data"
  |> List.map (fun line -> Scanf.sscanf line "%[^=]=%S" (fun k v -> (k, v)))

let remove_cwd =
  let prefix = Sys.getcwd () ^ Filename.dir_sep in
  let len_prefix = String.length prefix in
  fun fn ->
    let len = String.length fn in
    if len >= len_prefix && String.sub fn 0 len_prefix = prefix then
      String.sub fn len_prefix (len - len_prefix)
    else
      fn

module Dest = struct
  type t =
    | Infer
    | In_dir of string
    | This of string

  let of_dest_option = function
    | None   -> Infer
    | Some s -> This s

  let of_sub_dir_option = function
    | None   -> Infer
    | Some s -> In_dir s
end

let gen_section oc name files =
  let pr fmt = Printf.fprintf oc (fmt ^^ "\n") in
  pr "%s: [" name;
  List.iter
    (fun (src, dst) ->
       let src = remove_cwd src in
       let dst =
         match (dst : Dest.t) with
         | Infer -> Filename.basename src
         | This fn -> fn
         | In_dir dir -> Filename.concat dir (Filename.basename src)
       in
       if src = dst then
         pr "  %S" src
       else
         pr "  %S {%S}" src dst)
    files;
  pr "]"

let rec filter_log tags log acc =
  match log with
  | [] -> acc
  | (tag, fname) :: rest ->
    match String_map.find tag tags with
    | exception Not_found -> filter_log tags rest acc
    | dst -> filter_log tags rest ((fname, dst) :: acc)

type item =
  { section : string
  ; tags    : (string * Dest.t) list
  ; extra   : (string * Dest.t) list
  }

let oasis_lib ?sub_dir name =
  { section = "lib"
  ; tags    = [ "built_lib_" ^ name, Dest.of_sub_dir_option sub_dir ]
  ; extra   = []
  }

let oasis_obj ?sub_dir name =
  { section = "lib"
  ; tags    = [ "built_obj_" ^ name, Dest.of_sub_dir_option sub_dir ]
  ; extra   = []
  }

let oasis_exe ?dest ?(section="bin") name =
  let dest =
    match dest with
    | None -> None
    | Some name ->
      Some (
        if Sys.win32 && not (Filename.check_suffix name ".exe") then
          name ^ ".exe"
        else
          name
      )
  in
  { section = section
  ; tags    = [ "built_exec_" ^ name, Dest.of_dest_option dest ]
  ; extra   = []
  }

let file ?dest ~section name =
  { section = section
  ; tags    = []
  ; extra   = [ name, Dest.of_dest_option dest ]
  }

let generate ~package items =
  let log = read_setup_log () in
  let setup_data = read_setup_data () in
  let ext_dll =
    match List.assoc "ext_dll" setup_data with
    | ext -> ext
    | exception Not_found -> ".so"
  in
  let merge name files map =
    match String_map.find name map with
    | files' -> String_map.add name (files @ files') map
    | exception Not_found -> String_map.add name files map
  in
  let sections =
    List.fold_left
      (fun acc { section; tags; extra } ->
         let tags = string_map_of_list tags in
         let files = filter_log tags log [] @ extra in
         if section = "lib" then
           let stubs, others =
             List.partition
               (fun (fn, _) -> Filename.check_suffix fn ext_dll)
               files
           in
           merge "lib" others (merge "stublibs" stubs acc)
         else
           merge section files acc)
      String_map.empty items
    |> String_map.bindings
    |> List.filter (fun (_, l) -> l <> [])
  in
  let oc = open_out (package ^ ".install") in
  List.iter (fun (name, files) -> gen_section oc name files) sections;
  close_out oc
