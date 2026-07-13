------------------------------ MODULE open_source_gnosis_src_mod_loader ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"detect_format", "parse", "compile", "imports_state", "resolve_specs", "load_imports", "validate_imports", "export_state", "use_explicit_exports", "use_implicit_exports", "merge", "validate_exports", "assemble", "detect_format:ModuleDetectFormat", "parse:ModuleParse", "compile:ModuleCompileTopology", "imports_state:ModuleImportState", "resolve_specs:ModuleResolveImportSpecifiers", "load_imports:ModuleLoadImports", "validate_imports:ModuleValidateImports", "export_state:ModuleExportState", "use_explicit_exports:ModuleUseExplicitExports", "use_implicit_exports:ModuleUseImplicitExports", "merge:ModuleMergeTopology", "validate_exports:ModuleValidateExports", "assemble:ModuleAssembleModule"}
ROOTS == {"detect_format:ModuleDetectFormat", "detect_format", "imports_state", "resolve_specs", "load_imports", "validate_imports", "compile", "export_state", "use_explicit_exports", "use_implicit_exports", "merge", "validate_exports"}
TERMINALS == {"compile:ModuleCompileTopology", "imports_state:ModuleImportState", "resolve_specs:ModuleResolveImportSpecifiers", "load_imports:ModuleLoadImports", "validate_imports:ModuleValidateImports", "export_state:ModuleExportState", "use_explicit_exports:ModuleUseExplicitExports", "use_implicit_exports:ModuleUseImplicitExports", "merge:ModuleMergeTopology", "validate_exports:ModuleValidateExports", "assemble:ModuleAssembleModule"}
FOLD_TARGETS == {}
EFFECTS == {}
DECLARED_EFFECTS == {}
INFERRED_EFFECTS == {}

VARIABLES active, beta1, payloadPresent, consensusReached
vars == <<active, beta1, payloadPresent, consensusReached>>

Max2(a, b) == IF a > b THEN a ELSE b
CanFire(sourceSet) == sourceSet \subseteq active
UpdateActive(sourceSet, targetSet) == (active \ sourceSet) \cup targetSet

Init ==
  /\ active = ROOTS
  /\ beta1 = 0
  /\ payloadPresent = TRUE
  /\ consensusReached = FALSE

Edge_01_PROCESS ==
  /\ CanFire({"detect_format:ModuleDetectFormat"})
  /\ active' = UpdateActive({"detect_format:ModuleDetectFormat"}, {"parse:ModuleParse"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"parse:ModuleParse"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"detect_format"})
  /\ active' = UpdateActive({"detect_format"}, {"compile:ModuleCompileTopology"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"compile:ModuleCompileTopology"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"parse:ModuleParse"})
  /\ active' = UpdateActive({"parse:ModuleParse"}, {"imports_state:ModuleImportState"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"imports_state:ModuleImportState"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"imports_state"})
  /\ active' = UpdateActive({"imports_state"}, {"resolve_specs:ModuleResolveImportSpecifiers"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"resolve_specs:ModuleResolveImportSpecifiers"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"imports_state"})
  /\ active' = UpdateActive({"imports_state"}, {"compile:ModuleCompileTopology"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"compile:ModuleCompileTopology"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"resolve_specs"})
  /\ active' = UpdateActive({"resolve_specs"}, {"load_imports:ModuleLoadImports"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"load_imports:ModuleLoadImports"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"load_imports"})
  /\ active' = UpdateActive({"load_imports"}, {"validate_imports:ModuleValidateImports"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"validate_imports:ModuleValidateImports"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"validate_imports"})
  /\ active' = UpdateActive({"validate_imports"}, {"compile:ModuleCompileTopology"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"compile:ModuleCompileTopology"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"compile"})
  /\ active' = UpdateActive({"compile"}, {"export_state:ModuleExportState"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"export_state:ModuleExportState"} \cap FOLD_TARGETS # {})
Edge_10_PROCESS ==
  /\ CanFire({"export_state"})
  /\ active' = UpdateActive({"export_state"}, {"use_explicit_exports:ModuleUseExplicitExports"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"use_explicit_exports:ModuleUseExplicitExports"} \cap FOLD_TARGETS # {})
Edge_11_PROCESS ==
  /\ CanFire({"export_state"})
  /\ active' = UpdateActive({"export_state"}, {"use_implicit_exports:ModuleUseImplicitExports"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"use_implicit_exports:ModuleUseImplicitExports"} \cap FOLD_TARGETS # {})
Edge_12_PROCESS ==
  /\ CanFire({"use_explicit_exports"})
  /\ active' = UpdateActive({"use_explicit_exports"}, {"merge:ModuleMergeTopology"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"merge:ModuleMergeTopology"} \cap FOLD_TARGETS # {})
Edge_13_PROCESS ==
  /\ CanFire({"use_implicit_exports"})
  /\ active' = UpdateActive({"use_implicit_exports"}, {"merge:ModuleMergeTopology"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"merge:ModuleMergeTopology"} \cap FOLD_TARGETS # {})
Edge_14_PROCESS ==
  /\ CanFire({"merge"})
  /\ active' = UpdateActive({"merge"}, {"validate_exports:ModuleValidateExports"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"validate_exports:ModuleValidateExports"} \cap FOLD_TARGETS # {})
Edge_15_PROCESS ==
  /\ CanFire({"validate_exports"})
  /\ active' = UpdateActive({"validate_exports"}, {"assemble:ModuleAssembleModule"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"assemble:ModuleAssembleModule"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_PROCESS
  \/ Edge_10_PROCESS
  \/ Edge_11_PROCESS
  \/ Edge_12_PROCESS
  \/ Edge_13_PROCESS
  \/ Edge_14_PROCESS
  \/ Edge_15_PROCESS

TypeInvariant ==
  /\ active \subseteq NODES
  /\ beta1 \in Nat
  /\ payloadPresent \in BOOLEAN
  /\ consensusReached \in BOOLEAN

NoLostPayloadInvariant == payloadPresent = TRUE
HasFoldTargets == FOLD_TARGETS # {}
EventuallyTerminal == <> (active \cap TERMINALS # {})
EventuallyConsensus == IF HasFoldTargets THEN <> consensusReached ELSE TRUE
DeadlockFree == []<>(ENABLED Next)

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ WF_vars(Next)

THEOREM Spec => []NoLostPayloadInvariant

=============================================================================
