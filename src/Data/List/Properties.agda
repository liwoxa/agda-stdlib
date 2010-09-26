------------------------------------------------------------------------
-- List-related properties
------------------------------------------------------------------------

{-# OPTIONS --universe-polymorphism #-}

-- Note that the lemmas below could be generalised to work with other
-- equalities than _≡_.

module Data.List.Properties where

open import Algebra
open import Category.Monad
open import Data.List as List
open import Data.Nat
open import Data.Nat.Properties
open import Data.Bool
open import Function
open import Data.Product as Prod hiding (map)
open import Data.Maybe
open import Relation.Binary.PropositionalEquality as P
  using (_≡_; _≢_; _≗_; refl)
import Relation.Binary.EqReasoning as EqR

open RawMonadPlus List.monadPlus
private
  module LM {a} {A : Set a} = Monoid (List.monoid A)

∷-injective : ∀ {a} {A : Set a} {x y xs ys} →
              (x ∷ xs ∶ List A) ≡ y ∷ ys → x ≡ y × xs ≡ ys
∷-injective refl = (refl , refl)

∷ʳ-injective : ∀ {a} {A : Set a} {x y} xs ys →
               (xs ∷ʳ x ∶ List A) ≡ ys ∷ʳ y → xs ≡ ys × x ≡ y
∷ʳ-injective []          []          refl = (refl , refl)
∷ʳ-injective (x ∷ xs)    (y  ∷ ys)   eq   with ∷-injective eq
∷ʳ-injective (x ∷ xs)    (.x ∷ ys)   eq   | (refl , eq′) =
  Prod.map (P.cong (_∷_ x)) id $ ∷ʳ-injective xs ys eq′

∷ʳ-injective []          (_ ∷ [])    ()
∷ʳ-injective []          (_ ∷ _ ∷ _) ()
∷ʳ-injective (_ ∷ [])    []          ()
∷ʳ-injective (_ ∷ _ ∷ _) []          ()

right-identity-unique : ∀ {a} {A : Set a} (xs : List A) {ys} →
                        xs ≡ xs ++ ys → ys ≡ []
right-identity-unique []       refl = refl
right-identity-unique (x ∷ xs) eq   =
  right-identity-unique xs (proj₂ (∷-injective eq))

left-identity-unique : ∀ {A : Set} {xs} (ys : List A) →
                       xs ≡ ys ++ xs → ys ≡ []
left-identity-unique               []       _  = refl
left-identity-unique {xs = []}     (y ∷ ys) ()
left-identity-unique {xs = x ∷ xs} (y ∷ ys) eq
  with left-identity-unique (ys ++ [ x ]) (begin
         xs                  ≡⟨ proj₂ (∷-injective eq) ⟩
         ys ++ x ∷ xs        ≡⟨ P.sym (LM.assoc ys [ x ] xs) ⟩
         (ys ++ [ x ]) ++ xs ∎)
  where open P.≡-Reasoning
left-identity-unique {xs = x ∷ xs} (y ∷ []   ) eq | ()
left-identity-unique {xs = x ∷ xs} (y ∷ _ ∷ _) eq | ()

-- Map, sum, and append.

map-++-commute : ∀ {a b} {A : Set a} {B : Set b} (f : A → B) xs ys →
                 map f (xs ++ ys) ≡ map f xs ++ map f ys
map-++-commute f []       ys = refl
map-++-commute f (x ∷ xs) ys =
  P.cong (_∷_ (f x)) (map-++-commute f xs ys)

sum-++-commute : ∀ xs ys → sum (xs ++ ys) ≡ sum xs + sum ys
sum-++-commute []       ys = refl
sum-++-commute (x ∷ xs) ys = begin
  x + sum (xs ++ ys)
                         ≡⟨ P.cong (_+_ x) (sum-++-commute xs ys) ⟩
  x + (sum xs + sum ys)
                         ≡⟨ P.sym $ +-assoc x _ _ ⟩
  (x + sum xs) + sum ys
                         ∎
  where
  open CommutativeSemiring commutativeSemiring hiding (_+_)
  open P.≡-Reasoning

-- Various properties about folds.

foldr-universal : ∀ {a b} {A : Set a} {B : Set b}
                  (h : List A → B) f e →
                  (h [] ≡ e) →
                  (∀ x xs → h (x ∷ xs) ≡ f x (h xs)) →
                  h ≗ foldr f e
foldr-universal h f e base step []       = base
foldr-universal h f e base step (x ∷ xs) = begin
  h (x ∷ xs)
    ≡⟨ step x xs ⟩
  f x (h xs)
    ≡⟨ P.cong (f x) (foldr-universal h f e base step xs) ⟩
  f x (foldr f e xs)
    ∎
  where open P.≡-Reasoning

foldr-fusion : ∀ {a b c} {A : Set a} {B : Set b} {C : Set c}
               (h : B → C) {f : A → B → B} {g : A → C → C} (e : B) →
               (∀ x y → h (f x y) ≡ g x (h y)) →
               h ∘ foldr f e ≗ foldr g (h e)
foldr-fusion h {f} {g} e fuse =
  foldr-universal (h ∘ foldr f e) g (h e) refl
                  (λ x xs → fuse x (foldr f e xs))

idIsFold : ∀ {a} {A : Set a} → id {A = List A} ≗ foldr _∷_ []
idIsFold = foldr-universal id _∷_ [] refl (λ _ _ → refl)

++IsFold : ∀ {a} {A : Set a} (xs ys : List A) →
           xs ++ ys ≡ foldr _∷_ ys xs
++IsFold xs ys =
  begin
    xs ++ ys
  ≡⟨ P.cong (λ xs → xs ++ ys) (idIsFold xs) ⟩
    foldr _∷_ [] xs ++ ys
  ≡⟨ foldr-fusion (λ xs → xs ++ ys) [] (λ _ _ → refl) xs ⟩
    foldr _∷_ ([] ++ ys) xs
  ≡⟨ refl ⟩
    foldr _∷_ ys xs
  ∎
  where open P.≡-Reasoning

mapIsFold : ∀ {a b} {A : Set a} {B : Set b} {f : A → B} →
            map f ≗ foldr (λ x ys → f x ∷ ys) []
mapIsFold {f = f} =
  begin
    map f
  ≈⟨ P.cong (map f) ∘ idIsFold ⟩
    map f ∘ foldr _∷_ []
  ≈⟨ foldr-fusion (map f) [] (λ _ _ → refl) ⟩
    foldr (λ x ys → f x ∷ ys) []
  ∎
  where open EqR (P._→-setoid_ _ _)

concat-map : ∀ {a b} {A : Set a} {B : Set b} {f : A → B} →
             concat ∘ map (map f) ≗ map f ∘ concat
concat-map {b = b} {f = f} =
  begin
    concat ∘ map (map f)
  ≈⟨ P.cong concat ∘ mapIsFold {b = b} ⟩
    concat ∘ foldr (λ xs ys → map f xs ∷ ys) []
  ≈⟨ foldr-fusion {b = b} concat [] (λ _ _ → refl) ⟩
    foldr (λ ys zs → map f ys ++ zs) []
  ≈⟨ P.sym ∘
     foldr-fusion (map f) [] (λ ys zs → map-++-commute f ys zs) ⟩
    map f ∘ concat
  ∎
  where open EqR (P._→-setoid_ _ _)

map-id : ∀ {a} {A : Set a} → map id ≗ id {A = List A}
map-id {A = A} = begin
  map id        ≈⟨ mapIsFold ⟩
  foldr _∷_ []  ≈⟨ P.sym ∘ idIsFold {A = A} ⟩
  id            ∎
  where open EqR (P._→-setoid_ _ _)

map-compose : ∀ {a b c} {A : Set a} {B : Set b} {C : Set c}
                {g : B → C} {f : A → B} →
              map (g ∘ f) ≗ map g ∘ map f
map-compose {A = A} {B} {g = g} {f} =
  begin
    map (g ∘ f)
  ≈⟨ P.cong (map (g ∘ f)) ∘ idIsFold ⟩
    map (g ∘ f) ∘ foldr _∷_ []
  ≈⟨ foldr-fusion (map (g ∘ f)) [] (λ _ _ → refl) ⟩
    foldr (λ a y → g (f a) ∷ y) []
  ≈⟨ P.sym ∘ foldr-fusion (map g) [] (λ _ _ → refl) ⟩
    map g ∘ foldr (λ a y → f a ∷ y) []
  ≈⟨ P.cong (map g) ∘ P.sym ∘ mapIsFold {A = A} {B = B} ⟩
    map g ∘ map f
  ∎
  where open EqR (P._→-setoid_ _ _)

foldr-cong : ∀ {a b} {A : Set a} {B : Set b}
               {f₁ f₂ : A → B → B} {e₁ e₂ : B} →
             (∀ x y → f₁ x y ≡ f₂ x y) → e₁ ≡ e₂ →
             foldr f₁ e₁ ≗ foldr f₂ e₂
foldr-cong {f₁ = f₁} {f₂} {e} f₁≗₂f₂ refl =
  begin
    foldr f₁ e
  ≈⟨ P.cong (foldr f₁ e) ∘ idIsFold ⟩
    foldr f₁ e ∘ foldr _∷_ []
  ≈⟨ foldr-fusion (foldr f₁ e) [] (λ x xs → f₁≗₂f₂ x (foldr f₁ e xs)) ⟩
    foldr f₂ e
  ∎
  where open EqR (P._→-setoid_ _ _)

map-cong : ∀ {a b} {A : Set a} {B : Set b} {f g : A → B} →
           f ≗ g → map f ≗ map g
map-cong {A = A} {B} {f} {g} f≗g =
  begin
    map f
  ≈⟨ mapIsFold ⟩
    foldr (λ x ys → f x ∷ ys) []
  ≈⟨ foldr-cong (λ x ys → P.cong₂ _∷_ (f≗g x) refl) refl ⟩
    foldr (λ x ys → g x ∷ ys) []
  ≈⟨ P.sym ∘ mapIsFold {A = A} {B = B} ⟩
    map g
  ∎
  where open EqR (P._→-setoid_ _ _)

-- Take, drop, and splitAt.

take++drop : ∀ {a} {A : Set a}
             n (xs : List A) → take n xs ++ drop n xs ≡ xs
take++drop zero    xs       = refl
take++drop (suc n) []       = refl
take++drop (suc n) (x ∷ xs) =
  P.cong (λ xs → x ∷ xs) (take++drop n xs)

splitAt-defn : ∀ {a} {A : Set a} n →
               splitAt {A = A} n ≗ < take n , drop n >
splitAt-defn zero    xs       = refl
splitAt-defn (suc n) []       = refl
splitAt-defn (suc n) (x ∷ xs) with splitAt n xs | splitAt-defn n xs
... | (ys , zs) | ih = P.cong (Prod.map (_∷_ x) id) ih

-- TakeWhile, dropWhile, and span.

takeWhile++dropWhile : ∀ {a} {A : Set a} (p : A → Bool) (xs : List A) →
                       takeWhile p xs ++ dropWhile p xs ≡ xs
takeWhile++dropWhile p []       = refl
takeWhile++dropWhile p (x ∷ xs) with p x
... | true  = P.cong (_∷_ x) (takeWhile++dropWhile p xs)
... | false = refl

span-defn : ∀ {a} {A : Set a} (p : A → Bool) →
            span p ≗ < takeWhile p , dropWhile p >
span-defn p []       = refl
span-defn p (x ∷ xs) with p x
... | true  = P.cong (Prod.map (_∷_ x) id) (span-defn p xs)
... | false = refl

-- Partition.

partition-defn : ∀ {a} {A : Set a} (p : A → Bool) →
                 partition p ≗ < filter p , filter (not ∘ p) >
partition-defn p []       = refl
partition-defn p (x ∷ xs)
 with p x | partition p xs | partition-defn p xs
...  | true  | (ys , zs) | eq = P.cong (Prod.map (_∷_ x) id) eq
...  | false | (ys , zs) | eq = P.cong (Prod.map id (_∷_ x)) eq

-- Inits, tails, and scanr.

scanr-defn : ∀ {a b} {A : Set a} {B : Set b}
             (f : A → B → B) (e : B) →
             scanr f e ≗ map (foldr f e) ∘ tails
scanr-defn f e []             = refl
scanr-defn f e (x ∷ [])       = refl
scanr-defn f e (x₁ ∷ x₂ ∷ xs)
  with scanr f e (x₂ ∷ xs) | scanr-defn f e (x₂ ∷ xs)
...  | [] | ()
...  | y ∷ ys | eq with ∷-injective eq
...        | y≡fx₂⦇f⦈xs , _ = P.cong₂ (λ z zs → f x₁ z ∷ zs) y≡fx₂⦇f⦈xs eq

scanl-defn : ∀ {a b} {A : Set a} {B : Set b}
             (f : A → B → A) (e : A) →
             scanl f e ≗ map (foldl f e) ∘ inits
scanl-defn f e []       = refl
scanl-defn f e (x ∷ xs) = P.cong (_∷_ e) (begin
     scanl f (f e x) xs
  ≡⟨ scanl-defn f (f e x) xs ⟩
     map (foldl f (f e x)) (inits xs)
  ≡⟨ refl ⟩
     map (foldl f e ∘ (_∷_ x)) (inits xs)
  ≡⟨ map-compose (inits xs) ⟩
     map (foldl f e) (map (_∷_ x) (inits xs))
  ∎)
  where open P.≡-Reasoning

-- Length.

length-map : ∀ {a b} {A : Set a} {B : Set b} (f : A → B) xs →
             length (map f xs) ≡ length xs
length-map f []       = refl
length-map f (x ∷ xs) = P.cong suc (length-map f xs)

length-++ : ∀ {a} {A : Set a} (xs : List A) {ys} →
            length (xs ++ ys) ≡ length xs + length ys
length-++ []       = refl
length-++ (x ∷ xs) = P.cong suc (length-++ xs)

length-gfilter : ∀ {a b} {A : Set a} {B : Set b} (p : A → Maybe B) xs →
                 length (gfilter p xs) ≤ length xs
length-gfilter p []       = z≤n
length-gfilter p (x ∷ xs) with p x
length-gfilter p (x ∷ xs) | just y  = s≤s (length-gfilter p xs)
length-gfilter p (x ∷ xs) | nothing = ≤-step (length-gfilter p xs)

-- The list monad.

module Monad where

  left-zero : {A B : Set} (f : A → List B) → (∅ >>= f) ≡ ∅
  left-zero f = refl

  right-zero : {A B : Set} (xs : List A) →
               (xs >>= const ∅) ≡ (∅ ∶ List B)
  right-zero []       = refl
  right-zero (x ∷ xs) = right-zero xs

  private

    not-left-distributive :
      let xs = true ∷ false ∷ []; f = return; g = return in
      (xs >>= λ x → f x ∣ g x) ≢ ((xs >>= f) ∣ (xs >>= g))
    not-left-distributive ()

  right-distributive : {A B : Set} (xs ys : List A) (f : A → List B) →
                       (xs ∣ ys >>= f) ≡ ((xs >>= f) ∣ (ys >>= f))
  right-distributive []       ys f = refl
  right-distributive (x ∷ xs) ys f = begin
    f x ∣ (xs ∣ ys >>= f)            ≡⟨ P.cong (_∣_ (f x)) $ right-distributive xs ys f ⟩
    f x ∣ ((xs >>= f) ∣ (ys >>= f))  ≡⟨ P.sym $ LM.assoc (f x) _ _ ⟩
    (f x ∣ (xs >>= f)) ∣ (ys >>= f)  ∎
    where open P.≡-Reasoning

  left-identity : {A B : Set} (x : A) (f : A → List B) →
                  (return x >>= f) ≡ f x
  left-identity x f = proj₂ LM.identity (f x)

  right-identity : {A : Set} (xs : List A) →
                   (xs >>= return) ≡ xs
  right-identity []       = refl
  right-identity (x ∷ xs) = P.cong (_∷_ x) (right-identity xs)

  associative : {A B C : Set}
                (xs : List A) (f : A → List B) (g : B → List C) →
                (xs >>= λ x → f x >>= g) ≡ (xs >>= f >>= g)
  associative []       f g = refl
  associative (x ∷ xs) f g = begin
    (f x >>= g) ∣ (xs >>= λ x → f x >>= g)  ≡⟨ P.cong (_∣_ (f x >>= g)) $ associative xs f g ⟩
    (f x >>= g) ∣ (xs >>= f >>= g)          ≡⟨ P.sym $ right-distributive (f x) (xs >>= f) g ⟩
    (f x ∣ (xs >>= f) >>= g)                ∎
    where open P.≡-Reasoning

  cong : ∀ {A B : Set} {xs₁ xs₂} {f₁ f₂ : A → List B} →
         xs₁ ≡ xs₂ → f₁ ≗ f₂ → (xs₁ >>= f₁) ≡ (xs₂ >>= f₂)
  cong {xs₁ = xs} refl f₁≗f₂ = P.cong concat (map-cong f₁≗f₂ xs)

-- The applicative functor derived from the list monad.

-- Note that these proofs (almost) show that RawIMonad.rawIApplicative
-- is correctly defined. The proofs can be reused if proof components
-- are ever added to RawIMonad and RawIApplicative.

module Applicative where

  open P.≡-Reasoning

  private

    -- A variant of flip map.

    pam : {A B : Set} → List A → (A → B) → List B
    pam xs f = xs >>= return ∘ f

  -- ∅ is a left zero for _⊛_.

  left-zero : ∀ {A B} xs → (∅ ∶ List (A → B)) ⊛ xs ≡ ∅
  left-zero xs = begin
    ∅ ⊛ xs          ≡⟨ refl ⟩
    (∅ >>= pam xs)  ≡⟨ Monad.left-zero (pam xs) ⟩
    ∅               ∎

  -- ∅ is a right zero for _⊛_.

  right-zero : ∀ {A B} (fs : List (A → B)) → fs ⊛ ∅ ≡ ∅
  right-zero fs = begin
    fs ⊛ ∅            ≡⟨ refl ⟩
    (fs >>= pam ∅)    ≡⟨ (Monad.cong (refl {x = fs}) λ f →
                          Monad.left-zero (return ∘ f)) ⟩
    (fs >>= λ _ → ∅)  ≡⟨ Monad.right-zero fs ⟩
    ∅                 ∎

  -- _⊛_ distributes over _∣_ from the right.

  right-distributive :
    ∀ {A B} (fs₁ fs₂ : List (A → B)) xs →
    (fs₁ ∣ fs₂) ⊛ xs ≡ (fs₁ ⊛ xs ∣ fs₂ ⊛ xs)
  right-distributive fs₁ fs₂ xs = begin
    (fs₁ ∣ fs₂) ⊛ xs                     ≡⟨ refl ⟩
    (fs₁ ∣ fs₂ >>= pam xs)               ≡⟨ Monad.right-distributive fs₁ fs₂ (pam xs) ⟩
    (fs₁ >>= pam xs) ∣ (fs₂ >>= pam xs)  ≡⟨ refl ⟩
    fs₁ ⊛ xs ∣ fs₂ ⊛ xs                  ∎

  -- _⊛_ does not distribute over _∣_ from the left.

  private

    not-left-distributive :
      let fs = id ∷ id ∷ []; xs₁ = true ∷ []; xs₂ = true ∷ false ∷ [] in
      fs ⊛ (xs₁ ∣ xs₂) ≢ (fs ⊛ xs₁ ∣ fs ⊛ xs₂)
    not-left-distributive ()

  -- Applicative functor laws.

  identity : ∀ {A} (xs : List A) → return id ⊛ xs ≡ xs
  identity xs = begin
    return id ⊛ xs          ≡⟨ refl ⟩
    (return id >>= pam xs)  ≡⟨ Monad.left-identity id (pam xs) ⟩
    (xs >>= return)         ≡⟨ Monad.right-identity xs ⟩
    xs                      ∎

  private

    pam-lemma : {A B C : Set}
                (xs : List A) (f : A → B) (fs : B → List C) →
                (pam xs f >>= fs) ≡ (xs >>= λ x → fs (f x))
    pam-lemma xs f fs = begin
      (pam xs f >>= fs)                   ≡⟨ P.sym $ Monad.associative xs (return ∘ f) fs ⟩
      (xs >>= λ x → return (f x) >>= fs)  ≡⟨ Monad.cong (refl {x = xs}) (λ x → Monad.left-identity (f x) fs) ⟩
      (xs >>= λ x → fs (f x))             ∎

  composition :
    ∀ {A B C} (fs : List (B → C)) (gs : List (A → B)) xs →
    return _∘′_ ⊛ fs ⊛ gs ⊛ xs ≡ fs ⊛ (gs ⊛ xs)
  composition fs gs xs = begin
    return _∘′_ ⊛ fs ⊛ gs ⊛ xs                      ≡⟨ refl ⟩
    (return _∘′_ >>= pam fs >>= pam gs >>= pam xs)  ≡⟨ Monad.cong (Monad.cong (Monad.left-identity _∘′_ (pam fs))
                                                                              (λ _ → refl))
                                                                  (λ _ → refl) ⟩
    (pam fs _∘′_ >>= pam gs >>= pam xs)             ≡⟨ Monad.cong (pam-lemma fs _∘′_ (pam gs)) (λ _ → refl) ⟩
    ((fs >>= λ f → pam gs (_∘′_ f)) >>= pam xs)     ≡⟨ P.sym $ Monad.associative fs (λ f → pam gs (_∘′_ f)) (pam xs) ⟩
    (fs >>= λ f → pam gs (_∘′_ f) >>= pam xs)       ≡⟨ (Monad.cong (refl {x = fs}) λ f →
                                                        pam-lemma gs (_∘′_ f) (pam xs)) ⟩
    (fs >>= λ f → gs >>= λ g → pam xs (f ∘′ g))     ≡⟨ (Monad.cong (refl {x = fs}) λ f →
                                                        Monad.cong (refl {x = gs}) λ g →
                                                        P.sym $ pam-lemma xs g (return ∘ f)) ⟩
    (fs >>= λ f → gs >>= λ g → pam (pam xs g) f)    ≡⟨ (Monad.cong (refl {x = fs}) λ f →
                                                        Monad.associative gs (pam xs) (return ∘ f)) ⟩
    (fs >>= pam (gs >>= pam xs))                    ≡⟨ refl ⟩
    fs ⊛ (gs ⊛ xs)                                  ∎

  homomorphism : ∀ {A B : Set} (f : A → B) x →
                 return f ⊛ return x ≡ return (f x)
  homomorphism f x = begin
    return f ⊛ return x            ≡⟨ refl ⟩
    (return f >>= pam (return x))  ≡⟨ Monad.left-identity f (pam (return x)) ⟩
    pam (return x) f               ≡⟨ Monad.left-identity x (return ∘ f) ⟩
    return (f x)                   ∎

  interchange : ∀ {A B} (fs : List (A → B)) {x} →
                fs ⊛ return x ≡ return (λ f → f x) ⊛ fs
  interchange fs {x} = begin
    fs ⊛ return x                    ≡⟨ refl ⟩
    (fs >>= pam (return x))          ≡⟨ (Monad.cong (refl {x = fs}) λ f →
                                         Monad.left-identity x (return ∘ f)) ⟩
    (fs >>= λ f → return (f x))      ≡⟨ refl ⟩
    (pam fs (λ f → f x))             ≡⟨ P.sym $ Monad.left-identity (λ f → f x) (pam fs) ⟩
    (return (λ f → f x) >>= pam fs)  ≡⟨ refl ⟩
    return (λ f → f x) ⊛ fs          ∎
