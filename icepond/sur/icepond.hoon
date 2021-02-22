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
+$  fetcher-config
  $%
    [%these-servers servers=(list server)]
    [%sponsored-only config=fetcher-config]
    [%team-only config=fetcher-config]
    [%or p=fetcher-config q=fetcher-config]
    [%from-sponsor ~]
  ==
--
