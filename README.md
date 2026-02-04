# StumpWM iwd

StumpWM module for iwd (iNet wireless daemon)

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
```

### Parameters

- `iwd:*check-interval*` - Interval in seconds for battery check (Default: 3). 

## Modeline

`%I` -  formatter

### Parameters for modeline

- `iwd:*modeline-fmt*` - format of IWD modeline (default: "%e %p")
  - `%e` - Network ESSID
  - `%p` - Signal quality
