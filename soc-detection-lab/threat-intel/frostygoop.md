# FrostyGoop – ICS-angrep (Lviv, januar 2024)

**Konsekvens:** Oppvarming til 600+ bygninger avbrutt i sub-null temperaturer.

## Kill Chain
```
T0819  Exploit sårbar ruter → fotfeste i IT-nettverk
T1003  SAM-data kompromittert etter måneder
T0869  Modbus TCP (port 502) → direkte til ENCO-kontrollere
T0831  Temperaturregulering deaktiveres
```

## Hvorfor Modbus er sårbart

| Egenskap | Konsekvens |
|----------|------------|
| Ingen autentisering | Hvem som helst kan sende kommandoer |
| Ingen kryptering | All trafikk er klartekst |
| Designet 1979 | Sikkerhet var ikke prioritert |

## Svakheter

| Svakhet | NIST CSF |
|---------|----------|
| Sårbar ruter eksponert | Identify |
| Ingen IT/OT-segmentering | Protect |
| Ingen OT-overvåking | Detect |

**Tilskrivelse:** Moskva-basert IP, januar 2024. NSM peker på Russland.
