;; UnionChain - Labor Union Democratic Voting System
;; Version: 1.0.0

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_BALLOT_EXISTS (err u101))
(define-constant ERR_BALLOT_NOT_FOUND (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_CHOICE (err u105))
(define-constant ERR_SELF_REPRESENTATION (err u106))
(define-constant ERR_REPRESENTATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_SENIORITY (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var union-president principal tx-sender)
(define-data-var contract-cycle uint u0)

;; Maps
(define-map Ballots
  { ballot-id: uint }
  {
    title: (string-ascii 50),
    candidates: (list 10 (string-ascii 20)),
    deadline: uint,
    votes-total: uint
  })

(define-map UnionVotes
  { ballot-id: uint, member: principal }
  { candidate: (string-ascii 20), seniority: uint })

(define-map MemberSeniority
  { member: principal }
  { seniority: uint })

(define-map Delegates
  { grantor: principal }
  { delegate: principal })

;; Private Functions
(define-private (is-union-president)
  (is-eq tx-sender (var-get union-president)))

(define-private (check-ballot-exists (ballot-id uint))
  (is-some (map-get? Ballots { ballot-id: ballot-id })))

(define-private (check-voting-open (ballot-id uint))
  (match (map-get? Ballots { ballot-id: ballot-id })
    ballot-data (< (var-get contract-cycle) (get deadline ballot-data))
    false))

(define-private (get-member-seniority (member principal))
  (default-to u1 (get seniority (map-get? MemberSeniority { member: member }))))

(define-private (update-votes-total (ballot-id uint) (seniority uint))
  (match (map-get? Ballots { ballot-id: ballot-id })
    ballot-data (map-set Ballots
                 { ballot-id: ballot-id }
                (merge ballot-data { votes-total: (+ (get votes-total ballot-data) seniority) }))
    false))

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50)))

(define-private (validate-candidates (candidates (list 10 (string-ascii 20))))
  (and 
    (>= (len candidates) u2)
    (<= (len candidates) u10)
    (fold and (map validate-string candidates) true)
  ))

(define-private (validate-seniority-threshold (member principal))
  (> (get-member-seniority member) u0))

;; Public Functions
(define-public (create-ballot (title (string-ascii 50)) (candidates (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-union-president) ERR_UNAUTHORIZED)
    (asserts! (validate-string title) ERR_INVALID_INPUT)
    (asserts! (validate-candidates candidates) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (ballot-id (+ u1 (default-to u0 (get votes-total (map-get? Ballots { ballot-id: u0 })))))
        (current-cycle (var-get contract-cycle))
      )
      (asserts! (not (check-ballot-exists ballot-id)) ERR_BALLOT_EXISTS)
      (ok (map-set Ballots
            { ballot-id: ballot-id }
            {
              title: title,
              candidates: candidates,
              deadline: (+ current-cycle duration),
              votes-total: u0
            }))
    )
  ))

(define-public (cast-union-vote (ballot-id uint) (candidate (string-ascii 20)))
  (let 
    (
      (member-seniority (get-member-seniority tx-sender))
      (ballot (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND))
    )
    (asserts! (check-voting-open ballot-id) ERR_VOTING_ENDED)
    (asserts! (is-some (index-of (get candidates ballot) candidate)) ERR_INVALID_CHOICE)
    (asserts! (is-none (map-get? UnionVotes { ballot-id: ballot-id, member: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (validate-seniority-threshold tx-sender) ERR_NOT_ENOUGH_SENIORITY)
    (map-set UnionVotes
      { ballot-id: ballot-id, member: tx-sender }
      { candidate: candidate, seniority: member-seniority })
    (update-votes-total ballot-id member-seniority)
    (ok true)
  ))

(define-public (assign-delegate (delegate principal))
  (begin
    (asserts! (not (is-eq tx-sender delegate)) ERR_SELF_REPRESENTATION)
    (asserts! (is-none (map-get? Delegates { grantor: delegate })) ERR_REPRESENTATION_CYCLE)
    (map-set Delegates { grantor: tx-sender } { delegate: delegate })
    (map-set MemberSeniority
      { member: delegate }
      { seniority: (+ (get-member-seniority delegate) (get-member-seniority tx-sender)) })
    (map-delete MemberSeniority { member: tx-sender })
    (ok true)
  ))

(define-public (close-ballot (ballot-id uint))
  (begin
    (asserts! (is-union-president) ERR_UNAUTHORIZED)
    (asserts! (check-ballot-exists ballot-id) ERR_BALLOT_NOT_FOUND)
    (let ((ballot (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND)))
      (ok (map-set Ballots
            { ballot-id: ballot-id }
            (merge ballot { deadline: (var-get contract-cycle) })))
    )
  ))

(define-public (advance-contract-cycle)
  (begin
    (asserts! (is-union-president) ERR_UNAUTHORIZED)
    (ok (var-set contract-cycle (+ (var-get contract-cycle) u1)))
  ))

;; Read-Only Functions
(define-read-only (get-ballot-votes-total (ballot-id uint))
  (ok (get votes-total (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND))))

(define-read-only (get-member-seniority-level (member principal))
  (ok (get-member-seniority member)))

(define-read-only (get-ballot-status (ballot-id uint))
  (let ((ballot (unwrap! (map-get? Ballots { ballot-id: ballot-id }) ERR_BALLOT_NOT_FOUND)))
    (ok (< (var-get contract-cycle) (get deadline ballot)))
  ))

(define-read-only (get-current-contract-cycle)
  (ok (var-get contract-cycle)))

(define-read-only (get-union-stats)
  {
    president: (var-get union-president),
    current-cycle: (var-get contract-cycle)
  })