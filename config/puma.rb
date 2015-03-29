root = "#{Dir.getwd}"

pidfile "#{root}/tmp/puma/pid"
state_path "#{root}/tmp/puma/state"
rackup "#{root}/config.ru"

bind 'tcp://127.0.0.1:8888'