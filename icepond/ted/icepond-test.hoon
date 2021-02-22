/-  spider, icepond-types=icepond
/+  strandio
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
;<  our=@p   bind:m  get-our:strandio
;<  eny=@uv  bind:m  get-entropy:strandio
;<  ~        bind:m  (watch:strandio /ice-servers/from-self [our %icepond] /ice-servers/(scot %uv (sham eny)))
;<  ~        bind:m  (sleep:strandio ~s0)
;<  =cage    bind:m  (take-fact:strandio /ice-servers/from-self)
?>  =(p.cage %response)
(pure:m q.cage)
