#!/bin/bash

SCRIPTDIR=`dirname $0`
source "$SCRIPTDIR/functions"

###############################
# MAIN 
###############################

start_server master
check_get 18011 "/?a=*" '"count":0'
start_server master2
check_get 18012 "/?a=*" '"count":0'
start_server agent_multi

send_stat agent_multi "test.counter" 42
send_stat agent_multi "#beverly_hills" 90210
send_stat agent_multi "test.counter^a^b^c" 42
flush_istatd agent_multi
sleep 1 # terrible

# check first master
flush_istatd master
sleep 1 # terrible
test_counter master "test/counter/10s" 42
test_counter master "test/counter/a/10s" 42
test_counter master "test/counter/b/10s" 42
test_counter master "test/counter/c/10s" 42
test_counter master "istatd/admin/connections/10s" 0 0 0 0 0.1 0 0 0 0 
test_counter master "istatd/admin/commands/10s" 0 0 0 0 0.1 0 0 0 0

# check second master
flush_istatd master2
sleep 1 # terrible
test_counter master2 "test/counter/10s" 42
test_counter master2 "test/counter/a/10s" 42
test_counter master2 "test/counter/b/10s" 42
test_counter master2 "test/counter/c/10s" 42
test_counter master2 "istatd/admin/connections/10s" 0 0 0 0 0.1 0 0 0 0 
test_counter master2 "istatd/admin/commands/10s" 0 0 0 0 0.1 0 0 0 0

send_event agent_multi "!test.event|superevent|testhost"
send_stat agent_multi "test.postevent" 99
flush_istatd agent_multi
sleep 1 # terrible

flush_istatd master
test_counter master "test/postevent/10s" 99

flush_istatd master2
test_counter master2 "test/postevent/10s" 99

sleep 1 # terrible

check_get 18011 "/?a=*" '"count":1' '"_online":true' '"version":"' '"proto":"x ' '"hostname":"' '"beverly_hills":"90210'
check_get 18012 "/?a=*" '"count":1' '"_online":true' '"version":"' '"proto":"x ' '"hostname":"' '"beverly_hills":"90210'

purge_istatd 18033

#Clean up and exit
cleanup_test
rm -rf "$DBDIR"

