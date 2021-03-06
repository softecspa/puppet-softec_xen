puppet-softec\_xen
=================

La classe installa xen in base alle necessità softec. Utilizzata solo per retrocompatibilità, da ritenersi inaffidabile!


Il modulo Xen esegue alcune operazioni al fine di automatizzare la creazione di un nodo Xen (dom0).

 * Viene controllata la presenza e se assenti vengono installati i pacchetti:
  * ubuntu-xen-server       metapacchetto per xen-hypervisor-3.x, xen-tools, xen-utils-3.x, etc...
  * bridge-utils            necessario per la creazione dei network bridge
  * vlan                    necessario per il supporto alle VLAN
  * nfs-common              necessario per il mount delle share NFS dei vdisk, etc...
  * open-iscsi              necessario per il supporto su ISCSI
  * xen-shell               opzionale, consente di autorizzare un normale users per start|stop|reboot di una guest instance

 * Vengono pushati gli script necessari ad semplificare il networking:
  * network-bridge-vlan     script principale per la creazione e rimozione delle VLAN e dei bridge
  * network-multi-vlan      file/script network-multi-vlan  dove vengono definite le interfacce tagged e i bridge
 * Una volta pushati i due files viene rieseguito lo script network-multi-vlan con il parametro start
 * Se aggiunta una definizione di iface, vlan, e bridge viene rieseguito nuovamente lo script network-bridge-vlan

 * Viene pushato lo script xend-config.sxp, dove viene definita la gestione del networking, la memoria max del dom0, etc..

 * Vengono cambiati alcuni parametri del kernel in relazione al dom0 attraverso il file grub.conf:
  * dom0\_mem=1024M dom0\_max\_vcpus=1 dom0\_vcpus\_pin      cpu pinning del dom0 su cpu 0 e utilizzo max di memoria ad 1G
  * console=tty0 netloop.nloopbacks=0                   viene specificato che i bridge non possono bindare sul loopback

 * Vengono definiti alcuni valori per grub:
  * Commento hiddenmenu, si rende  visibile il menu' di grub
  * Cambio del valore timeout a 15 secondi

 * Viene eseguito il comando grub-update

 * Le azioni, ex.: 'network-multi-vlan start', vengono loggate sul client con il tag 'puppet-xen-class'

 * Viene pushato il file /etc/apt/preferences per evitare l'upgrade automatico del kernel
    anche in relazione al pacchetto unattended-upgrades
    *** ATTENZIONE: questo file no permette commenti, quindi non è stato possibile implementare gli svn keywords ***

 * Viene pushato il file /etc/xen-tools/xen-tools.conf che contiene dei custom default relativi al comando xen-create-image
    necessario per creare facilmente una nuova virtual machine Ubuntu 8.04
