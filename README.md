# F5GO-Mihomo-stuff

![GitHub](https://img.shields.io/badge/GitHub-F5GO--Mihomo--stuff-black?style=for-the-badge&logo=github)
![OpenWrt](https://img.shields.io/badge/OpenWrt-Latest-blue?style=for-the-badge&logo=openwrt)
![Mihomo](https://img.shields.io/badge/Mihomo-Clash.Meta-9cf?style=for-the-badge)
![YAML](https://img.shields.io/badge/Format-YAML-red?style=for-the-badge&logo=yaml)

Небольшой репозиторий с:

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

## Заметки по списку Bosch Home Connect

Список доменов (domail list) [bosch-home-connect.yaml](domains-list/bosch-home-connect.yaml) предназначен для умной техники Bosch Home Connect. В моих условиях он не дал стабильного результата: либо у Bosch периодические сбои, либо сильно ужесточена проверка региона/сети.

## Контакты

Проект создан и развивается при поддержке сообщества **F5GO.ONE**.

- YouTube: https://youtube.com/@F5GO
- Сайт: https://f5go.one
- Telegram: https://t.me/f5gou
- VK: https://vk.ru/f5gou

## Дисклеймер

Материалы в этом репозитории опубликованы в образовательных и развлекательных целях. Используйте на свой страх и риск и соблюдайте законы вашей страны и правила провайдеров/сервисов.

## Лицензия

MIT.

