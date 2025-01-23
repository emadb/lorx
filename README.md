# Lorx

## TODO
- Migliorare gestione soglia (isteresi)
x Lorx.Device: Testare la logica per ridurre al minimo le chiamate
- Scheda termostato dashboard
  x Mostrare stato accensione
  x Mostrare temperatura desiderata
  - Mostrare schedulazione?
- Grafico andamento temperatura
- API per lettura temperatura esterna
x Introdurre struct per dati notifica (device_id, temp, target_temp, current_temp, ....)
x Al primo caricamento non mostra i dati fino al successivo :check_temp (Device genserver)
- Design scheda termostato
- Autenticazione
x Deploy
- Auto/Manual mode: se in manual si accende/spegne manualmente, in auto segue lo schedule