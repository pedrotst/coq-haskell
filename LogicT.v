Require Export Iso.
Require Export Monad.

Inductive LogicT (M : Type -> Type) `{Monad M} (A : Type) :=
  LogicT_ : forall {R : Type}, ((A -> M R -> M R) -> M R -> M R) -> LogicT M A.

Inductive LogicT' (M : Type -> Type) `{Monad M} (A : Type) :=
  LogicT_' : forall {R : Type}, ((A -> R -> M R) -> R -> M R) -> LogicT' M A.

Definition fromLogicT (M : Type -> Type) `{Monad M} (A : Type)
  (l : LogicT M A) : LogicT' M A :=
  match l with
    LogicT_ _ await =>
      LogicT_' M A (fun yield =>
        await (compose (join/M) ∘ (@fmap M _ _ _) ∘ yield) ∘ pure)
  end.

Definition toLogicT (M : Type -> Type) `{Monad M} (A : Type)
  (l : LogicT' M A) : LogicT M A :=
  match l with
    LogicT_' _ await =>
      LogicT_ M A (fun yield => join ∘ fmap (await (fun x => yield x ∘ pure)))
  end.

(* The condition J2 was given by Jones and Duponcheel as a condition in their
   treatment of "compatible" monads.  I'm not yet certain what part it plays
   here.
*)
Global Instance LogicT_Restricted_Isomorphism
  (M : Type -> Type) `{Monad M} (A : Type)
  (J2 : forall A B (f : M A -> M B), join ∘ fmap f = f ∘ join)
  : LogicT' M A ≅ LogicT M A :=
{ to   := toLogicT M A
; from := fromLogicT M A
}.
Proof.
  intros.
  - extensionality x.
    unfold id.
    destruct x.
    unfold compose.
    simpl. f_equal.
    unfold flip, bind.
    extensionality p. extensionality q.
    unfold compose.
    rewrite <- app_fmap_compose_x.
    rewrite monad_law_3_x.
    f_equal.
    extensionality p0. extensionality q0.
    unfold compose.
    rewrite <- app_fmap_compose_x.
    rewrite monad_law_3_x.
    reflexivity.
  - extensionality x.
    unfold id. destruct x.
    unfold compose. simpl.
    unfold compose at 5.
    f_equal. extensionality x.
    rewrite <- fun_composition.
    rewrite comp_assoc.
    rewrite J2.
    rewrite <- comp_assoc.
    rewrite monad_law_2.
    rewrite comp_id_right.
    f_equal. extensionality y.
    unfold compose at 2.
    unfold compose at 1.
    extensionality x0.
    assert ((join/M) ((fmap[M] (x y ∘ pure/M)) x0) =
            (join/M ∘ fmap[M] (x y ∘ pure/M)) x0).
      auto. rewrite H0. clear H0.
    rewrite <- fun_composition.
    rewrite comp_assoc.
    rewrite J2.
    rewrite <- comp_assoc.
    rewrite monad_law_2.
    reflexivity.
Defined.
