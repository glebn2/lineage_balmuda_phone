# LineageOS 24.0 for BALMUDA Phone (unofficial)

**English** | [Русский](#русский)

Unofficial LineageOS 24.0 (Android 17) for BALMUDA Phone. One image for A101BM and X01A; the device
codename is `A101BM`.

Builds, TWRP and discussion (Russian): [4PDA thread](https://4pda.to/forum/index.php?showtopic=1068017),
[downloads](https://4pda.to/forum/index.php?showtopic=1068017&view=findpost&p=145680258).

## Install

Downloads: [Releases](https://github.com/glebn2/lineage_balmuda_phone/releases). Take the
`…-TWRP.zip`; the `…-OTA.zip` is for the built-in Updater only and cannot be installed from TWRP.
TWRP image: [twrp_device_balmuda_A101BM releases](https://github.com/glebn2/twrp_device_balmuda_A101BM/releases).

1. Unlock the bootloader. One-button tool: [balmunlock](https://github.com/glebn2/balmunlock).
2. Flash TWRP to both recovery partitions, so it stays available whichever slot is active
   (updates switch slots):

   ```bash
   fastboot flash recovery_a TWRP-3.7.1_12-BALMUDA_Phone-<date>.img
   fastboot flash recovery_b TWRP-3.7.1_12-BALMUDA_Phone-<date>.img
   fastboot reboot recovery
   ```

3. In TWRP: Install → the `…-TWRP.zip`. It writes the active slot; the other slot keeps stock
   until the first update.
4. First install over stock wipes data:
   - zip copied to internal storage: after the zip (and GApps, if any) do Wipe → Format Data, type
     `yes`, then reboot;
   - zip from `adb sideload` or USB-OTG: the zip wipes data itself.
5. Reboot → System.

Updates: Settings → System → System updates (A/B, installs into the other slot, data kept, TWRP stays).
A newer `…-TWRP.zip` can also be installed from TWRP over LineageOS; data is kept.

GApps and Magisk survive OTA updates from 24.0-test6 on: the build keeps the Play services that TWRP
moved out of the MindTheGapps APEX. If Play services crash after an update anyway: TWRP → Install →
MindTheGapps → Reboot → System.

## Repositories

| Path | Repository |
|---|---|
| `device/balmuda/A101BM` | [android_device_balmuda_A101BM](https://github.com/glebn2/android_device_balmuda_A101BM) |
| `vendor/balmuda` | [proprietary_vendor_balmuda](https://github.com/glebn2/proprietary_vendor_balmuda) |
| `kernel/balmuda/A101BM` | [LineageOS/android_kernel_motorola_sm7250](https://github.com/LineageOS/android_kernel_motorola_sm7250), UAPI headers only |

This repository has the local manifest, build and signing scripts, and the TWRP installer.
TWRP for BALMUDA Phone: [twrp_device_balmuda_A101BM](https://github.com/glebn2/twrp_device_balmuda_A101BM).

## Build

Set up the build environment as described in the LineageOS wiki, then:

```bash
git clone https://github.com/glebn2/lineage_balmuda_phone ~/lineage_balmuda_phone
mkdir -p ~/lineage && cd ~/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs --no-clone-bundle
mkdir -p .repo/local_manifests
cp ~/lineage_balmuda_phone/local_manifests/balmuda_phone.xml .repo/local_manifests/
repo sync -c --no-tags
~/lineage_balmuda_phone/scripts/build.sh
```

`build.sh` applies `device/balmuda/A101BM/patches` first. Revert them before `repo sync`:

```bash
device/balmuda/A101BM/patches/apply-patches.sh --revert
```

TWRP zip from a test-key build:

```bash
ANDROID_BUILD_TOP=~/lineage python3 ~/lineage_balmuda_phone/twrp-zip/build_lineage_zip.py \
  24.0-$(date +%Y%m%d)-UNOFFICIAL lineage-BALMUDA_Phone-TWRP.zip ~/lineage/out/target/product/A101BM
```

Signed release:

```bash
~/lineage_balmuda_phone/scripts/build.sh target-files-package otatools
~/lineage_balmuda_phone/scripts/sign_release.sh 24.0-$(date +%Y%m%d) ~/lineage-release
```

## Notes

- Stock Kyocera 4.19 kernel, DTB, DTBO and modules. The patches make the BPF and kernel version
  checks of Android 17 non-fatal on 4.19.
- The boot image keeps the stock header version (11.0.0 / 2023-09) so TWRP can decrypt `/data`.
- SELinux is permissive; vbmeta verification is disabled.

## License

Apache-2.0. `gps/` in the device tree keeps its own license headers. Proprietary files belong to
their respective owners.

---

## Русский

Неофициальная LineageOS 24.0 (Android 17) для BALMUDA Phone. Один образ для A101BM и X01A,
кодовое имя устройства — `A101BM`.

Сборки, TWRP и обсуждение: [тема на 4PDA](https://4pda.to/forum/index.php?showtopic=1068017),
[загрузки](https://4pda.to/forum/index.php?showtopic=1068017&view=findpost&p=145680258).

### Установка

Загрузки: [Releases](https://github.com/glebn2/lineage_balmuda_phone/releases). Нужен
`…-TWRP.zip`; `…-OTA.zip` — только для встроенного обновления, из TWRP он не ставится.
Образ TWRP: [релизы twrp_device_balmuda_A101BM](https://github.com/glebn2/twrp_device_balmuda_A101BM/releases).

1. Разблокировать загрузчик. Утилита разблокировки в одну кнопку: [balmunlock](https://github.com/glebn2/balmunlock).
2. Прошить TWRP в оба раздела recovery, чтобы он оставался доступен при любом активном слоте
   (обновления переключают слоты):

   ```bash
   fastboot flash recovery_a TWRP-3.7.1_12-BALMUDA_Phone-<дата>.img
   fastboot flash recovery_b TWRP-3.7.1_12-BALMUDA_Phone-<дата>.img
   fastboot reboot recovery
   ```

3. В TWRP: Install → `…-TWRP.zip`. Пишется активный слот, второй остаётся стоковым до первого
   обновления.
4. Первая установка поверх стока стирает данные:
   - zip во внутренней памяти — после него (и GApps, если нужны) Wipe → Format Data, ввести `yes`,
     затем перезагрузка;
   - zip через `adb sideload` или USB-OTG — данные стирает сам zip.
5. Reboot → System.

Обновления: Настройки → Система → Обновления системы (A/B, ставятся во второй слот, данные и TWRP
сохраняются). Новый `…-TWRP.zip` тоже можно поставить из TWRP поверх LineageOS без потери данных.

GApps и Magisk переживают обновление по воздуху начиная с 24.0-test6: сборка сохраняет Play services,
которые TWRP перенёс из APEX MindTheGapps. Если после обновления Play services всё же падают:
TWRP → Install → MindTheGapps → Reboot → System.

### Репозитории

| Путь | Репозиторий |
|---|---|
| `device/balmuda/A101BM` | [android_device_balmuda_A101BM](https://github.com/glebn2/android_device_balmuda_A101BM) |
| `vendor/balmuda` | [proprietary_vendor_balmuda](https://github.com/glebn2/proprietary_vendor_balmuda) |
| `kernel/balmuda/A101BM` | [LineageOS/android_kernel_motorola_sm7250](https://github.com/LineageOS/android_kernel_motorola_sm7250), только заголовки UAPI |

В этом репозитории — локальный манифест, скрипты сборки и подписи, установщик для TWRP.
TWRP для BALMUDA Phone: [twrp_device_balmuda_A101BM](https://github.com/glebn2/twrp_device_balmuda_A101BM).

### Сборка

Подготовить окружение по вики LineageOS, затем выполнить команды из раздела [Build](#build).
`build.sh` сначала применяет `device/balmuda/A101BM/patches`; перед `repo sync` их нужно откатить
(`device/balmuda/A101BM/patches/apply-patches.sh --revert`).

### Примечания

- Штатное ядро Kyocera 4.19, DTB, DTBO и модули. Патчи делают проверки BPF и версии ядра в Android 17
  нефатальными на 4.19.
- В заголовке boot-образа сохранена стоковая версия (11.0.0 / 2023-09), чтобы TWRP расшифровывал `/data`.
- SELinux в режиме permissive, проверка vbmeta отключена.

### Лицензия

Apache-2.0. `gps/` в дереве устройства сохраняет собственные заголовки лицензий. Проприетарные файлы
принадлежат их правообладателям.
