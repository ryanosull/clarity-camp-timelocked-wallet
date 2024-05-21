
;; title: timelocked-wallet
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;




;; constants

;; Owner
(define-constant contract-owner tx-sender)

;; Errors
(define-constant err-owner-only (err u100))
(define-constant err-already-locked (err u101))
(define-constant err-unlock-in-past (err u102))
(define-constant err-no-value (err u103))
(define-constant err-beneficiary-only (err u104))
(define-constant err-unlock-height-not-reached (err u105))






;; data vars

;; Data
(define-data-var beneficiary (optional principal) none) ;; One side-note to keep in mind is that the principal is stored as an (optional principal).
;; We thus need to wrap the tx-sender in a (some ...) before we do the comparison.
(define-data-var unlock-height uint u0)



;; data maps
;;

;; public functions
;;

(define-public (lock (new-beneficiary principal) (unlock-at uint) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (var-get beneficiary)) err-already-locked)
        (asserts! (> unlock-at block-height) err-unlock-in-past)
        (asserts! (> amount u0) err-no-value)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender))) ;; gives us the principal of the contract
        (var-set beneficiary (some new-beneficiary)) ;; #[allow(unchecked_data)] <- place me above this line
        (var-set unlock-height unlock-at)
        (ok true)
    )
)


(define-public (bestow (new-beneficiary principal))
    (begin
        (asserts! (is-eq (some tx-sender) (var-get beneficiary)) err-beneficiary-only) ;; principal is (optional), thus we wrap tx-sender in (some...)
        (var-set beneficiary (some new-beneficiary))
        (ok true)
    )
)


(define-public (claim)
    (begin
        (asserts! (is-eq (some tx-sender) (var-get beneficiary)) err-beneficiary-only)
        (asserts! (>= block-height (var-get unlock-height)) err-unlock-height-not-reached)
        (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender (unwrap-panic (var-get beneficiary))))
    )
)

;; read only functions
;;

;; private functions
;;

