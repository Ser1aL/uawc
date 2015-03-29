# UA Web Challenge Application 
Crawler Application that gathers urls of one specific domain and builds Sitemap out of them

## Installation
```
git clone https://github.com/Ser1aL/uawc.git
vagrant up
```

## How to check if servies are running
```
ps aux | grep puma
ps aux | grep resque
```
should produce results. If nothing produced cd to application directory and run
```
./restart_server.sh
./restart_resque.sh
```

## How to change the level of url nesting
Modify workers/sitemap_worker.rb file, constant named MAX_DEEP_LEVEL and then
```
./restart_server.sh
./restart_resque.sh
```
