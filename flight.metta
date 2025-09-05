; Define types (optional for clarity)
!(bind! &dist-space (new-space))
!(bind! &parent-space (new-space))
!(bind! &pq-space (new-space))
(: flight-route (-> City City Airline Duration Cost Layovers))
(: dist (-> City Number))
(: parent (-> City City))
(: user-preferences (-> User Prioritize Symbol))  ; Symbol is Cost or Duration

; Sample flight data (add more as needed)
!(add-atom &self (flight-route A B AirlineX 3 200 0))
!(add-atom &self (flight-route B C AirlineY 2 150 0))
!(add-atom &self (flight-route A C AirlineZ 5 300 0))
!(add-atom &self (flight-route C D AirlineX 1 100 0))
!(add-atom &self (flight-route A D AirlineY 4 250 0))
!(add-atom &self (flight-route D E AirlineZ 2 180 0))
!(add-atom &self (flight-route B E AirlineX 6 350 0))
!(add-atom &dist-space (dist A 0))  ; Initial distance to start node
!(add-atom &dist-space (dist B 9999))
!(add-atom &dist-space (dist C 9999))
!(add-atom &dist-space (dist D 9999))
!(add-atom &dist-space (dist E 9999))
!(add-atom &pq-space (prio B 0))
!(add-atom &pq-space (prio C 9999))
!(add-atom &pq-space (prio D 9999))
!(add-atom &pq-space (prio E 9999))
!(add-atom &parent-space (parent A ()))  ; Start node has no parent
!(add-atom &parent-space (parent B A))
!(add-atom &parent-space (parent C B))
!(add-atom &parent-space (parent D C))
!(add-atom &parent-space (parent E D))
; Helper: Get all unique nodes
(= (get-nodes)
  (let* (($fr (match &self (flight-route $from $to $a $b $c $d) $from)))
    $fr))

; Initialize distances
(= (set-distance-if-not-start $node $start)
  (if-equal $node $start (add-atom &dist-space (dist $node 0)) (add-atom &dist-space (dist $node 9999))))

(= (initialize-distances $start)
  (let $nodes (get-nodes)
    (map-atom $nodes $x
      (set-distance-if-not-start $x $start))))

; -------- Core Update Functions --------
(= (get-neighbors-with-weight $u $criteria)
  (let $matches (match &self (flight-route $u $v $a $dur $cost $l) (neighbor $v (if-equal $criteria Cost $cost $dur)))
    $matches))

; Update a single neighbor
(= (update-neighbor $u $u-dist (neighbor $v $weight) $dist $parent $pq $criteria $end)
  (let* (($alt (+ $u-dist $weight))
         (() (println! ("Considering neighbor:" $v "with alt distance:" $alt))))
    (let* (($v-dist-atoms (collapse (match $dist (dist $v $d) $d)))
           (() (println! ("Current distance to" $v "is:" $v-dist-atoms)))
           ($v-dist (car-atom $v-dist-atoms))
           ($old-d (if (== $v-dist ()) 9999 $v-dist)))
        (if (< $alt $v-dist)
          (let* ((() (println! ("Updating distance for" $v "from" $old-d "to" $alt)))
                 ($_ (remove-atom $dist (dist $v $v-dist)))
                 ($_ (add-atom $dist (dist $v $alt)))
                 ($_ (add-atom $parent (parent $v $u))))
            (let* (($old-prios (collapse (match $pq (prio $v $old-d) $old-d)))
                    (() (println! ("Old priorities for" $v "are:" $old-prios))))
              (let* (($old-prio (car-atom $old-prios))
                     (() (println! ("Old priority for" $v "was:" $old-prio))))
                (let $_ (if (== $old-prio ())
                           (add-atom $pq (prio $v $alt))
                           (let $_ (remove-atom $pq (prio $v $old-prio))
                             (add-atom $pq (prio $v $alt))))
                  (empty)))))
          (empty)))))

; Update all neighbors
(= (update-neighbors $u $neighbors $u-dist $dist $parent $pq $criteria $end)
  (let $collapsed-neighbors (collapse $neighbors)
    (if (== (size-atom $collapsed-neighbors) 0)
      (empty)
      (let $decons (decons-atom $collapsed-neighbors)
        (let* (($neighbor (car-atom $decons))
               (() (println! ("Processing neighbor:" $neighbor))))
          (let* (($tail (cdr-atom $decons))
                 (() (println! ("Updating neighbor:" $neighbor))))
            (let* (($s (update-neighbor $u $u-dist $neighbor $dist $parent $pq $criteria $end))
                   (() (println! ("Updated neighbor:" $s))))
              (update-neighbors $u $tail $u-dist $dist $parent $pq $criteria $end))))))))

; -------- Dijkstra Core --------
; Find min priority
(= (find-min-prio $atoms $current-min)
  (if (== (size-atom $atoms) 0) $current-min
    (let* (($head (car-atom $atoms))
           (() (println! ("Current head:" $head "Current min:" $current-min "Current atoms:" $atoms))))
      (let $tail (cdr-atom $atoms)
        (if (== (size-atom $tail) 0) $current-min
          (let $head-dist (index-atom $head 2)
            (let $current-dist (index-atom $current-min 2)
              (let $next-min (if (< $head-dist $current-dist) $head $current-min)
                (find-min-prio $tail $next-min)))))))))

; Main loop
(= (dijkstra-loop $pq $dist $parent $criteria $end)
  (let $pq-atom (get-atoms $pq)
    (let $pq-atoms (collapse $pq-atom)
      (if (== (size-atom $pq-atoms) 0)
        (empty)
        (let $initial (car-atom $pq-atoms)
          (if (== $initial ())
            (empty)
            (let $min-prio (find-min-prio $pq-atoms $initial)
              (let $u (index-atom $min-prio 1)
                (let $u-dist (index-atom $min-prio 2)
                  (let $_ (remove-atom $pq $min-prio)
                    (if (== $u $end)
                      (done)
                      (let* (($x (update-neighbors $u (get-neighbors-with-weight $u $criteria) $u-dist $dist $parent $pq $criteria $end))
                             (() (println! ("Updated neighbors for" $u "to" $x))))
                        (dijkstra-loop $pq $dist $parent $criteria $end)))))))))))))

; -------- Path Rebuild --------
(= (reconstruct-path $parent $current $start $acc)
  (if (== $current $start)
    (cons-atom $current $acc)
    (let $par (match $parent (parent $current $p) $p)
      (if (== $par ())
        ()
        (reconstruct-path $parent $par $start (cons-atom $current $acc))))))

; Compute weight
(= (compute-total-weight $path $criteria $acc)
  (if (== (size-atom $path) 0)
    $acc
    (let* (($head (car-atom $path))
           (() (println! ("Current path head:" $head "Current acc:" $acc))))
      (let $tail (cdr-atom $path)
        (let $next (car-atom $tail)
          (let $edge-atoms (match &self (flight-route $head $next $x $dur $cost $y) (if (== $criteria Cost) $cost $dur))
            (let $collapsed (collapse $edge-atoms)
              (let* (($edge (car-atom $collapsed))
                     (() (println! ("Edge from" $head "to" $next "has weight:" $edge))))
                (compute-total-weight $tail $criteria (+ $acc $edge))))))))))

; -------- Driver --------
(= (dijkstra $start $end $criteria)
  (let* (
         ($w (initialize-distances $start))
         ($p (add-atom &pq-space (prio $start 0)))
         ($d (dijkstra-loop &pq-space &dist-space &parent-space $criteria $end))
         (() (println! ("Dijkstra complete. Reconstructing path..." $d))))
    (let* (($path (reconstruct-path &parent-space $end $start ()))
          (() (println! ("Reconstructed path:" $path))))
          ($path))))

; Public API
(= (getOptimizedRoute $start $end $criteria)
  (dijkstra $start $end $criteria))

;!(getOptimizedRoute A E Duration)