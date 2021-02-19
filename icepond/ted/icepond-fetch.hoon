:: This is a wrapper for icepond fetching strands. It is in a separate
:: file because spider will only run strands from a file as threads.
::
:: It accepts an argument containing a fetching thread (from the icepond
:: state) and the name of the requesting ship. The ship name argument
:: is passed to the fetching thread.
::
:: It also handles wrapping the return result in a vase
/-  spider, icepond-types=icepond
/+  strandio
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
=+  !<([ship=@p  strand=$-(@p form:(strand ,response:icepond-types))] arg)
;<  result-unwrapped=response:icepond-types  bind:m  (strand ship)
(pure:m !>(result-unwrapped))
