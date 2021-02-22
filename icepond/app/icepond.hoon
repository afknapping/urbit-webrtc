:: # ICEpond: acquire ICE server information
::
:: ## Functionality
:: ICEpond is designed to acquire information about ICE servers and send
:: it to agents, possibly on other ships. The actual fetching of server
:: information is left to a user configurable (via a poke) strand which
:: is passed the name of the requesting ship, and can do arbitrary
:: checking and IO to come up with a suitable list of candidates or a
:: reason why no candidates are available.
::
:: The default strand asks the ship's sponsor for servers if the
:: request comes from the ship's team (the ship itself or its moons) but
:: otherwise returns no servers.
::
:: Other, composable strands provide various authentication schemes as
:: well as other server acquisition methods including static sets of
:: servers, random selection from a list, and credential acquisition
:: from COTURN.
::
:: Client applications submit a %watch to /ice-servers/<random id>
:: 
:: They receive a list of ice servers, or a reason why no ice servers
:: could be given, along the supplied wire.
::
:: ## Implementation
:: Each watch request is serviced by a spider thread, whose thread id is
:: mapped to the random ID submitted by the requesting agent.
:: 
:: All threads run the same strand, parameterized only by the ship name.
:: The strand can be changed, to service all subsequent responses, by a
:: poke.
::
/-  icepond-types=icepond, spider
/+  default-agent, dbug, icepond
=,  strand=strand:spider
=/  response-strand  (strand ,response:icepond-types)
|%

:: We keep around a gate-strand that will produce ICE candidates for a
:: ship. Ideally this checks the ship's relation to us, and then fetches
:: server information from our sponsor, a static configuration, or e.g.
:: a COTURN server
::
:: We also keep around a thread id <-> request ID mapping,
:: so that when a thread finishes acquiring ice servers, we can
:: notify the requestee with a %gift and a subsequent %kick
+$  versioned-state
    $%  state-0
    ==
+$  state-0
    [%0 acquire-ice=$-(@p form:response-strand) running-requests=(map @ta tid:spider) running-threads=(map tid:spider @ta)]
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state=state-0
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    default  ~(. (default-agent this %|) bowl)

++  on-init
    ~&  >  'icepond init: default ice fetcher installed'
    `this(state [%0 acquire-ice=(strand-from-config:icepond default-config:icepond) running-requests=~ running-threads=~])
++  on-save
    ^-  vase
    !>(state)

:: - load the strand from the state
:: - kill any running threads
:: - kick any remaining subscriptions
++  on-load  
  |=  =vase
  ^-  (quip card _this)
  =/  old-state  !<(versioned-state vase)
  ?-  -.old-state  
      %0
      ~&  >  'icepond load from version 0'
      :_  this(state [%0 acquire-ice=acquire-ice:old-state running-requests=~ running-threads=~])
      %+  weld
          (turn ~(tap in ~(key by running-requests:old-state)) kick-requester)
      (turn ~(tap in ~(key by running-threads:old-state)) stop-thread)
      ::
  ==

:: Only one poke: to set the acquire function
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:default mark vase)
      %set-acquire-ice
      ?>  (team:title our.bowl src.bowl) :: Only us or our moons
      =/  new-acquire-ice  !<($-(@p form:response-strand) vase)
      =/  new-state  state(acquire-ice new-acquire-ice)
      ~&  >  'icepond: new ice server acquisition strand'
      `this(state new-state)
  ==

:: handle watches by poking spider with our strand 
:: Applications should watch a path
:: - /ice-servers/<random id>
::   This ensures that we return the ICE servers acquired for the specific
::   request. We don't want to broadcast ICE servers.
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  -.path  (on-watch:default path)
      %ice-servers
    =/  rqid  +<.path
    ?:  (~(has by running-requests:state) rqid)  ~|("Already got a request with id: {<rqid>}" !!)
    =/  tid  (scot %ta (cat 3 'icepond-acquire-ice_' (scot %uv (sham eny:bowl))))
    =/  new-running-requests  (~(put by running-requests:state) rqid tid)
    =/  new-running-threads  (~(put by running-threads:state) tid rqid)
    =/  new-state  state(running-requests new-running-requests, running-threads new-running-threads)
    :_  this(state new-state)
    (start-and-watch-thread tid=tid strand=acquire-ice:state ship=src.bowl)
  ==

:: handle leaves by poking spider to stop the relevant thread
++  on-leave  
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-leave:default path)
      [%ice-servers * ~]
      =/  rqid  +<.path
      ?.  (~(has by running-requests:state) rqid)
          ~&  >  "Missing request id: {<rqid>}"
          `this
      =/  tid  (~(got by running-requests:state) rqid)
      =/  new-running-requests  (~(del by running-requests:state) rqid)
      =/  new-running-threads  (~(del by running-threads:state) tid)
      =/  new-state  state(running-requests new-running-requests, running-threads new-running-threads)
      :_  this(state new-state)
      :~
        (stop-thread tid)
      ==
  ==
++  on-peek   on-peek:default
++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    ?+  -.wire  (on-agent:default wire sign)
        %start-acquire
        ~&  >  "Successfully started thread {<+<.wire>}"
        `this
        ::
        %stop-acquire
        ~&  >  "Successfully stopped thread {<+<.wire>}"
        `this
        ::
        %acquired-ice-servers
        ?+  -.sign  (on-agent:default wire sign)
            %fact
            ?+  p.cage.sign  (on-agent:default wire sign)
                %thread-fail
                =/  failure  !<([term tang] q.cage.sign)
                ~|  -.failure  !!
                ::
                %thread-done
                =/  tid  +<.wire
                =/  rqid  (~(got by running-threads:state) tid)
                =/  =response:icepond-types  !<(response:icepond-types q.cage.sign)
                =/  new-running-requests  (~(del by running-requests:state) rqid)
                =/  new-running-threads  (~(del by running-threads:state) tid)
                =/  new-state  state(running-requests new-running-requests, running-threads new-running-threads)
                :_  this(state new-state)
                (kick-requester-with-fact rqid response)
            ==
        ==
    ==

++  on-arvo   on-arvo:default
++  on-fail   on-fail:default
--
:: Helpers
|_  =bowl:gall
++  stop-thread
    |=  =tid:spider
    =/  =cage  [%spider-stop !>([tid %.y])]
    ^-  card:agent:gall
    [%pass /stop-acquire/[tid] %agent [our.bowl %spider] %poke cage]
++  kick-requester
    |=  rqid=@ta
    ^-  card:agent:gall
    [%give %kick ~[/ice-servers/[rqid]] ~]
++  kick-requester-with-fact
    |=  [rqid=@ta =response:icepond-types]
    ^-  (list card:agent:gall)
    :~
    [%give %fact ~[/ice-servers/[rqid]] [%response !>(response)]]
    [%give %kick ~[/ice-servers/[rqid]] ~]
    ==
++  start-and-watch-thread
    |=  [=tid:spider strand=$-(@p form:response-strand) ship=@p]
    ^-  (list card:agent:gall)
    =/  =cage  [%spider-start !>([parent=~ use=tid file=%icepond-fetch vase=!>([~ ship=ship strand=strand])])]
    :~
    [%pass /start-acquire/[tid] %agent [our.bowl %spider] %poke cage]
    [%pass /acquired-ice-servers/[tid] %agent [our.bowl %spider] %watch /thread-result/[tid]]
    ==
--
