#! /bin/bash

cat << EOF | less

=====================================================================
  MUSIC TRX - AIUTO
=====================================================================

- Abilita o disabilita la modifica delle configurazioni:

  $ music-trx-config.sh enable|disable

      ARGOMENTI:
        enable    abilita la configurazione
        disable   disabilita la configurazione


- Imposta il volume o lo salva per i prossimi reboot.
  Per salvare è necessario che la modifica delle configurazioni
  sia abilitata (usa music-trx-config.sh)

  $ music-trx-volume.sh set|save

      PARAMETRI:
        set         apre l'utility per impostare i volumi
        save        salva permanentemente lo stato corrente dei volumi


- Mostra stato e statistiche del servizio in tempo reale

  $ music-trx-status.sh


- Avvia o arresta il servizio

  $ sudo systemctl start|stop music-trx.service

      PARAMETRI:
        start       avvia il servizio
        stop        arresta il servizio


- Mostra i log del servizio

  $ music-trx-log.sh


EOF
