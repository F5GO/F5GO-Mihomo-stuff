# F5GO-Mihomo-stuff

![GitHub](https://img.shields.io/badge/GitHub-F5GO--Mihomo--stuff-black?style=for-the-badge&logo=github)
![OpenWrt](https://img.shields.io/badge/OpenWrt-Latest-blue?style=for-the-badge&logo=openwrt)
![Mihomo](https://img.shields.io/badge/Mihomo-Clash.Meta-9cf?style=for-the-badge)
![YAML](https://img.shields.io/badge/Format-YAML-red?style=for-the-badge&logo=yaml)

## Дисклеймер

Материалы в этом репозитории опубликованы в образовательных и развлекательных целях. Используйте на свой страх и риск и соблюдайте законы вашей страны и правила провайдеров/сервисов.

## Небольшой репозиторий с:

- моими списками доменов под Mihomo (Clash.Meta) / Clash (формат `rule-providers`);
- шаблонами конфигов для OpenWrt-сервисов SSClash и Nikki (оба используют ядро Mihomo);
- вспомогательными списками подсетей (например, Telegram).

Цель — быстро собрать рабочую конфигурацию на роутере/шлюзе и удобно обновлять правила по ссылкам (rule-providers через `type: http`).

Разработано для сообщества **F5GO.ONE**.

- Сайт: https://f5go.one
- YouTube: https://youtube.com/@F5GO
- Telegram: https://t.me/f5gou
- VK: https://vk.ru/f5gou

## Структура

- [config-templates](config-templates) — готовые YAML-конфиги Mihomo под разные сценарии:
  - [ssclash.yaml](config-templates/ssclash.yaml) / [ssclash-white-list.yaml](config-templates/ssclash-white-list.yaml)
  - [openwrt-nikki.yaml](config-templates/openwrt-nikki.yaml) / [openwrt-nikki-white-list.yaml](config-templates/openwrt-nikki-white-list.yaml)
- [domains-list](domains-list) — локальные списки доменов (rule-set):
  - [google_ai.yaml](domains-list/google_ai.yaml) — Google AI / Gemini (собран на основе списков [itDog](https://github.com/itdoginfo/allow-domains), адаптирован под сервисные домены)
  - [trae.yaml](domains-list/trae.yaml) — домены Trae
  - [bosch-home-connect.yaml](domains-list/bosch-home-connect.yaml) — Bosch Home Connect (в моём кейсе пока нестабильно/не побеждено)
- [subnets](subnets) — списки подсетей:
  - [telegram-ip.txt](subnets/telegram-ip.txt)
- [scripts](scripts) — вспомогательные скрипты для OpenWrt / Mihomo:
  - [ssclash-memory-limit.sh](scripts/ssclash-memory-limit.sh) — ограничение потребления памяти Mihomo в SSClash через настройки Go Runtime.

## Формат списков доменов

Файлы в [domains-list](domains-list) — это «классические» ruleset-файлы для Mihomo/Clash:

```yaml
payload:
  - DOMAIN-SUFFIX,example.com
  - DOMAIN,api.example.com
  - DOMAIN-KEYWORD,example
```

Такие файлы подключаются через `rule-providers` с `behavior: classical`.

Пример подключения по URL (чтобы обновлялось автоматически):

```yaml
rule-providers:
  google-ai:
    type: http
    behavior: classical
    url: "https://raw.githubusercontent.com/F5GO/F5GO-Mihomo-stuff/refs/heads/main/domains-list/google_ai.yaml"
    interval: 43200
    path: ./ruleset/google-ai.yaml
```

Дальше используете в `rules`:

```yaml
rules:
  - RULE-SET,google-ai,AI
```

## Шаблоны конфигов (SSClash / Nikki)

В [config-templates](config-templates) лежат конфиги, которые можно:

- вставить как основной конфиг Mihomo внутри SSClash/Nikki;
- использовать как основу и допилить под себя (DNS, rule-providers, прокси, группы).

Что обычно нужно заменить в первую очередь:

- `proxies`: свои ноды/подписки, ключи/пароли, адреса серверов;
- `log-level`: под отладку можно временно поднять до `info`.

В шаблоны добавлены бесплатные прокси как «стартовый» вариант. Они не гарантируют стабильность и производительность, поэтому для нормальной работы рекомендую заменить их на свои ноды/подписки.

## Что означает `*-white-list.yaml` в этом репозитории

`*-white-list.yaml` — это шаблоны с включённым Fake-IP, где Fake-IP применяется избирательно (только к выбранным доменам/RuleSet’ам).

Идея такая:

- обычные шаблоны (`ssclash.yaml`, `openwrt-nikki.yaml`) не включают выборочный Fake-IP;
- варианты `*-white-list.yaml` включают Fake-IP и описывают, для каких доменов выдавать fake-ip, а для каких — real-ip.

Почему так: некоторым сервисам/сайтам Fake-IP помогает стабильнее работать в условиях DNS-подмен/блокировок, а включать Fake-IP «на всё» иногда не хочется.

Технически:

- `ssclash-white-list.yaml` использует `dns.fake-ip-filter-mode: whitelist` — Fake-IP выдаётся только при успешном совпадении с `fake-ip-filter`.
- `openwrt-nikki-white-list.yaml` использует `dns.fake-ip-filter-mode: rule` — вы сами задаёте, где `fake-ip`, а где `real-ip`, последняя строка (`MATCH,real-ip`) делает Real-IP поведением по умолчанию.

Коротко: Fake-IP влияет на DNS-ответ (какие IP получит клиент), а маршрутизация трафика определяется правилами (`rules`) и настройками самого сервиса (SSClash/Nikki) на уровне OpenWrt.

## Быстрый старт

### SSClash (OpenWrt)

1. Возьмите шаблон [ssclash.yaml](config-templates/ssclash.yaml) или [ssclash-white-list.yaml](config-templates/ssclash-white-list.yaml).
2. Замените секцию `proxies` под свои ноды (и всё, что помечено как «поменяйте»).
3. Проверьте, что в `rule-providers` прописаны нужные URL/пути и совпадают имена rule-set’ов с тем, что используется в `rules`.
4. Перезапустите сервис и откройте панель (external-ui), проверьте, что rule-providers скачались.

### Nikki (OpenWrt)

1. Возьмите [openwrt-nikki.yaml](config-templates/openwrt-nikki.yaml) или [openwrt-nikki-white-list.yaml](config-templates/openwrt-nikki-white-list.yaml).
2. Замените секцию `proxies` под свои ноды.
3. Проверьте `rules`: catch-all правило здесь — `MATCH,GLOBAL`, то есть «всё остальное» уйдёт в глобальную политику/группу, выбранную в UI.

## Ограничение потребления RAM Mihomo в SSClash

На OpenWrt-роутерах с небольшим объёмом оперативной памяти **Mihomo** может занимать значительную часть доступной RAM. Особенно заметно это на устройствах с **256 МБ RAM**, где рост потребления памяти может привести к сильному замедлению или зависанию роутера.

Для таких устройств в репозитории есть скрипт:

[`scripts/ssclash-memory-limit.sh`](scripts/ssclash-memory-limit.sh)

Он добавляет в `procd`-сервис SSClash две настройки **Go Runtime**:

```text
GOGC=50
GOMEMLIMIT=96MiB
```

### Что они делают

#### `GOGC=50`

Заставляет Garbage Collector Go запускаться чаще.

Стандартное значение Go — `100`. Значение `50` уменьшает допустимый рост heap между циклами GC, снижая потребление памяти ценой небольшого увеличения нагрузки на CPU.

#### `GOMEMLIMIT=96MiB`

Устанавливает **soft memory limit** для Go Runtime. При приближении к лимиту Go начинает агрессивнее освобождать память.

> **Важно:** `GOMEMLIMIT` — не жёсткий лимит RSS процесса. Mihomo всё равно может использовать больше указанного объёма, поскольку RSS включает память, которая не учитывается непосредственно лимитом Go Runtime.

### Быстрая установка

Подключитесь к OpenWrt по SSH и выполните:

```sh
wget -qO /tmp/ssclash-memory-limit.sh https://raw.githubusercontent.com/F5GO/F5GO-Mihomo-stuff/main/scripts/ssclash-memory-limit.sh && chmod +x /tmp/ssclash-memory-limit.sh && /tmp/ssclash-memory-limit.sh
```

По умолчанию будут установлены:

```text
GOGC=50
GOMEMLIMIT=96MiB
```

Это стартовые значения, рассчитанные прежде всего на OpenWrt-устройства с **256 МБ RAM**.

Скрипт:

1. проверяет наличие SSClash;
2. создаёт резервную копию `/etc/init.d/ssclash`;
3. добавляет `GOGC` и `GOMEMLIMIT` в окружение `procd`;
4. перезапускает SSClash;
5. ждёт запуска Mihomo;
6. проверяет, что Mihomo действительно унаследовал заданные переменные;
7. показывает текущее потребление памяти Mihomo и системы.

### Свои значения

Можно передать `GOGC` и `GOMEMLIMIT` аргументами.

Например:

```sh
/tmp/ssclash-memory-limit.sh 50 128MiB
```

установит:

```text
GOGC=50
GOMEMLIMIT=128MiB
```

### Проверка

Проверить, что настройки действительно применились к Mihomo:

```sh
PID=$(pgrep -f '^/opt/clash/bin/clash ')
cat /proc/$PID/environ | tr '\0' '\n' | grep -E '^(GOGC|GOMEMLIMIT)='
```

Должно появиться:

```text
GOGC=50
GOMEMLIMIT=96MiB
```

Текущее реальное потребление памяти Mihomo можно посмотреть так:

```sh
PID=$(pgrep -f '^/opt/clash/bin/clash ')
grep -E 'VmRSS|RssAnon|RssFile|VmData' /proc/$PID/status
free -h
```

### Откат

Скрипт сохраняет исходный init-файл SSClash:

```text
/etc/init.d/ssclash.bak
```

Вернуть исходную конфигурацию:

```sh
cp /etc/init.d/ssclash.bak /etc/init.d/ssclash
/etc/init.d/ssclash restart
```

> **Примечание:** после обновления или переустановки SSClash файл `/etc/init.d/ssclash` может быть перезаписан. В таком случае скрипт можно запустить повторно.

## Заметки по списку Bosch Home Connect

Список доменов (domail list) [bosch-home-connect.yaml](domains-list/bosch-home-connect.yaml) предназначен для умной техники Bosch Home Connect. В моих условиях он не дал стабильного результата: либо у Bosch периодические сбои, либо сильно ужесточена проверка региона/сети.

## Контакты

Проект создан и развивается при поддержке сообщества **F5GO.ONE**.

- YouTube: https://youtube.com/@F5GO
- Сайт: https://f5go.one
- Telegram: https://t.me/f5gou
- VK: https://vk.ru/f5gou


## Лицензия

MIT.

