# 6.x

rpm -ivH http://repo.nikoforge.org/redhat/el6/nikoforge-release-latest
yum -y install http://vesta.informatik.rwth-aachen.de/ftp/pub/Linux/fedora-epel/6/i386/epel-release-6-8.noarch.rpm

yum -y install ipsec-tools
yum -y install xl2tpd

cat <<EOF >/etc/racoon/init.sh
#!/bin/sh
# set security policies
echo -e "flush;\n\
        spdflush;\n\
        spdadd 0.0.0.0/0[0] 0.0.0.0/0[1701] udp -P in  ipsec esp/transport//require;\n\
        spdadd 0.0.0.0/0[1701] 0.0.0.0/0[0] udp -P out ipsec esp/transport//require;\n"\
        | setkey -c
# enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF

chmod 750 /etc/racoon/init.sh

sed --in-place '/\/etc\/racoon\/init.sh/d'  /etc/rc.d/rc.local
echo /etc/racoon/init.sh >> /etc/rc.d/rc.local

cat <<EOF > /etc/racoon/racoon.conf
path include "/etc/racoon";
path pre_shared_key "/etc/racoon/psk.txt";
path certificate "/etc/racoon/certs";
path script "/etc/racoon/scripts";
remote anonymous
{
        exchange_mode    aggressive,main;
        passive          on;
        proposal_check   obey;
        support_proxy    on;
        nat_traversal    on;
        ike_frag         on;
        dpd_delay        20;
        proposal
        {
                encryption_algorithm  aes;
                hash_algorithm        sha1;
                authentication_method pre_shared_key;
                dh_group              modp1024;
        }
        proposal
        {
                encryption_algorithm  3des;
                hash_algorithm        sha1;
                authentication_method pre_shared_key;
                dh_group              modp1024;
        }
}
sainfo anonymous
{
        encryption_algorithm     aes,3des;
        authentication_algorithm hmac_sha1;
        compression_algorithm    deflate;
        pfs_group                modp1024;
}
EOF

chmod 600 /etc/racoon/racoon.conf

cat <<EOF > /etc/racoon/psk.txt
myhomelan d41d8cd98f00b204e980
* d41d8cd98f00b204e980
EOF

chmod 600 /etc/racoon/psk.txt

cat <<EOF > /etc/xl2tpd/xl2tpd.conf
[global]
ipsec saref = yes
force userspace = yes
[lns default]
local ip = 10.203.123.200
ip range = 10.203.123.201-10.203.123.210
refuse pap = yes
require authentication = yes
ppp debug = yes
length bit = yes
pppoptfile = /etc/ppp/options.xl2tpd
EOF

cat <<EOF > /etc/ppp/options.xl2tpd
ms-dns 10.203.120.41
ms-dns 8.8.8.8
require-mschap-v2
asyncmap 0
auth
crtscts
lock
hide-password
modem
debug
name l2tpd
proxyarp
lcp-echo-interval 10
lcp-echo-failure 100
EOF

cat <<EOF >> /etc/ppp/chap-secrets
dista5      *         666666     *
dista6      *         666666     *
dista7      *         666666     *
dista8      *         666666     *
dista9      *         666666     *
EOF

chmod 600 /etc/ppp/chap-secrets
chkconfig racoon on
chkconfig xl2tpd on
service racoon restart
service xl2tpd restart
/etc/racoon/init.sh
