/-   spider, icepond
/+   strandio
=,   strand=strand:spider
=<
|%
:: TODO: The default acquire should poke the sponsor (if other than
:: self, hello ~zod) for ICE candidates for itself and its team
:: but return ~ for all others
++  default-acquire
    =/  m  (strand ,response:icepond)
    ^-  $-(@p form:m)
    (or (team-only (or from-sponsor google-open)) (sponsored-only (or from-sponsor google-open)))
++  from-sponsor
    |=  requester=@p
    =/  m  (strand ,response:icepond)
    =,  m
    ^-  form
    ;<  sponsor=@p  bind  get-sein
    ;<  our=@p      bind  get-our:strandio
    ?<  =(sponsor our)
    ;<  eny=@uv     bind  get-entropy:strandio
    ;<  ~           bind  (watch:strandio /ice-servers/from-sponsor [sponsor %icepond] /ice-servers/(scot %uv (sham eny)))
    ;<  =cage       bind  (take-fact:strandio /ice-servers/from-sponsor)
    ?>  =(p.cage %response)
    =/  res  !<(response:icepond q.cage)
    (pure res)
++  these-servers
    |=  servers=(list server:icepond)
    |=  requester=@p
    =/  m  (strand ,response:icepond)
    =,  m
    ^-  form
    (pure [%servers servers])
++  sponsored-only
    =/  m  (strand ,response:icepond)
    |=  strand-for-sponsored=$-(@p form:m)
    |=  requester=@p
    ;<  our=@p         bind:m  get-our:strandio
    ;<  other-sein=@p  bind:m  (get-other-sein requester)
    ?.  =(other-sein our)
      (pure:m [%no-servers ~[%not-kid]])
    (strand-for-sponsored requester)
++  team-only
    =/  m  (strand ,response:icepond)
    |=  strand-for-team=$-(@p form:m)
    |=  requester=@p
    ;<  our=@p  bind:m  get-our:strandio
    ?.  (team:title our requester)
      (pure:m [%no-servers ~[%not-team]])
    (strand-for-team requester)
++  or
    =/  m  (strand ,response:icepond)
    |=  [strand-p=$-(@p form:m) strand-q=$-(@p form:m)]
    |=  requester=@p
    ^-  form:m
    ;<  p-tid=tid:spider    bind:m  (start-thread-with-args:strandio %icepond-fetch !>([ship=requester strand=strand-p]))
    ;<  q-tid=tid:spider    bind:m  (start-thread-with-args:strandio %icepond-fetch !>([ship=requester strand=strand-q]))
    ;<  ~                   bind:m  (watch-our:strandio /awaiting/[p-tid] %spider /thread-result/[p-tid])
    ;<  ~                   bind:m  (watch-our:strandio /awaiting/[q-tid] %spider /thread-result/[q-tid])
    ;<  p-cage=cage         bind:m  (take-fact:strandio /awaiting/[p-tid])
    ;<  q-cage=cage         bind:m  (take-fact:strandio /awaiting/[q-tid])
    =/  p-res
        ?+  p.p-cage  ~|([%strange-thread-result p.p-cage %icepond-fetch p-tid] !!)
           %thread-fail  [%no-servers ~[%failed-thread]]
           %thread-done  !<(response:icepond q.p-cage)
        ==
    =/  q-res
        ?+  p.q-cage  ~|([%strange-thread-result p.q-cage %icepond-fetch q-tid] !!)
           %thread-fail  [%no-servers ~[%failed-thread]]
           %thread-done  !<(response:icepond q.q-cage)
        ==
    %. 
      ?-  p-res
          [%no-servers *]
            ?-  q-res
              [%no-servers *]  [%no-servers (weld +.p-res +.q-res)]
              [%servers *]  q-res
            ==
          [%servers *]
            ?-  q-res 
              [%no-servers *]  p-res
              [%servers *]  [%servers (dedup (weld +.p-res +.q-res))]
            ==
      ==
    pure:m
++  google-open
    =/  m  (strand ,response:icepond)
    |=  requester=@p
    (pure:m [%servers ~[[urls=~['stun:stun.l.google.com:19302'] auth=~]]])

:: TODO:
::  - COTURN credential fetching
::  - group filtering
::  - examples of combining all of these
--
|%
++  dedup
    |=  servers=(list server:icepond)
    ^-  (list server:icepond)
    ~(val by (malt (zing (turn servers |=(=server:icepond (turn urls.server |=(url=@t [url server])))))))
++  get-sein
  =/  m  (strand ,@p)
  ^-  form:m
  |=  tin=strand-input:strand
  `[%done (sein:title our.bowl.tin now.bowl.tin our.bowl.tin)]
++  get-other-sein
  =/  m  (strand ,@p)
  |=  other=@p
  ^-  form:m
  |=  tin=strand-input:strand
  `[%done (sein:title our.bowl.tin now.bowl.tin other)]
--
