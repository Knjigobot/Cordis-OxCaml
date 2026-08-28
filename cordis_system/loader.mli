(** [Cordis_system.Loader] - Declarative Plugin Manifest & Dynamic Dependency Reconciler *)

open Cordis_core.Types
open Cordis_core

type plugin_spec = {
  name : string;
  plugin : (module Registry.PLUGIN);
  enabled : bool;
  config : Schema.json_value;
}

type manifest = plugin_spec list

type t

val create : Context.t -> t

val topological_sort : manifest -> (manifest, string list) result

val reconcile : t -> manifest -> (unit, string) result

val current_manifest : t -> manifest
