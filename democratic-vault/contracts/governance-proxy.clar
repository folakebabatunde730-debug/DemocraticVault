;; Democratic Vault - Governance Proxy Contract
;; A proxy-based governance system for decentralized decision making

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-PROPOSAL-EXPIRED (err u103))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-IMPLEMENTATION (err u106))
(define-constant ERR-INVALID-INPUT (err u107))
(define-constant ERR-ZERO-AMOUNT (err u108))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Implementation contract address
(define-data-var implementation-contract principal tx-sender)

;; Governance token settings
(define-data-var min-vote-threshold uint u1000)
(define-data-var voting-period uint u1440) ;; blocks (~10 days)

;; Proposal counter
(define-data-var proposal-counter uint u0)

;; Constants for validation
(define-constant MAX-VOTING-PERIOD u14400) ;; ~100 days max
(define-constant MIN-VOTING-PERIOD u144)   ;; ~1 day min
(define-constant MAX-THRESHOLD u100000000) ;; Max threshold
(define-constant MIN-THRESHOLD u1)         ;; Min threshold

;; Proposal structure
(define-map proposals
  uint
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    target-contract: principal,
    function-call: (string-ascii 100),
    votes-for: uint,
    votes-against: uint,
    start-block: uint,
    end-block: uint,
    executed: bool,
    active: bool
  }
)

;; Vote tracking
(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, power: uint }
)

;; Token balances (simplified governance token)
(define-map token-balances principal uint)

;; Total token supply
(define-data-var total-supply uint u1000000)

;; Implementation registry
(define-map implementation-registry
  (string-ascii 50)
  principal
)

;; Initialize contract with initial token distribution
(begin
  (map-set token-balances tx-sender u500000)
  (map-set token-balances 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u300000)
  (map-set token-balances 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE u200000)
)

;; Input validation helpers
(define-private (is-valid-principal (account principal))
  (not (is-eq account 'SP000000000000000000002Q6VF78))
)

(define-private (is-valid-string (str (string-ascii 100)))
  (> (len str) u0)
)

(define-private (is-valid-description (desc (string-ascii 500)))
  (> (len desc) u0)
)

(define-private (is-valid-function-name (fname (string-ascii 100)))
  (> (len fname) u0)
)

(define-private (is-valid-registry-name (name (string-ascii 50)))
  (> (len name) u0)
)

;; Get token balance
(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? token-balances account))
)

;; Transfer tokens (simplified) - with input validation
(define-public (transfer (amount uint) (recipient principal))
  (let (
    (sender-balance (get-balance tx-sender))
  )
    ;; Input validation
    (asserts! (> amount u0) ERR-ZERO-AMOUNT)
    (asserts! (is-valid-principal recipient) ERR-INVALID-INPUT)
    (asserts! (not (is-eq tx-sender recipient)) ERR-INVALID-INPUT)
    (asserts! (>= sender-balance amount) ERR-INSUFFICIENT-BALANCE)
    
    ;; Perform transfer
    (map-set token-balances tx-sender (- sender-balance amount))
    (map-set token-balances recipient (+ (get-balance recipient) amount))
    (ok true)
  )
)

;; Set implementation contract (only owner) - with validation
(define-public (set-implementation (new-implementation principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal new-implementation) ERR-INVALID-INPUT)
    (var-set implementation-contract new-implementation)
    (ok true)
  )
)

;; Register implementation for specific function - with validation
(define-public (register-implementation (function-name (string-ascii 50)) (implementation principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (is-valid-registry-name function-name) ERR-INVALID-INPUT)
    (asserts! (is-valid-principal implementation) ERR-INVALID-INPUT)
    (map-set implementation-registry function-name implementation)
    (ok true)
  )
)

;; Create new proposal - with comprehensive validation
(define-public (create-proposal 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (target-contract principal)
    (function-call (string-ascii 100)))
  (let (
    (proposer-balance (get-balance tx-sender))
    (proposal-id (+ (var-get proposal-counter) u1))
    (current-block block-height)
  )
    ;; Input validation
    (asserts! (is-valid-string title) ERR-INVALID-INPUT)
    (asserts! (is-valid-description description) ERR-INVALID-INPUT)
    (asserts! (is-valid-principal target-contract) ERR-INVALID-INPUT)
    (asserts! (is-valid-function-name function-call) ERR-INVALID-INPUT)
    (asserts! (>= proposer-balance (var-get min-vote-threshold)) ERR-INSUFFICIENT-BALANCE)
    
    (map-set proposals proposal-id {
      proposer: tx-sender,
      title: title,
      description: description,
      target-contract: target-contract,
      function-call: function-call,
      votes-for: u0,
      votes-against: u0,
      start-block: current-block,
      end-block: (+ current-block (var-get voting-period)),
      executed: false,
      active: true
    })
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Vote on proposal
(define-public (vote (proposal-id uint) (support bool))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
    (voter-balance (get-balance tx-sender))
    (current-block block-height)
  )
    ;; Input validation
    (asserts! (> proposal-id u0) ERR-INVALID-INPUT)
    (asserts! (get active proposal) ERR-PROPOSAL-NOT-ACTIVE)
    (asserts! (<= current-block (get end-block proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) ERR-ALREADY-VOTED)
    (asserts! (> voter-balance u0) ERR-INSUFFICIENT-BALANCE)
    
    (map-set votes { proposal-id: proposal-id, voter: tx-sender } 
             { vote: support, power: voter-balance })
    
    (if support
      (map-set proposals proposal-id 
        (merge proposal { votes-for: (+ (get votes-for proposal) voter-balance) }))
      (map-set proposals proposal-id 
        (merge proposal { votes-against: (+ (get votes-against proposal) voter-balance) })))
    
    (ok true)
  )
)

;; Execute proposal (proxy call to implementation)
(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
    (current-block block-height)
  )
    ;; Input validation
    (asserts! (> proposal-id u0) ERR-INVALID-INPUT)
    (asserts! (get active proposal) ERR-PROPOSAL-NOT-ACTIVE)
    (asserts! (> current-block (get end-block proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts! (not (get executed proposal)) ERR-UNAUTHORIZED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR-UNAUTHORIZED)
    
    ;; Mark as executed
    (map-set proposals proposal-id (merge proposal { executed: true }))
    
    ;; Proxy call to implementation (simplified)
    (ok true)
  )
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get vote details
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

;; Check if proposal can be executed
(define-read-only (can-execute (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (and 
      (get active proposal)
      (> block-height (get end-block proposal))
      (not (get executed proposal))
      (> (get votes-for proposal) (get votes-against proposal)))
    false
  )
)

;; Get implementation for function
(define-read-only (get-implementation (function-name (string-ascii 50)))
  (map-get? implementation-registry function-name)
)

;; Administrative functions - with validation
(define-public (set-voting-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (>= new-period MIN-VOTING-PERIOD) ERR-INVALID-INPUT)
    (asserts! (<= new-period MAX-VOTING-PERIOD) ERR-INVALID-INPUT)
    (var-set voting-period new-period)
    (ok true)
  )
)

(define-public (set-min-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (>= new-threshold MIN-THRESHOLD) ERR-INVALID-INPUT)
    (asserts! (<= new-threshold MAX-THRESHOLD) ERR-INVALID-INPUT)
    (var-set min-vote-threshold new-threshold)
    (ok true)
  )
)

;; Deactivate proposal (emergency) - with validation
(define-public (deactivate-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (> proposal-id u0) ERR-INVALID-INPUT)
    (asserts! (get active proposal) ERR-PROPOSAL-NOT-ACTIVE)
    (map-set proposals proposal-id (merge proposal { active: false }))
    (ok true)
  )
)
