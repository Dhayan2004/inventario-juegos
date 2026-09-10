# Monedas — exponente ISO 4217 (GENERADO — no editar a mano)

> Fuente: `vendor/pagokit/data/currencies.json` (PagoKit 0.2.2, MIT). Regenerar con
> `bash scripts/sync-pagokit-catalog.sh`. Cita: `[memory:references#R-012]`.
>
> **Regla (PAY-004):** el monto en unidades menores es `amount × 10^exponent`, **nunca** `amount * 100` a
> ciegas. Con exponente 0 (`BIF` · `CLP` · `DJF` · `GNF` · `ISK` · `JPY` · `KMF` · `KRW` · `PYG` · `RWF` · `UGX` · `VND` · `VUV` · `XAF` · `XOF` · `XPF`) `* 100` es un sobrecobro de 100× que ningún test lanza.

| Código | Nombre | Exponente | Cero decimales |
|---|---|---:|---|
| `AED` | UAE Dirham | 2 |  |
| `AMD` | Armenian Dram | 2 |  |
| `AOA` | Angolan Kwanza | 2 |  |
| `ARS` | Argentine Peso | 2 |  |
| `AUD` | Australian Dollar | 2 |  |
| `AZN` | Azerbaijani Manat | 2 |  |
| `BDT` | Bangladeshi Taka | 2 |  |
| `BGN` | Bulgarian Lev | 2 |  |
| `BHD` | Bahraini Dinar | 3 |  |
| `BIF` | Burundian Franc | 0 | **sí — nunca `* 100`** |
| `BND` | Brunei Dollar | 2 |  |
| `BOB` | Bolivian Boliviano | 2 |  |
| `BRL` | Brazilian Real | 2 |  |
| `BWP` | Botswana Pula | 2 |  |
| `BZD` | Belize Dollar | 2 |  |
| `CAD` | Canadian Dollar | 2 |  |
| `CHF` | Swiss Franc | 2 |  |
| `CLP` | Chilean Peso | 0 | **sí — nunca `* 100`** |
| `CNY` | Chinese Yuan | 2 |  |
| `COP` | Colombian Peso | 2 |  |
| `CRC` | Costa Rican Colon | 2 |  |
| `CUP` | Cuban Peso | 2 |  |
| `CZK` | Czech Koruna | 2 |  |
| `DJF` | Djiboutian Franc | 0 | **sí — nunca `* 100`** |
| `DKK` | Danish Krone | 2 |  |
| `DOP` | Dominican Peso | 2 |  |
| `DZD` | Algerian Dinar | 2 |  |
| `EGP` | Egyptian Pound | 2 |  |
| `ETB` | Ethiopian Birr | 2 |  |
| `EUR` | Euro | 2 |  |
| `GBP` | Pound Sterling | 2 |  |
| `GEL` | Georgian Lari | 2 |  |
| `GHS` | Ghanaian Cedi | 2 |  |
| `GNF` | Guinean Franc | 0 | **sí — nunca `* 100`** |
| `GTQ` | Guatemalan Quetzal | 2 |  |
| `HKD` | Hong Kong Dollar | 2 |  |
| `HNL` | Honduran Lempira | 2 |  |
| `HTG` | Haitian Gourde | 2 |  |
| `HUF` | Hungarian Forint | 2 |  |
| `IDR` | Indonesian Rupiah | 2 |  |
| `ILS` | Israeli New Shekel | 2 |  |
| `INR` | Indian Rupee | 2 |  |
| `IQD` | Iraqi Dinar | 3 |  |
| `IRR` | Iranian Rial | 2 |  |
| `ISK` | Icelandic Krona | 0 | **sí — nunca `* 100`** |
| `JMD` | Jamaican Dollar | 2 |  |
| `JOD` | Jordanian Dinar | 3 |  |
| `JPY` | Japanese Yen | 0 | **sí — nunca `* 100`** |
| `KES` | Kenyan Shilling | 2 |  |
| `KHR` | Cambodian Riel | 2 |  |
| `KMF` | Comorian Franc | 0 | **sí — nunca `* 100`** |
| `KPW` | North Korean Won | 2 |  |
| `KRW` | South Korean Won | 0 | **sí — nunca `* 100`** |
| `KWD` | Kuwaiti Dinar | 3 |  |
| `KZT` | Kazakhstani Tenge | 2 |  |
| `LBP` | Lebanese Pound | 2 |  |
| `LKR` | Sri Lankan Rupee | 2 |  |
| `LYD` | Libyan Dinar | 3 |  |
| `MAD` | Moroccan Dirham | 2 |  |
| `MGA` | Malagasy Ariary | 1 |  |
| `MMK` | Myanmar Kyat | 2 |  |
| `MRU` | Mauritanian Ouguiya | 1 |  |
| `MUR` | Mauritian Rupee | 2 |  |
| `MXN` | Mexican Peso | 2 |  |
| `MYR` | Malaysian Ringgit | 2 |  |
| `MZN` | Mozambican Metical | 2 |  |
| `NGN` | Nigerian Naira | 2 |  |
| `NIO` | Nicaraguan Cordoba | 2 |  |
| `NOK` | Norwegian Krone | 2 |  |
| `NPR` | Nepalese Rupee | 2 |  |
| `NZD` | New Zealand Dollar | 2 |  |
| `OMR` | Omani Rial | 3 |  |
| `PAB` | Panamanian Balboa | 2 |  |
| `PEN` | Peruvian Sol | 2 |  |
| `PHP` | Philippine Peso | 2 |  |
| `PKR` | Pakistani Rupee | 2 |  |
| `PLN` | Polish Zloty | 2 |  |
| `PYG` | Paraguayan Guarani | 0 | **sí — nunca `* 100`** |
| `QAR` | Qatari Riyal | 2 |  |
| `RON` | Romanian Leu | 2 |  |
| `RSD` | Serbian Dinar | 2 |  |
| `RUB` | Russian Ruble | 2 |  |
| `RWF` | Rwandan Franc | 0 | **sí — nunca `* 100`** |
| `SAR` | Saudi Riyal | 2 |  |
| `SEK` | Swedish Krona | 2 |  |
| `SGD` | Singapore Dollar | 2 |  |
| `SYP` | Syrian Pound | 2 |  |
| `THB` | Thai Baht | 2 |  |
| `TND` | Tunisian Dinar | 3 |  |
| `TRY` | Turkish Lira | 2 |  |
| `TTD` | Trinidad and Tobago Dollar | 2 |  |
| `TWD` | New Taiwan Dollar | 2 |  |
| `TZS` | Tanzanian Shilling | 2 |  |
| `UAH` | Ukrainian Hryvnia | 2 |  |
| `UGX` | Ugandan Shilling | 0 | **sí — nunca `* 100`** |
| `USD` | US Dollar | 2 |  |
| `UYU` | Uruguayan Peso | 2 |  |
| `UZS` | Uzbekistani Som | 2 |  |
| `VES` | Venezuelan Bolivar | 2 |  |
| `VND` | Vietnamese Dong | 0 | **sí — nunca `* 100`** |
| `VUV` | Vanuatu Vatu | 0 | **sí — nunca `* 100`** |
| `XAF` | Central African CFA Franc | 0 | **sí — nunca `* 100`** |
| `XOF` | West African CFA Franc | 0 | **sí — nunca `* 100`** |
| `XPF` | CFP Franc | 0 | **sí — nunca `* 100`** |
| `ZAR` | South African Rand | 2 |  |
| `ZMW` | Zambian Kwacha | 2 |  |
