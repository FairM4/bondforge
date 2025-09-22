;; BondForge - Tokenized Debt & Lending Contract

;; Error constants
(define-constant err-bond-not-found (err u100))
(define-constant err-bond-already-accepted (err u101))
(define-constant err-bond-not-found-repay (err u102))
(define-constant err-not-borrower (err u103))
(define-constant err-deadline-passed (err u104))
(define-constant err-bond-not-found-default (err u105))
(define-constant err-deadline-not-passed (err u106))
(define-constant err-already-repaid (err u107))
(define-constant err-not-lender (err u108))
(define-constant err-transfer-failed (err u109))
(define-constant err-invalid-amount (err u110))
(define-constant err-invalid-deadline (err u111))

;; Data variables
(define-data-var bond-counter uint u0)

;; Data maps
(define-map bonds
  {id: uint}
  {lender: principal,
   borrower: (optional principal),
   amount: uint,
   interest: uint,
   collateral: uint,
   deadline: uint,
   repaid: bool,
   defaulted: bool})

;; ---------------------------------------
;; PUBLIC: Create bond offer as a lender
;; ---------------------------------------
(define-public (create-bond (amount uint) (interest uint) (collateral uint) (deadline uint))
  (let 
    ((id (var-get bond-counter)))
    ;; Validate inputs
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= interest u0) err-invalid-amount)
    (asserts! (>= collateral u0) err-invalid-amount)
    (asserts! (> deadline stacks-block-height) err-invalid-deadline)
    
    ;; Increment counter
    (var-set bond-counter (+ id u1))
    
    ;; Create bond
    (map-set bonds {id: id}
      {lender: tx-sender,
       borrower: none,
       amount: amount,
       interest: interest,
       collateral: collateral,
       deadline: deadline,
       repaid: false,
       defaulted: false})
    (ok id)))

;; ---------------------------------------
;; PUBLIC: Accept a bond as borrower
;; ---------------------------------------
(define-public (accept-bond (id uint))
  (let 
    ((bond-counter-val (var-get bond-counter)))
    ;; Validate id
    (asserts! (< id bond-counter-val) err-bond-not-found)
    (let 
      ((bond (unwrap! (map-get? bonds {id: id}) err-bond-not-found)))
      ;; Check if bond is available
      (asserts! (is-eq (get borrower bond) none) err-bond-already-accepted)
      (asserts! (is-eq (get repaid bond) false) err-already-repaid)
      (asserts! (is-eq (get defaulted bond) false) err-already-repaid)
      
      ;; Transfer collateral from borrower to contract
      (try! (stx-transfer? (get collateral bond) tx-sender (as-contract tx-sender)))
      
      ;; Transfer loan amount from lender to borrower
      (try! (as-contract (stx-transfer? (get amount bond) tx-sender (get lender bond))))
      
      ;; Update bond with borrower
      (map-set bonds {id: id}
        (merge bond {borrower: (some tx-sender)}))
      (ok true))))

;; ---------------------------------------
;; PUBLIC: Repay a bond
;; ---------------------------------------
(define-public (repay-bond (id uint))
  (let 
    ((bond-counter-val (var-get bond-counter)))
    ;; Validate id
    (asserts! (< id bond-counter-val) err-bond-not-found-repay)
    (let 
      ((bond (unwrap! (map-get? bonds {id: id}) err-bond-not-found-repay)))
      ;; Validate borrower and conditions
      (asserts! (is-eq (unwrap! (get borrower bond) err-not-borrower) tx-sender) err-not-borrower)
      (asserts! (<= stacks-block-height (get deadline bond)) err-deadline-passed)
      (asserts! (is-eq (get repaid bond) false) err-already-repaid)
      (asserts! (is-eq (get defaulted bond) false) err-already-repaid)
      
      ;; Transfer repayment (principal + interest) from borrower to lender
      (try! (stx-transfer? (+ (get amount bond) (get interest bond)) tx-sender (get lender bond)))
      
      ;; Return collateral from contract to borrower
      (try! (as-contract (stx-transfer? (get collateral bond) tx-sender (unwrap! (get borrower bond) err-not-borrower))))
      
      ;; Mark bond as repaid
      (map-set bonds {id: id}
        (merge bond {repaid: true}))
      (ok true))))

;; ---------------------------------------
;; PUBLIC: Mark default and claim collateral
;; ---------------------------------------
(define-public (mark-default (id uint))
  (let 
    ((bond-counter-val (var-get bond-counter)))
    ;; Validate id
    (asserts! (< id bond-counter-val) err-bond-not-found-default)
    (let 
      ((bond (unwrap! (map-get? bonds {id: id}) err-bond-not-found-default)))
      ;; Validate conditions for default
      (asserts! (> stacks-block-height (get deadline bond)) err-deadline-not-passed)
      (asserts! (is-eq (get repaid bond) false) err-already-repaid)
      (asserts! (is-eq (get defaulted bond) false) err-already-repaid)
      (asserts! (is-eq tx-sender (get lender bond)) err-not-lender)
      (asserts! (is-some (get borrower bond)) err-bond-not-found)
      
      ;; Transfer collateral from contract to lender
      (try! (as-contract (stx-transfer? (get collateral bond) tx-sender (get lender bond))))
      
      ;; Mark bond as defaulted
      (map-set bonds {id: id}
        (merge bond {defaulted: true}))
      (ok true))))

;; ---------------------------------------
;; READ-ONLY: Get bond details
;; ---------------------------------------
(define-read-only (get-bond (id uint))
  (map-get? bonds {id: id}))

(define-read-only (get-bond-counter)
  (var-get bond-counter))

;; ---------------------------------------
;; READ-ONLY: Check bond status
;; ---------------------------------------
(define-read-only (is-bond-available (id uint))
  (match (map-get? bonds {id: id})
    bond (and 
           (is-none (get borrower bond))
           (is-eq (get repaid bond) false)
           (is-eq (get defaulted bond) false))
    false))

(define-read-only (is-bond-active (id uint))
  (match (map-get? bonds {id: id})
    bond (and 
           (is-some (get borrower bond))
           (is-eq (get repaid bond) false)
           (is-eq (get defaulted bond) false)
           (<= stacks-block-height (get deadline bond)))
    false))

(define-read-only (is-bond-defaultable (id uint))
  (match (map-get? bonds {id: id})
    bond (and 
           (is-some (get borrower bond))
           (is-eq (get repaid bond) false)
           (is-eq (get defaulted bond) false)
           (> stacks-block-height (get deadline bond)))
    false))
