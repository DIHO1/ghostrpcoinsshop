# Ghost Market

Zaawansowany sklep premium dla serwera FiveM z walutą Ghost Coin oraz futurystycznym interfejsem typu tablet.

## Wymagania
- [ESX](https://github.com/esx-framework/esx-legacy)
- [oxmysql](https://github.com/overextended/oxmysql)
- Skonfigurowane połączenie `setr mysql_connection_string` w `server.cfg`

## Instalacja
1. Skopiuj zasób do katalogu `resources/[local]/ghostmarket`.
2. Dodaj do `server.cfg`:
   ```cfg
   ensure ghostmarket
   ```
3. Upewnij się, że `oxmysql` uruchamia się przed `ghostmarket`.

Przy pierwszym starcie zasób samodzielnie utworzy tabele `ghost_shop_wallet` (saldo monet) oraz `ghost_shop_state` (trwałość licznika wydarzenia).

## Uprawnienia ACE
Domyślne komendy administracyjne wymagają flagi ACE `ghostmarket.admin`. Dodaj ją do swojej konfiguracji uprawnień, np. w `server.cfg` lub `permissions.cfg`:
```cfg
add_ace group.admin ghostmarket.admin allow        # nadaj dostęp całej grupie
add_principal identifier.steam:110000112345678 group.admin   # przypisz konkretnego gracza do grupy
```
> Możesz też pominąć grupy i użyć bezpośrednio `add_ace identifier.steam:110000112345678 ghostmarket.admin allow`.

Jeżeli zmienisz nazwę flagi w `Config.Admin.requiredAce` lub `Config.EventTimer.requiredAce`, zaktualizuj wpisy ACE odpowiednio. Po starcie zasobu w konsoli pojawią się instrukcje z aktualną nazwą wymaganej flagi.

## Dostępne komendy
- `/market` – otwiera tablet Ghost Market (domyślnie również pod klawiszem **F7**).
- `/ghostcoins <add|remove|set|show>` – zarządzanie saldem graczy. Wspiera identyfikatory ESX (steam, license) oraz ID gracza na serwerze.
- `/marketevent <set|show|clear>` – zarządzanie licznikiem wydarzenia widocznym na ekranie startowym tabletu. Komenda przyjmuje formaty czasu typu `2h30m`, `90` (minuty) lub `01:30:00`.

## Konfiguracja zasobu
W pliku [`config.lua`](config.lua) znajdziesz:
- definicję waluty (nazwa, symbol, kolor),
- ustawienia anty-spam (cooldown zakupów),
- układ tabletu (`Config.Layout`) – hero sekcja, sekcje katalogu, wyróżnione elementy,
- pełną listę produktów (`Config.ShopItems`) w tym skrzynki z wagami dropów, pojazdy, usługi i boosty.

Dostosuj strukturę według potrzeb – każdy produkt posiada `rewardData` przekazywane do serwera (`item`, `money`, `group`, `vehicle` oraz `crate`).

## Interfejs NUI
- Pełnoekranowe tło wykorzystuje grafikę Franklina z lekkim rozmyciem i neonową warstwą.
- Tablet wyświetla saldo, hero sekcję z licznikiem, katalog z filtrowaniem, log aktywności i animacje otwierania skrzynek.
- Zakupy wymagają potwierdzenia w modalnym oknie, a interfejs można zamknąć przyciskiem, komendą lub klawiszem **ESC**.

## Integracje nagród
- `item` – używa `xPlayer.addInventoryItem`.
- `money` – wspiera konta `money` oraz `black_money`.
- `group` – nadaje uprawnienia komendą `ExecuteCommand('add_ace ...')` (dopasuj do własnego systemu uprawnień).
- `vehicle` – loguje informacje o pojeździe; wymaga integracji z Twoim systemem garażu.
- `crate` – rozwija skrzynkę, losuje nagrody według wag i wysyła wynik do klienta wraz z animacją.

## Rozwiązywanie problemów
- Brak salda lub błędy SQL? Sprawdź połączenie `oxmysql` i upewnij się, że baza zawiera tabelę `ghost_shop_wallet`.
- Komendy zwracają błąd „Odmowa dostępu”? Zweryfikuj wpisy ACE i upewnij się, że gracz ma przypisaną odpowiednią grupę lub identyfikator.
- Interfejs się nie otwiera? Upewnij się, że NUI ma dostęp do plików (`fxmanifest.lua`) i że zasób jest uruchomiony po ESX.
