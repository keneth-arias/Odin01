# Odin01
Per esporre questo vecchio server Odin01 su Internet ho ragionato sui framework API in cui bisogna configurare, integrare e implementare svariate funzioni distinte:
- Sicurezza
- Autorizzazioni e Autenticazione
- Limitazione e controllo delle chiamate
- Monitoraggio e analisi
- Gestione log

Quindi all'inizio ho pensato ad alcuni framework API open source, personalizzabili, modulari e realizzabili in infrastrutture on-premise per poi scegliere di utilizzare i servizi cloud managed.\
Data la complessità delle possibili soluzioni on-prem e la mia mancanza di tempo per studiarle e farle bene ho deciso di implementare una soluzione serverless basata su AWS VPN, VPC, API Gateway, Amazon Cognito e CloudWatch.

La scelta l'ho fatta valutando:
- Velocitá di deploy
- Integrazione
- Scalabilitá
- Fatturazione

Per la connessione criptata e sicura useró AWS Site-to-site VPN, che collegerá il Gateway Router della rete dove risiede il server Odin01 alla VPC.
Per la configurazione del Customer Router si possono usare le istruzioni base in [Customer Router\Customer router config.txt](Customer Router\Customer router config.txt).
Oppure quelle specifiche per marca e modello del dispositivo che sono scaricabili dal template pre-configurato di AWS VPN Connections.




HTTP SERVER
DEFAULT GATEWAY DEVICE: Internet Key Exchange per associare e stabilirie 2 tunnel IPsec (1 backup)  
AWS Site-to-Site VPN
AWS VPC
