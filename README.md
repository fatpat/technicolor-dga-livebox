# technicolor-dga-livebox

Configurations + patches pour DGA4130 et DGA4132 en version 2.2.1 pour les réseaux xDSL et Fibre Orange France.

## Version courte
Il faut rooter le modem puis le mettre à jour en version 2.2.1. Toute la procédure est expliquée en long en large
en en travers sur ce site très bien fait (en anglais): https://hack-technicolor.readthedocs.io/en/stable/. Vous
trouverez, pour le DGA4130 et le DGA4132, le dernier firmware en date (2.2.1) ainsi que le 1.0.3 qui est facilement
rootable.

Note: après la mise à jour, penser à faire un reboot supplémentaire pour s'assurer que le fichier `/etc/rc.local`
est vide (ou presque, à quelques commentaires prêt).

il faut prendre les fichiers correspondant à votre version (à ce jour il n'y a que la version 2.2.1) et vous
trouverez dans le répertoire correspondant une arborescence à copier sur le dga.

Une fois le modem rooté et que vous êtes connecté dessus il faut copier les fichiers suivants:
- `/bin/fti.lua`
- `/bin/patch-odhcp.lua`
- `/etc/firewall.user`
- `/etc/rc.local`
- `/etc/config/network`

La copie peut se faire d'une traite en ligne de commande depuis votre poste:
```
linux# tar -czpf - --strip 1 --owner 0 --group 0 2.2.1 | ssh root@192.168.1.1 tar -C / -xzpf -
```

Ensuite il ne reste plus qu'à mettre votre fti encodé dans le fichier `/etc/config/network` par la commande
suivante sur le dga:
```
dga# sed s/%%%%%%%%%%/`fti.lua fti/abcdefg`/ /etc/config/network
```

Enfin, il faut patcher le binaire odhcpc par la commande
```
/bin/patch-odhcpc.lua
```

il ne reste plus qu'à rebooter le modem et constater l'ipv4 et l'ipv6 montée sur le dga:
```
ifstatus wan
ifstatus wan6
```

Maintenant à vous de jouer :)

## Version longue
Je ne reviendrai pas sur la façon de rooter un DGA, tout est indiqué sur https://hack-technicolor.readthedocs.io/.

Une fois rooté, bien s'assurer de rebooter au moins une fois pour avoir un fichier `/etc/rc.local` vide. En effet, lors de
la procédure de mise à jour, après le reboot, le fichier n'est pas vide et est automatiquement vidé au prochaine reboot.

Vous trouverez dans le répertoire 2.2.1 (pour la dernière version en date), les fichiers à copier sur le DGA
(via la commande `scp` ou via un programme de copie sous windows comme `winSCP` ou `FileZilla`):

### `/bin/fti.lua`
Une fois copié sur le dga, il faut lui donner les droits d'éxécution par la commande `chmod 755 /bin/fti.lua`. Ce script
permet de convertir votre identifiant orange (`fti/xxxxxxx`) en hexadecimal.
```
dga# fti.lua fti/xxxxxxx
6674692f78787878787878
```

C'est cette version hexadécimale de l'identifiant qu'il faudra renseigner dans le fichier `/etc/config/network`.

### `/bin/patch-odhcpc.lua`
Comme pour le script `fti.lua`, il faut lui donner les droits d'éxécution par la commande `chmod 755 /bin/patch-odhcpc.lua`.

Le binaire du client DHCPv4 (`/usr/sbin/odhcpc`) ne permet pas d'envoyer l'option 90 qui est indispensable pour avoir une réponse
des serveurs DHCP d'orange. C'est par cette option que votre ligne est identifiée.

Ce script va lire le binaire original dans `/rom/usr/sbin/odhcpc` et modifier un octet afin de modifier le comportement du binaire
et ainsi permettre l'envoie de l'option 90 (via l'argument `-x 90:***************`).

Normalement il suffit d'appeler la commande une seule fois, mais il peut être judicieux de l'intégrer dans le fichier `/etc/rc.local`
afin de garantir que le patch est appliqué à chaque reboot. Ce n'est pas un problème vu que le script prends sa source dans le répertoire
`/rom` qui est une copie en lecture seule du contenu du firmware.

```
dga# patch-odhcpc.lua
/usr/sbin/odhcpc successfully patched, you can restart network now
```
### `/etc/rc.local`
Ce script s'éxécute à chaque démarrage du modem. Il patch le binaire `odhcpc` (au cas où, voir ci-dessus) et mets en place
les queues egress sur l'interface dsl (ptm0.832, car sur le VLAN 832 CQFD).

Source: https://lafibre.info/remplacer-livebox/remplacement-de-la-livebox-par-un-routeur-openwrt-18-dhcp-v4v6-tv/

### `/etc/firewall.user`
Ce fichier intègre les règles iptables faite par l'utilisateur. Ont été rajoutées les règles de classement des flux spécifiques
à Orange dans les queues.

Source: https://lafibre.info/remplacer-livebox/remplacement-de-la-livebox-par-un-routeur-openwrt-18-dhcp-v4v6-tv/

### `/etc/config/network`
C'est le fichier brut, qui contient la configuration complète du modem. Il est possible de le copier comme cela.
Dedans il faut intégrer votre identifiant orange en hexadécimale en remplaçant à 2 endroits la suite de caractères
`%%%%%%%%%%` par la valeur renvoyée par le script `/bin/fti.lua`. La commande suivante permet de le faire automatiquement:
```
dga# sed s/%%%%%%%%%%/`fti.lua fti/abcdefg`/ /etc/config/network
```

Pour ceux qui, comme moi, n'aiment pas copier des fichiers sans trop savoir, voici les blocs intéressants à modifier:
#### la configuration du port adsl sur le vlan 832
```
# port ADSL (interface ptm0)
config device 'wanptm0'
	option type '8021q'
	option name 'wanptm0'
	option ifname 'ptm0'
	option vid '832'                   # VLAN orange
	option ipv6 '1'                    # bien penser a l'activer
	option mtu '1500'
```

#### la configuration ipv4 du wan (de l'ip publique)
```
config interface 'wan'
	option ifname 'ptm0.832'           # ptm0 pour l'adsl (eth4 pour le wan sur port route) et le vlan d'orange
	option proto 'dhcp'
	option peerdns '1'
	option broadcast '1'
	option vendorid 'sagem'
	option reqopts '1 15 28 51 58 59 90'
	option sendopts '77:2b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e4c697665626f7834 90:00000000000000000000001a0900000558010341010df%%%%%%%%%%'
	option mtu '1500'
	option auto '1'
	option ipv6 '1'                    # il faut bien activer ipv6 sur le wan meme si l'ipv6 se fera sur wan6
                                       # sinon ca désactive ipv6 sur l'interface ptm0.832 via net.ipv6.conf.ptm0.832.disable_ipv6=1
```

#### forcer le mode `dhcp` sur le wan (et non ppoe d'origine)
```
config config 'config'
	option wan_mode 'dhcp'             # pas sur que ce soit indispensable, au cas ou
```

#### la configuration ipv6 du wan (l'ip publique et le prefix /56)
```
config interface 'wan6'
	option ifname '@wan'
	option proto 'dhcpv6'
	option reqprefix 'auto'
	option reqaddress 'none'
	option defaultreqopts '0'
	option reqopts '11 17 23 24'
	option userclass 'FSVDSL_livebox.Internet.softathome.livebox4'
	option vendorclass '0000040e0005736167656d'
	option sendopts '11:00000000000000000000001a0900000558010341010d%%%%%%%%%%'
	option iface_dslite '0'            # desactiver ds-lite car on est en ipv6 natif
	option iface_464xlat '0'           # desactiver translation ipv4/65 car on est en ipv6 natif
```

les blocs liés à la voip/sip ont été supprimés dans mon cas. Libre à vous de jouer avec.

### Fin de la procédure
Une fois terminé, il ne reste plus qu'à rebooter le dga et connecter le cable rj11 :)

Une fois rebooté, vérifier la connexion ipv4 et ipv6. Si ça ne fonctionne pas vérifiez bien la présence de votre identifiant orange
(`fti/xxxxx`) dans les blocs `wan` et `wan6` du fichier `/etc/config/network`. A chaque modification, un restart du réseau est nécessaire par:
```
dga# /etc/init.d/network restart
```

Enfin, je vous conseil d'insaller la GUI alternative d'Ansuel que vous trouverez ici: https://github.com/Ansuel/tch-nginx-gui.
```
curl -k https://raw.githubusercontent.com/Ansuel/gui-dev-build-auto/master/GUI.tar.bz2 | bzcat | tar -C / -xvf -
/etc/init.d/rootdevice force
```

Pour ce qui est de la TV et de la voip, si cela vous intéresse, je vous laisse vous référer aux éxélents threads sur le sujet:
- https://lafibre.info/remplacer-livebox/remplacer-sa-livebox-par-un-technicolor-dga4132-roote/
- https://lafibre.info/remplacer-livebox/remplacement-de-la-livebox-par-un-routeur-openwrt-18-dhcp-v4v6-tv/

Je n'ai pas testé le fonctionnement moi même.

## Version chroot (pour la postérité)
Avant de savoir patcher le binaire odhcpc pour avoir l'option 90, on pouvait utiliser le binaire du firmware 1.0.3 en mettant en place
un chroot. Tout est disponible dans le répertoire `old-with-chroot-odhcpc`. Regarder le fichier `dga4130 (AGTEF)/2.2.1/Makefile` pour
le détail d'implémentation et le fichier `README.md` pour les explications d'usage.

## Pourquoi tout cela ?
Pour DHCPv4, seul le binaire `/usr/sbin/odhcpc` du firmware 1.0.3 permet d'envoyer l'option 90. Ce binaire fonctionne pour tous les firmwares < 2.2.0.

Pour DHCPv6, seuls les binaires `/usr/sbin/odhcp6c` des firmwares >= 2.2.0 permettent de passer l'option 11 (équivalent de l'option 90 en DHCPv4).

On constate que sans rien faire, soit nous avons de l'ipv4 avec les firmware < 2.2.0 et l'ipv6 avec les firmware >= 2.2.0. Mais jamais les deux !
Heuresement le patch sur le binaire `odhcpc` en 2.2.x permet d'avoir les deux pour ces versions là !
