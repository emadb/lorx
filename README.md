# Lorx

## TODO
- Scheda termostato dashboard
  - Mostrare stato accensione
  - Mostrare temperatura desiderata
  - Mostrare schedulazione?
- Grafico andamento temperatura
- API per lettura temperatura esterna
- Migliorare gestione soglia (isteresi)
- Lorx.Device: Testare la logica per ridurre al minimo le chiamate
- Introdurre struct per dati notifica (device_id, temp, target_temp, current_temp, ....)
- Al primo caricamento non mostra i dati fino al successivo :check_temp (Device genserver)
- Design scheda termostato