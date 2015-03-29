if [ -e tmp/resque/resque_worker_1.pid ]; then \
for f in `ls tmp/resque/resque_worker*.pid`; \
  do \
    if kill -0 `cat $f`> /dev/null 2>&1; then \
      kill -9 `cat $f` && rm $f \
    ;fi \
  ;done \
;fi

PIDFILE=tmp/resque/resque_worker_1.pid QUEUE=sitemap_queue rake resque:work 2>log/resque_error_log_1.log >log/resque_log_1.log &
PIDFILE=tmp/resque/resque_worker_2.pid QUEUE=sitemap_queue rake resque:work 2>log/resque_error_log_2.log >log/resque_log_2.log &
PIDFILE=tmp/resque/resque_worker_3.pid QUEUE=sitemap_queue rake resque:work 2>log/resque_error_log_3.log >log/resque_log_3.log &