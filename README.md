# technicolor-dga-livebox

Configurations + patches pour DGA4130 et DGA4132 en version 2.2.1 pour les réseaux xDSL et Fibre Orange France.

## Version courte
Il faut rooter le modem puis le mettre à jour en version 2.2.1. Toute la procédure est expliquée en long en large
en en travers sur ce site très bien fait (en anglais): https://hack-technicolor.readthedocs.io/en/stable/.

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

il ne reste plus qu'à rebooter le modem et constater l'ipv4 et l'ipv6 montée sur le dga:
```
ifstatus wan
ifstatus wan6
```

Maintenant à vous de jouer :)

## Version longue

TODO
