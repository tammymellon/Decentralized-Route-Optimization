;; title: Decentralized-Route-Optimization
;; version: 1.0.0
;; summary: A decentralized route optimization system that rewards drivers for efficient routes
;; description: Drivers submit route data and earn micro-tokens based on route efficiency

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-ROUTE (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-UNAUTHORIZED (err u105))

(define-constant MIN-DISTANCE u1)
(define-constant MAX-DISTANCE u10000)
(define-constant MIN-TIME u1)
(define-constant MAX-TIME u14400)
(define-constant BASE-REWARD u100)
(define-constant EFFICIENCY-MULTIPLIER u10)

;; data vars
(define-data-var total-routes uint u0)
(define-data-var total-drivers uint u0)
(define-data-var reward-pool uint u1000000)
(define-data-var next-route-id uint u1)

;; data maps
(define-map drivers
    principal
    {
        registered-at: uint,
        total-routes: uint,
        efficiency-score: uint,
        total-rewards: uint,
        reputation: uint
    }
)

(define-map routes
    uint
    {
        driver: principal,
        start-lat: int,
        start-lng: int,
        end-lat: int,
        end-lng: int,
        distance: uint,
        time-taken: uint,
        fuel-used: uint,
        traffic-conditions: uint,
        timestamp: uint,
        efficiency-score: uint,
        reward-earned: uint
    }
)

(define-map route-feedback
    uint
    {
        upvotes: uint,
        downvotes: uint,
        feedback-count: uint
    }
)

(define-map driver-balances
    principal
    uint
)

(define-map route-history
    principal
    (list 100 uint)
)

;; public functions
(define-public (register-driver)
    (let 
        (
            (caller tx-sender)
            (current-block stacks-block-height)
        )
        (asserts! (is-none (map-get? drivers caller)) ERR-ALREADY-EXISTS)
        (map-set drivers caller
            {
                registered-at: current-block,
                total-routes: u0,
                efficiency-score: u0,
                total-rewards: u0,
                reputation: u1000
            }
        )
        (map-set driver-balances caller u0)
        (var-set total-drivers (+ (var-get total-drivers) u1))
        (ok true)
    )
)

(define-public (submit-route 
    (start-lat int) 
    (start-lng int) 
    (end-lat int) 
    (end-lng int)
    (distance uint)
    (time-taken uint)
    (fuel-used uint)
    (traffic-conditions uint)
    )
    (let 
        (
            (caller tx-sender)
            (route-id (var-get next-route-id))
            (current-block stacks-block-height)
            (driver-info (unwrap! (map-get? drivers caller) ERR-NOT-FOUND))
            (efficiency (calculate-efficiency distance time-taken fuel-used traffic-conditions))
            (reward (calculate-reward efficiency))
        )
        (asserts! (>= distance MIN-DISTANCE) ERR-INVALID-ROUTE)
        (asserts! (<= distance MAX-DISTANCE) ERR-INVALID-ROUTE)
        (asserts! (>= time-taken MIN-TIME) ERR-INVALID-ROUTE)
        (asserts! (<= time-taken MAX-TIME) ERR-INVALID-ROUTE)
        
        (map-set routes route-id
            {
                driver: caller,
                start-lat: start-lat,
                start-lng: start-lng,
                end-lat: end-lat,
                end-lng: end-lng,
                distance: distance,
                time-taken: time-taken,
                fuel-used: fuel-used,
                traffic-conditions: traffic-conditions,
                timestamp: current-block,
                efficiency-score: efficiency,
                reward-earned: reward
            }
        )
        
        (map-set route-feedback route-id
            {
                upvotes: u0,
                downvotes: u0,
                feedback-count: u0
            }
        )
        
        (map-set drivers caller
            (merge driver-info
                {
                    total-routes: (+ (get total-routes driver-info) u1),
                    efficiency-score: (/ (+ (* (get efficiency-score driver-info) (get total-routes driver-info)) efficiency) (+ (get total-routes driver-info) u1)),
                    total-rewards: (+ (get total-rewards driver-info) reward)
                }
            )
        )
        
        (map-set driver-balances caller 
            (+ (default-to u0 (map-get? driver-balances caller)) reward)
        )
        
        (let ((current-history (default-to (list) (map-get? route-history caller))))
            (map-set route-history caller 
                (unwrap! (as-max-len? (append current-history route-id) u100) ERR-INVALID-ROUTE)
            )
        )
        
        (var-set next-route-id (+ route-id u1))
        (var-set total-routes (+ (var-get total-routes) u1))
        (var-set reward-pool (- (var-get reward-pool) reward))
        
        (ok route-id)
    )
)

(define-public (vote-route (route-id uint) (upvote bool))
    (let 
        (
            (caller tx-sender)
            (route-data (unwrap! (map-get? routes route-id) ERR-NOT-FOUND))
            (feedback-data (unwrap! (map-get? route-feedback route-id) ERR-NOT-FOUND))
            (driver-info (unwrap! (map-get? drivers (get driver route-data)) ERR-NOT-FOUND))
        )
        (asserts! (not (is-eq caller (get driver route-data))) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? drivers caller)) ERR-NOT-FOUND)
        
        (if upvote
            (map-set route-feedback route-id
                (merge feedback-data
                    {
                        upvotes: (+ (get upvotes feedback-data) u1),
                        feedback-count: (+ (get feedback-count feedback-data) u1)
                    }
                )
            )
            (map-set route-feedback route-id
                (merge feedback-data
                    {
                        downvotes: (+ (get downvotes feedback-data) u1),
                        feedback-count: (+ (get feedback-count feedback-data) u1)
                    }
                )
            )
        )
        
        (let ((reputation-change (if upvote u10 (- u0 u5))))
            (map-set drivers (get driver route-data)
                (merge driver-info
                    {
                        reputation: (+ (get reputation driver-info) reputation-change)
                    }
                )
            )
        )
        
        (ok true)
    )
)

(define-public (withdraw-rewards (amount uint))
    (let 
        (
            (caller tx-sender)
            (balance (default-to u0 (map-get? driver-balances caller)))
        )
        (asserts! (is-some (map-get? drivers caller)) ERR-NOT-FOUND)
        (asserts! (>= balance amount) ERR-INSUFFICIENT-BALANCE)
        
        (map-set driver-balances caller (- balance amount))
        (ok amount)
    )
)

(define-public (add-to-reward-pool (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set reward-pool (+ (var-get reward-pool) amount))
        (ok true)
    )
)

;; read only functions
(define-read-only (get-driver-info (driver principal))
    (map-get? drivers driver)
)

(define-read-only (get-route-info (route-id uint))
    (map-get? routes route-id)
)

(define-read-only (get-route-feedback (route-id uint))
    (map-get? route-feedback route-id)
)

(define-read-only (get-driver-balance (driver principal))
    (default-to u0 (map-get? driver-balances driver))
)

(define-read-only (get-driver-routes (driver principal))
    (default-to (list) (map-get? route-history driver))
)

(define-read-only (get-total-stats)
    {
        total-routes: (var-get total-routes),
        total-drivers: (var-get total-drivers),
        reward-pool: (var-get reward-pool),
        next-route-id: (var-get next-route-id)
    }
)

(define-read-only (get-top-drivers)
    (ok "Top drivers functionality would require additional indexing")
)

(define-read-only (calculate-efficiency (distance uint) (time-taken uint) (fuel-used uint) (traffic-conditions uint))
    (let 
        (
            (speed-score (/ (* distance u3600) time-taken))
            (fuel-efficiency (/ distance (+ fuel-used u1)))
            (traffic-bonus (- u100 traffic-conditions))
        )
        (/ (+ speed-score fuel-efficiency traffic-bonus) u3)
    )
)

(define-read-only (calculate-reward (efficiency uint))
    (+ BASE-REWARD (* efficiency EFFICIENCY-MULTIPLIER))
)

(define-read-only (get-route-efficiency-ranking (route-id uint))
    (let 
        (
            (route-data (unwrap! (map-get? routes route-id) ERR-NOT-FOUND))
        )
        (ok (get efficiency-score route-data))
    )
)

;; private functions
(define-private (is-valid-coordinates (lat int) (lng int))
    (and 
        (>= lat -90000000)
        (<= lat 90000000)
        (>= lng -180000000)
        (<= lng 180000000)
    )
)
