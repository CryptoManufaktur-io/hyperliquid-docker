#!/usr/bin/env bash
# --------------------------------------------------------------------
# Hyperliquid Validator – P2P Connection Auditor
# Lists remote IPs and counts of active connections across ports
# Usage: check_peer_connections.sh
# --------------------------------------------------------------------

CID=hyperliquid-docker-consensus-1
PORTS="4001 4002 4003 4004"
PID=$(docker inspect -f '{{.State.Pid}}' "$CID" 2>/dev/null) || {
  echo "Container $CID not found"; exit 1;
}

sudo nsenter -t "$PID" -n ss -4ntp \
| awk -v ports="$PORTS" '
BEGIN{
  split(ports,p); for(i in p) allow[p[i]]=1; header="Remote_IP";
  n=asorti(p,ps,"@val_num_asc");
  for(i=1;i<=n;i++) { header=header" "p[ps[i]]; cols[i]=p[ps[i]]; }
  header=header" Total"
}
NR>1{
  split($4,L,":"); lp=L[length(L)];
  if(!(lp in allow)) next;
  split($5,R,":"); ip=R[1];
  c[ip,lp]++; tot[ip]++; ips[ip]=1;
}
END{
  print header;
  print "--------------------";
  for(ip in ips){
    line=sprintf("%-20s", ip);
    t=0;
    for(i=1;i<=n;i++){
      lp=cols[i]; v=((ip SUBSEP lp) in c ? c[ip,lp] : 0);
      line=line sprintf(" %5d", v); t+=v;
    }
    line=line sprintf(" %5d", t);
    print line;
  }
}' | sort -k5nr
