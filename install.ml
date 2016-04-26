#directory "_build/oasis2opam-install";;
#load "oasis2opam_install.cma";;

open Oasis2opam_install;;

generate ~package:"js-build-tools"
  [ oasis_lib "jane_street_ocamlbuild_goodies"
  ; oasis_lib "oasis2opam_install"
  ; file "META" ~section:"lib"
  ]
