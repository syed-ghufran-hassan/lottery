;; Simple Lottery Contract

(define-map tickets { player: principal } { amount: uint })
(define-data-var total-tickets uint u0)

;; Constants
(define-constant ticket-price u1000000) ;; 1 STX (1_000_000 microSTX)
(define-constant err-zero-amount (err u100))
(define-constant err-insufficient-payment (err u101))

(define-public (buy-ticket (amount uint))
  (if (is-eq amount u0)
      err-zero-amount
      (let (
            (cost (* amount ticket-price))
           )
        (begin
          ;; Transfer STX from buyer to contract
          (try! (stx-transfer? cost tx-sender (as-contract tx-sender)))

          (let (
                (current (default-to u0
                          (get amount
                            (map-get? tickets { player: tx-sender }))))
               )
            (map-set tickets
              { player: tx-sender }
              { amount: (+ current amount) })

            (var-set total-tickets
              (+ (var-get total-tickets) amount))
          )

          (ok "Ticket purchased")
        )
      )
  )
)

(define-read-only (get-tickets (player principal))
  (default-to u0
    (get amount (map-get? tickets { player })))
)

(define-read-only (get-total-tickets)
  (var-get total-tickets)
)
