# StumpWM iwd

StumpWM module for iwd (iNet wireless daemon).

The module operates in a non-blocking manner, utilizing a separate thread to interact with iwd via DBUS.

## Requirements

- [IWD](https://iwd.wiki.kernel.org/) daemon installed
- [DBUS](https://github.com/death/dbus) library

## Installation

```bash
cd ~/.stumpwm.d/modules/
git clone https://github.com/Junker/stumpwm-iwd iwd
```
`
```common-lisp
(stumpwm:add-to-load-path "~/.stumpwm.d/modules/iwd")
(load-module "iwd")
```

## Usage

```common-lisp
(iwd:init)
(setf stumpwm:*screen-mode-line-format* "... %I ...")
```

### Parameters

- `iwd:*check-interval*` - Interval in seconds for wifi status check (Default: 3). 

## Modeline

`%I` -  formatter

### Parameters for modeline

- `iwd:*modeline-fmt*` - format of iwd modeline (default: `%e %p`)
  - `%e` - Network ESSID
  - `%p` - Signal quality
