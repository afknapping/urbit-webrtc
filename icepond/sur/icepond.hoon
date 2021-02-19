|%
:: Optional auth information for a server
+$  auth  $@(~ [username=@t credentials=@t credentials-type=$@(~ @t)])
:: A description of an ice server
+$  server  [urls=(list @t) auth=auth]
:: The response to a request for ICE servers
+$  response
  $%
    [%no-servers (list @tas)]
    [%servers (list server)]
  ==
--
