(lang dune 3.10)
(name cordis_oxcaml)
(version 1.0.0)

(generate_opam_files true)

(license MIT)
(authors "DeepSeek-AI" "Shigma" "Jane Street" "Cordis-OxCaml Contributors")
(maintainers "tradis-core@cordis.org")

(package
 (name cordis-oxcaml)
 (synopsis "Spatiotemporal Composability Meta-Framework in OxCaml")
 (description
  "Cordis-OxCaml is an industrial-grade, zero-leak meta-framework for spatial coeffects and temporal revertible effects in OxCaml. It provides dynamic dependency injection, hot-swappable plugins, lifecycle scopes, algebraic effect rollbacks, schema validation, and high-frequency reactive financial pipelines.")
 (depends
  (ocaml (>= 5.0.0))
  (dune (>= 3.10.0))
  (unix (>= 0))
  (alcotest (>= 1.7.0) :with-test))
 (tags ("cordis" "oxcaml" "spatiotemporal" "plugins" "effects" "quantitative-finance")))
