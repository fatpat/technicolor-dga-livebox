# technicolor-dga-livebox
Comment remplacer la livebox par un modem technicolor DGA4130/2 (mais aussi surement d'autres).

Toutes les manipulations sont indiquées pour être réalisées depuis un linux et sur le dga. C'est possible
depuis un windows, mais ce sera moins bien décris et des adaptations seront nécessaires. Mais avec 
WSL ce devrait être assez simple.

#### Typo
- Pour le code lancé sur le dga:
```
dga# command arguement

result
```
- Pour le code lancé depuis le poste (linux): 
```
linux# command arguement

result
```

## Etapes:
### 1. rooter le modem
Le plus simple est de suivre le site https://hack-technicolor.readthedocs.io/en/stable/ qui détail
toutes les étapes pour rooter son modem. Il faut bien lire pour comprendre ce qu'il faut faire et comment.

Une fois rooté, il ne faut pas négliger la configuration des banks en cas de problème:
https://hack-technicolor.readthedocs.io/en/stable/Hacking/PostRoot/#bank-planning.

Note: vous trouverez dans le répertoire `dgaXXX (YYYYY)/firmwares/YYYYY-1.03_CLOSED.rbi`, le firmware le
plus simple à rooter.

### 2. mettre à jour avec la dernière version
Une fois rooté, il faut mettre à jour vers la denière version, encore une fois tout est détaillé:
https://hack-technicolor.readthedocs.io/en/stable/Upgrade/.

Vous trouverez dans le répertoire `dgaXXX (YYYYY)/firmwares/YYYYY-2.2.1_CLOSED.rbi`, le dernier firwmare
stable à jour (01/2021).

Note: ne surtout pas oublier la section intitulée `Preserving root access` 😉

A la fin du processus, rebooter le modem (commande `reboot`) et s'assurer d'avoir un fichier `/etc/rc.local` ne contenant
que la ligne `exit 0`.

A ce moment là, vous avez une modem rooté, en dernière version, clean et avec accès SSH.

### 3. extraire le binaire odhcpc du firmware 1.0.3
Sur le réseau Orange, pour obtenir une adresse IP en DHCPv4 le client DHCP doit envoyer les options `70` et `90`.
Or depuis la version 1.0.4 du firmare, le client dhcp (`odhcpc`) ne permet plus d'envoyer l'option 90. Il faut donc
récupérer le binaire `odhcpc` du firmware 1.0.3 pour le mettre sur la dernière version.

Pour ce qui est de l'IPv6, le client DHCPv6 doit envoyer les options `11`, `15` et `16`. Depuis le firmware 2.2.0
le client dhcpv6 (`odhcp6c`) le permet (alors que dans les versions < 2.2.0, l'option `11` n'était pas disponible).

Voici ce qu'il faut faire.
1. copier le firmware 1.0.3 sur le dga (ou utiliser WinSCP)
```
linux# scp dga4130\ \(AGTEF\)/firmwares/AGTEF_1.0.3_CLOSED.rbi root@192.168.1.1:/tmp/

AGTEF_1.0.3_CLOSED.rbi                            100%   25MB   1.8MB/s   00:14
```

2. dechiffrer et extraire le firmware
Le firmware au format .rbi est chiffré et n'est pas utilisable en l'état. Il faut le déchiffrer sur le DGA sur lequel 
se trouve les outils et les clés nécessaires.
```
dga# cat /tmp/AGTEF_1.0.3_CLOSED.rbi | (bli_parser && echo "Please wait..." && (bli_unseal | dd bs=4 skip=1 seek=1 of=/tmp/AGTEF_1.0.3_CLOSED.bin))

magic_value: BLI2
fim: 23
fia: ZA
prodid: 0
varid: 0
version: 0.0.0.0
data_offset: 369
data_size: 26406986
timestamp: 0x207F57E0
boardname: VBNT-K
prodname: Technicolor DGA0130TCH
varname: DGA0130TCH
tagparserversion: 200
flashaddress: 0x5A00000
Please wait...
```

3. Récupérer le binaire 1.0.3 depuis le dga:
```
linux# scp root@192.168.1.1:/tmp/AGTEF_1.0.3_CLOSED.bin dga4130\ \(AGTEF\)/firmwares/

AGTEF_1.0.3_CLOSED.bin                            100%   25MB   1.8MB/s   00:14
```

4. faire du ménage sur le dga:
```
dga# rm /tmp/AGTEF_1.0.3_CLOSED.*
```

5. extraire le contenu du firmware 1.03 et sauvegarder les fichiers
Il faut tout d'abord installer l'outil [binwalk](https://github.com/ReFirmLabs/binwalk/) sur votre poste:
```
linux(debian)# sudo apt-install binwalk
```
Pour les autres cas (autre que debian/ubuntu), se référer au site de binwalk:
```
linux# wget -O - https://github.com/ReFirmLabs/binwalk/archive/v2.2.0.tar.gz | tar -x

...
linux# (cd binwalk-2.2.0 && sudo python3 setup.py install)

...
Writing /usr/local/lib/python3.6/site-packages/binwalk-2.2.0-py3.6.egg-info
```

Une fois binwalk installé, il ne reste plus qu'à extraire le contenu du firmware 1.0.3:
```
linux# binwalk -Mre dga4130\ \(AGTEF\)/firmwares/AGTEF_1.0.3_CLOSED.bin

Scan Time:     2021-02-16 05:26:33
Target File:   /tmp/_technicolor-dga-livebox/AGTEF_1.0.3_CLOSED.bin.extracted/_26.extracted/450F43
MD5 Checksum:  70bc8f4b72a86921468bf8e8441dce51
Signatures:    391

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------

```

Nous avons désormais accès au contenu du firmware 1.0.3 et nous allons récupérer les fichiers qui nous intéressent:
- `/usr/sbin/odhcpc`
- `/lib/libc.so.0`, `libuClibc-0.9.33.2.so`
- `ld-uClibc.so.0`, `ld-uClibc-0.9.33.2.so`
- 



6. création du chroot
sur le dga, passer les commandes suivantes:
```
mkdir /chroot-1.0.3
mkdir /chroot-1.0.3/dev
test -c /chroot-1.0.3/dev/null || mknod -m 0444 /chroot-1.0.3/dev/null c 1 3
test -c /chroot-1.0.3/dev/random || mknod -m 0444 /chroot-1.0.3/dev/random c 1 8
test -c /chroot-1.0.3/dev/urandom || mknod -m 0444 /chroot-1.0.3/dev/urandom c 1 9
test -c /chroot-1.0.3/dev/zero || mknod -m 0444 /chroot-1.0.3/dev/zero c 1 5
mkdir /chroot-1.0.3/var
mkdir -p /chroot-1.0.3/lib/netifd
mkdir -p /chroot-1.0.3/usr/share/libubox
echo /lib/netifd         /chroot/lib/netifd     none  bind,ro  0  0 >>/etc/fstab
echo /var                /chroot/var            none  bind     0  0 >>/etc/fstab
echo /usr/share/libubox  /chroot/share/libubox  none  bind,ro  0  0 >>/etc/fstab
mount -a
cp /lib/functions.sh /chroot-1.0.3/lib/
```

## Notes
### Firmwares
Les firmwares sont disponible sur le repository d'ansuel sur le forum italien: https://repository.ilpuntotecnico.com/files/Ansuel/

Je n'ai recopié que ceux pour le 4130 et 4132, mais les firmwares d'autres versions sont également disponibles.

Seules les versions intéressantes sont disponibles ici:
- 1.0.3: on y retrouve le binaire odhcpc compatible avec l'option 90 et il est facilement rootable
- 2.2.1: dernière version stable à ce jour (01/2021)
