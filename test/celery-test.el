(require 'ert)
(require 'el-mock)

(require 'celery)

(ert-deftest test-celery-compute-full-stats-workers ()
  (should (equal '((worker02 (total
                              (swh\.worker\.tasks\.do_something_awesome . 27113))
                             (rusage
                              (utime . 393.488)
                              (stime . 26.512)
                              (oublock . 0)
                              (nvcsw . 208050)
                              (nswap . 0)
                              (nsignals . 0)
                              (nivcsw . 132094)
                              (msgsnd . 0)
                              (msgrcv . 0)
                              (minflt . 15180)
                              (maxrss . 36568)
                              (majflt . 38)
                              (ixrss . 0)
                              (isrss . 0)
                              (inblock . 14280)
                              (idrss . 0))
                             (prefetch_count . 8)
                             (pool
                              (writes
                               (total . 27113)
                               (raw . "12702, 14411")
                               (inqueues
                                (total . 2)
                                (active . 0))
                               (avg . "50.00%")
                               (all . "46.85%, 53.15%"))
                              (timeouts .
                                        [3600.0 0])
                              (put-guarded-by-semaphore . :json-false)
                              (processes .
                                         [14221 14223])
                              (max-tasks-per-child . "N/A")
                              (max-concurrency . 1))
                             (pid . 14216)
                             (clock . "403897")
                             (broker
                              (virtual_host . "/")
                              (userid . "guest")
                              (uri_prefix)
                              (transport_options)
                              (transport . "amqp")
                              (ssl . :json-false)
                              (port . 5672)
                              (login_method . "AMQPLAIN")
                              (insist . :json-false)
                              (hostname . "moma")
                              (heartbeat)
                              (connect_timeout . 4)
                              (alternates .
                                          []))))
                 (with-mock
                   (mock (celery--compute-raw-celery-output) =>
                         "celery@worker02: OK\n    {\n        \"broker\": {\n            \"alternates\": [],\n            \"connect_timeout\": 4,\n            \"heartbeat\": null,\n            \"hostname\": \"moma\",\n            \"insist\": false,\n            \"login_method\": \"AMQPLAIN\",\n            \"port\": 5672,\n            \"ssl\": false,\n            \"transport\": \"amqp\",\n            \"transport_options\": {},\n            \"uri_prefix\": null,\n            \"userid\": \"guest\",\n            \"virtual_host\": \"/\"\n        },\n        \"clock\": \"403897\",\n        \"pid\": 14216,\n        \"pool\": {\n            \"max-concurrency\": 1,\n            \"max-tasks-per-child\": \"N/A\",\n            \"processes\": [\n                14221,\n                14223\n            ],\n            \"put-guarded-by-semaphore\": false,\n            \"timeouts\": [\n                3600.0,\n                0\n            ],\n            \"writes\": {\n                \"all\": \"46.85%, 53.15%\",\n                \"avg\": \"50.00%\",\n                \"inqueues\": {\n                    \"active\": 0,\n                    \"total\": 2\n                },\n                \"raw\": \"12702, 14411\",\n                \"total\": 27113\n            }\n        },\n        \"prefetch_count\": 8,\n        \"rusage\": {\n            \"idrss\": 0,\n            \"inblock\": 14280,\n            \"isrss\": 0,\n            \"ixrss\": 0,\n            \"majflt\": 38,\n            \"maxrss\": 36568,\n            \"minflt\": 15180,\n            \"msgrcv\": 0,\n            \"msgsnd\": 0,\n            \"nivcsw\": 132094,\n            \"nsignals\": 0,\n            \"nswap\": 0,\n            \"nvcsw\": 208050,\n            \"oublock\": 0,\n            \"stime\": 26.512,\n            \"utime\": 393.488\n        },\n        \"total\": {\n            \"swh.worker.tasks.do_something_awesome\": 27113\n        }\n    }")

                   (celery-compute-full-stats-workers)))))

(ert-deftest test-celery-all-workers ()
  (should (equal '(w01 w02) (celery-all-workers '((w01 (a . b)) (w02 (b . c))))))
  (should-not (celery-all-workers '())))

(ert-deftest test-celery-count-processes-per-worker ()
  (should (equal 5 (let ((stats '((w02 (pool
                                        (processes .
                                                   [1 2 3 4 5]))))))
                     (celery-count-processes-per-worker stats 'w02))))
  (should-not (let ((stats '((w01 (pool
                                   (processes .
                                              [14221 14223]))))))
                (celery-count-processes-per-worker stats 'w02))))

(ert-deftest test-celery-total-tasks-per-worker ()
  (should (equal 27113 (let ((stats '((w02 (total
                                            (swh\.worker\.tasks\.do_something_awesome . 27113))))))
                         (celery-total-tasks-per-worker stats 'w02))))
  (should-not (let ((stats '((w01 (total
                                   (swh\.worker\.tasks\.do_something_awesome . 27113))))))
                (celery-total-tasks-per-worker stats 'w02))))

(ert-deftest test-celery-total-tasks-per-worker ()
  (should (string= "| Fri Aug  7 19:02:12 2015 | 27113 | 300 | " (with-mock
                                                                   (mock (current-time-string) => "Fri Aug  7 19:02:12 2015")
                                                                   (let ((stats '((w02 (total
                                                                                        (swh\.worker\.tasks\.do_something_awesome . 27113)))
                                                                                  (w01 (total
                                                                                        (swh\.worker\.tasks\.do_something_awesome . 300))))))
                                                                     (celery--to-org-table-row stats)))))
  (should (string= "| Fri Aug  7 19:02:38 2015 | 300 | " (with-mock
                                                           (mock (current-time-string) => "Fri Aug  7 19:02:38 2015")
                                                           (let ((stats '((w02 (total
                                                                                (swh\.worker\.tasks\.do_something_awesome . 27113)))
                                                                          (w01 (total
                                                                                (swh\.worker\.tasks\.do_something_awesome . 300))))))
                                                             (celery--to-org-table-row stats '(w01)))))))

(ert-deftest test-celery--stats-to-org-row ()
  (should (string= "| date                     |  w01 |   w02 | w01 + w02 |
| Fri Aug  7 16:51:25 2015 | 5949 |  5703 |     11652 |
| snapshot time            |  300 | 27113 |     27413 |
|                          |      |       |         0 |
#+TBLFM: $4=vsum($2..$3)
"

                   (lexical-let ((stats '((w02 (total
                                                (swh\.worker\.tasks\.do_something_awesome . 27113)))
                                          (w01 (total
                                                (swh\.worker\.tasks\.do_something_awesome . 300))))))
                     (with-mock
                       (mock (current-time-string) => "snapshot time")
                       (with-temp-buffer
                         (org-mode)
                         (insert "| date | w01 | w02 | + |\n")
                         (insert "| Fri Aug  7 16:51:25 2015 | 5949 | 5703 |  |\n")
                         (insert "#+TBLFM: $4=vsum($2..$3)\n")
                         (previous-line 2)
                         (beginning-of-line)
                         (celery--stats-to-org-row stats '(w01 w02))
                         (buffer-substring-no-properties (point-min) (point-max))))))))

(ert-deftest test-celery-log ()
  (should (string= "Celery - This is a formatted message. Hello dude, how are you?"
                   (celery-log "This is a formatted message. Hello %s, %s" "dude" "how are you?"))))


(ert-deftest test-celery-simplify-stats ()
  (should (equal
           '((worker02 (:total . 27113) (:processes . 2))
             (worker99 (:total . 27113) (:processes . 2)))
           (celery-simplify-stats '((worker02 (total
                                               (swh\.worker\.tasks\.do_something_awesome . 27113))
                                              (prefetch_count . 8)
                                              (pool
                                               (writes
                                                (total . 27113)
                                                (raw . "12702, 14411")
                                                (inqueues
                                                 (total . 2)
                                                 (active . 0))
                                                (avg . "50.00%")
                                                (all . "46.85%, 53.15%"))
                                               (timeouts .
                                                         [3600.0 0])
                                               (processes .
                                                          [14221 14223])
                                               (max-tasks-per-child . "N/A")
                                               (max-concurrency . 1))
                                              (pid . 14216)
                                              (clock . "403897")
                                              (broker
                                               (virtual_host . "/")
                                               (userid . "guest")
                                               (heartbeat)
                                               (connect_timeout . 4)
                                               (alternates . [])))
                                    (worker99 (total
                                               (swh\.worker\.tasks\.do_something_awesome . 27113))
                                              (prefetch_count . 8)
                                              (pool
                                               (writes
                                                (total . 27113)
                                                (raw . "12702, 14411")
                                                (inqueues
                                                 (total . 2)
                                                 (active . 0))
                                                (avg . "50.00%")
                                                (all . "46.85%, 53.15%"))
                                               (timeouts .
                                                         [3600.0 0])
                                               (processes .
                                                          [14221 14223])
                                               (max-tasks-per-child . "N/A")
                                               (max-concurrency . 1))
                                              (pid . 14216)
                                              (clock . "403897")
                                              (broker
                                               (virtual_host . "/")
                                               (userid . "guest")
                                               (heartbeat)
                                               (connect_timeout . 4)
                                               (alternates . []))))))))

(ert-deftest test-celery--compute-stats-workers-with-refresh ()
  (should (equal :full-stats
                 (with-mock
                   (mock (celery-compute-full-stats-workers) => :full-stats)
                   (let ((celery-last-known-stats nil))
                     (celery--compute-stats-workers-with-refresh)))))
  (should (equal :old-stats
                 (let ((celery-last-known-stats :old-stats))
                   (celery--compute-stats-workers-with-refresh))))
  (should (equal :full-stats
                 (with-mock
                   (mock (celery-compute-full-stats-workers) => :full-stats)
                   (let ((celery-last-known-stats :old-stats))
                     (celery--compute-stats-workers-with-refresh 'with-refresh))))))

;; (ert-deftest test-celery--with-delay-apply ()
;;   (with-mock
;;     (mock (celery--compute-stats-workers-with-refresh) => :stats)
;;     (mock (celery-simplify-stats :stats) => :simplified-stats)
;;     (celery--with-delay-apply
;;      (lambda (stats)
;;        (should (equal :simplified-stats stats))))))
;; does not work