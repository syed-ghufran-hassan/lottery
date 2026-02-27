;; ================================
;; PRODUCTION LOTTERY CONTRACT
;; ================================

;; ---------- CONSTANTS ----------
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-LOTTERY-CLOSED (err u102))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u103))
(define-constant ERR-NO-TICKETS (err u104))
(define-constant ERR-ALREADY-DRAWN (err u105))

(define-constant TICKET-PRICE u1000000) ;; 1 STX (in microSTX)

;; ---------- DATA ----------
(define-data-var contract-owner principal tx-sender)
(define-data-var total-tickets uint u0)
(define-data-var lottery-open bool true)
(define-data-var winner (optional principal) none)

(define-map tickets 
  { player: principal } 
  { amount: uint })

;; ---------- PRIVATE HELPERS ----------
(define-private (is-owner)
  (is-eq tx-sender (var-get contract-owner)))

(define-private (assert-owner)
  (if (is-owner)
      (ok true)
      ERR-NOT-AUTHORIZED))

(define-private (assert-lottery-open)
  (if (var-get lottery-open)
      (ok true)
      ERR-LOTTERY-CLOSED))

;; ---------- PUBLIC FUNCTIONS ----------

;; Buy tickets
(define-public (buy-ticket (amount uint))
  (begin
    (try! (assert-lottery-open))
    
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    ;; Ensure correct STX payment
    (let (
        (required-payment (* amount TICKET-PRICE))
    )
      (try! (stx-transfer? required-payment tx-sender (as-contract tx-sender)))
    )

    (let (
        (current (default-to u0 
                  (get amount (map-get? tickets { player: tx-sender }))))
    )
      (map-set tickets 
        { player: tx-sender } 
        { amount: (+ current amount) })

      (var-set total-tickets 
        (+ (var-get total-tickets) amount))
    )

    (print { event: "ticket-purchased", buyer: tx-sender, amount: amount })

    (ok true)
  )
)

;; Draw winner (owner only)
(define-public (draw-winner (randomness uint))
  (begin
    (try! (assert-owner))
    (try! (assert-lottery-open))
    
    (asserts! (> (var-get total-tickets) u0) ERR-NO-TICKETS)
    (asserts! (is-none (var-get winner)) ERR-ALREADY-DRAWN)

    ;; Deterministic pseudo randomness
    ;; In production use VRF / commit-reveal
    (let (
        (winning-index (mod randomness (var-get total-tickets)))
        (selected (pick-winner winning-index))
    )
      (var-set winner (some selected))
      (var-set lottery-open false)

      (print { event: "winner-selected", winner: selected })

      (ok selected)
    )
  )
)

;; Withdraw funds (owner only)
(define-public (withdraw)
  (begin
    (try! (assert-owner))

    (let (
        (balance (stx-get-balance (as-contract tx-sender)))
    )
      (try! (stx-transfer? balance (as-contract tx-sender) tx-sender))
    )

    (ok true)
  )
)

;; ---------- WINNER SELECTION ----------
;; NOTE: Iterating maps is not possible in Clarity.
;; For production, maintain an indexed list of players.
;; This is simplified placeholder logic.
(define-private (pick-winner (index uint))
  tx-sender ;; Replace with indexed tracking logic
)

;; ---------- READ ONLY ----------

(define-read-only (get-tickets (player principal))
  (default-to u0 (get amount (map-get? tickets { player })))
)

(define-read-only (get-total-tickets)
  (var-get total-tickets)
)

(define-read-only (get-winner)
  (var-get winner)
)

(define-read-only (is-lottery-open)
  (var-get lottery-open)
)
