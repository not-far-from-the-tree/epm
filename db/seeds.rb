# sources for Toronto wards
#   human-readable: http://app.toronto.ca/wards/jsp/wards.jsp
#   machine-readable: http://www1.toronto.ca/wps/portal/contentonly?vgnextoid=b1533f0aacaaa210VgnVCM1000006cd60f89RCRD

wards = <<WARDS
1 Etobicoke North
2 Etobicoke North
3 Etobicoke Centre
4 Etobicoke Centre
5 Etobicoke-Lakeshore
6 Etobicoke-Lakeshore
7 York West
8 York West
9 York Centre
10 York Centre
11 York South-Weston
12 York South-Weston
13 Parkdale-High Park
14 Parkdale-High Park
15 Eglinton-Lawrence
16 Eglinton-Lawrence
17 Davenport
18 Davenport
19 Trinity-Spadina
20 Trinity-Spadina
21 St. Paul's
22 St. Paul's
23 Willowdale
24 Willowdale
25 Don Valley West
26 Don Valley West
27 Toronto Centre-Rosedale
28 Toronto Centre-Rosedale
29 Toronto-Danforth
30 Toronto-Danforth
31 Beaches-East York
32 Beaches-East York
33 Don Valley East
34 Don Valley East
35 Scarborough Southwest
36 Scarborough Southwest
37 Scarborough Centre
38 Scarborough Centre
39 Scarborough-Agincourt
40 Scarborough-Agincourt
41 Scarborough-Rouge River
42 Scarborough-Rouge River
43 Scarborough East
44 Scarborough East
WARDS

wards.split("\n").each {|ward_name| Ward.create name: ward_name }