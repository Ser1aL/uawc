if [ -f tmp/puma/pid ] && kill -0 `cat tmp/puma/pid`; then kill -9 `cat tmp/puma/pid`; fi
puma 2>&1 >/dev/null &