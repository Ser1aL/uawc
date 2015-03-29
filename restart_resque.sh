if [ -e tmp/resque/resque_worker_1.pid ]; then \
for f in `ls tmp/resque/resque_worker*.pid`; \
  do \
    if kill -0 `cat $f`> /dev/null 2>&1; then \
      kill -9 `cat $f` && rm $f \
    ;fi \
  ;done \
;fi

PIDFILE=tmp/resque/resque_worker_1.pid QUEUE=sitemap_queue rake resque:work 2>/opt/my_errlog_1 >/opt/mylog_1 &
PIDFILE=tmp/resque/resque_worker_2.pid QUEUE=sitemap_queue rake resque:work 2>/opt/my_errlog_2 >/opt/mylog_2 &
PIDFILE=tmp/resque/resque_worker_3.pid QUEUE=sitemap_queue rake resque:work 2>/opt/my_errlog_3 >/opt/mylog_3 &