------------------------------------------------------------------------
-- The Agda standard library
--
-- Table-related properties
------------------------------------------------------------------------

module Data.Table.Properties where

open import Data.Table
open import Data.Table.Relation.Equality

open import Data.Bool using (true; false; if_then_else_)
import Data.Nat as ℕ
open import Data.Empty using (⊥-elim)
open import Data.Fin using (Fin; suc; zero; _≟_; punchIn)
import Data.Fin.Properties as FP
open import Data.Fin.Permutation as Perm using (Permutation; _⟨$⟩ʳ_; _⟨$⟩ˡ_)
open import Data.List as L using (List; _∷_; [])
open import Data.List.Any using (here; there; index)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.Product as Product using (Σ; ∃; _,_; proj₁; proj₂)
open import Data.Vec as V using (Vec; _∷_; [])
import Data.Vec.Properties as VP
open import Function using (_∘_; flip)
open import Function.Inverse using (Inverse)
open import Relation.Binary.PropositionalEquality as P using (_≡_; _≢_)
open import Relation.Nullary using (yes; no)

module _ {a} {A : Set a} where

  fromList-∈ : ∀ {xs : List A} (i : Fin (L.length xs)) → lookup (fromList xs) i ∈ xs
  fromList-∈ {[]}     ()
  fromList-∈ {x ∷ xs} zero    = here P.refl
  fromList-∈ {x ∷ xs} (suc i) = there (fromList-∈ i)

  index-fromList-∈ : ∀ {xs i} → index (fromList-∈ {xs} i) ≡ i
  index-fromList-∈ {[]}     {()}
  index-fromList-∈ {x ∷ xs} {zero}  = P.refl
  index-fromList-∈ {x ∷ xs} {suc i} = P.cong suc index-fromList-∈

  fromList-index : ∀ {xs} {x : A} (x∈xs : x ∈ xs) → lookup (fromList xs) (index x∈xs) ≡ x
  fromList-index (here px)    = P.sym px
  fromList-index (there x∈xs) = fromList-index x∈xs

  lookup∈ : ∀ {xs : List A} (i : Fin (L.length xs)) → ∃ λ x → x ∈ xs
  lookup∈ i = _ , fromList-∈ i


  -- Isomorphism between tables and vectors.

  ↔Vec : ∀ {n} → Inverse (≡-setoid A n) (P.setoid (Vec A n))
  ↔Vec = record
    { to = record { _⟨$⟩_ = toVec ; cong = VP.tabulate-cong }
    ; from = P.→-to-⟶ fromVec
    ; inverse-of = record
      { left-inverse-of = VP.lookup∘tabulate ∘ lookup
      ; right-inverse-of = VP.tabulate∘lookup
      }
    }


  -- Selecting from any table is the same as selecting from a constant table.

  select-const : ∀ {n} (z : A) (i : Fin n) t → select z i t ≗ select z i (replicate (lookup t i))
  select-const z i t j with j ≟ i
  ... | yes _ = P.refl
  ... | no  _ = P.refl

  -- Selecting an element from a table then looking it up is the same as looking
  -- up the index in the original table

  select-lookup :
    ∀ {n x i} (t : Table A n) →
    lookup (select x i t) i ≡ lookup t i
  select-lookup {i = i} t with i ≟ i
  select-lookup t | yes p = P.refl
  select-lookup t | no ¬p = ⊥-elim (¬p P.refl)

  -- Selecting an element from a table then removing the same element produces a
  -- constant table

  select-remove :
    ∀ {n x} i (t : Table A (ℕ.suc n)) →
    remove i (select x i t) ≗ replicate {n = n} x
  select-remove i t j with punchIn i j ≟ i
  select-remove i t j | yes p = ⊥-elim (FP.punchInᵢ≢i _ _ p)
  select-remove i t j | no ¬p = P.refl

  -- Removing an index 'i' from a table permuted with 'π' is the same as
  -- removing the element, then permuting with 'π' minus 'i'.

  remove-permute :
    ∀ {m n} (π : Permutation (ℕ.suc m) (ℕ.suc n)) i (t : Table A (ℕ.suc n)) →
    remove (π ⟨$⟩ˡ i) (permute π t) ≗ permute (Perm.remove (π ⟨$⟩ˡ i) π) (remove i t)
  remove-permute π i t j = P.cong (lookup t) (Perm.punchIn-permute′ π i j)
