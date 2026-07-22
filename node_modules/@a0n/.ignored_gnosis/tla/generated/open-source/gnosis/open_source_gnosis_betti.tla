------------------------------ MODULE open_source_gnosis_betti ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"source_reader", "strip_comments", "node_lexer", "edge_lexer", "property_lexer", "ast_assembler", "betti_verifier", "verify_result", "verified_compilation", "failed_compilation", "compile_halt", "wasm_emitter", "source_code", "raw_ast", "binary_output"}
ROOTS == {"source_code"}
TERMINALS == {"binary_output", "compile_halt"}
FOLD_TARGETS == {"raw_ast"}
EFFECTS == {"fs.local"}
DECLARED_EFFECTS == {}
INFERRED_EFFECTS == {"fs.local"}
\* EFFECT_NODE source_reader declared={} inferred={"fs.local"}

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
  /\ CanFire({"source_code"})
  /\ active' = UpdateActive({"source_code"}, {"source_reader"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"source_reader"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"source_reader"})
  /\ active' = UpdateActive({"source_reader"}, {"strip_comments"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"strip_comments"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"strip_comments"})
  /\ active' = UpdateActive({"strip_comments"}, {"node_lexer", "edge_lexer", "property_lexer"})
  /\ beta1' = beta1 + (Cardinality({"node_lexer", "edge_lexer", "property_lexer"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"node_lexer", "edge_lexer", "property_lexer"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"node_lexer", "edge_lexer", "property_lexer"})
  /\ active' = UpdateActive({"node_lexer", "edge_lexer", "property_lexer"}, {"raw_ast"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"raw_ast"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"raw_ast"})
  /\ active' = UpdateActive({"raw_ast"}, {"ast_assembler"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ast_assembler"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"ast_assembler"})
  /\ active' = UpdateActive({"ast_assembler"}, {"betti_verifier"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"betti_verifier"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"betti_verifier"})
  /\ active' = UpdateActive({"betti_verifier"}, {"verify_result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verify_result"} \cap FOLD_TARGETS # {})
Edge_08_PROCESS ==
  /\ CanFire({"verify_result"})
  /\ active' = UpdateActive({"verify_result"}, {"verified_compilation"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verified_compilation"} \cap FOLD_TARGETS # {})
Edge_09_PROCESS ==
  /\ CanFire({"verified_compilation"})
  /\ active' = UpdateActive({"verified_compilation"}, {"wasm_emitter"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"wasm_emitter"} \cap FOLD_TARGETS # {})
Edge_10_PROCESS ==
  /\ CanFire({"wasm_emitter"})
  /\ active' = UpdateActive({"wasm_emitter"}, {"binary_output"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"binary_output"} \cap FOLD_TARGETS # {})
Edge_11_PROCESS ==
  /\ CanFire({"verify_result"})
  /\ active' = UpdateActive({"verify_result"}, {"failed_compilation"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"failed_compilation"} \cap FOLD_TARGETS # {})
Edge_12_HALT ==
  /\ CanFire({"failed_compilation"})
  /\ active' = UpdateActive({"failed_compilation"}, {"compile_halt"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"compile_halt"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_FORK
  \/ Edge_04_FOLD
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS
  \/ Edge_08_PROCESS
  \/ Edge_09_PROCESS
  \/ Edge_10_PROCESS
  \/ Edge_11_PROCESS
  \/ Edge_12_HALT

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
