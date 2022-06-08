#!/bin/bash

# 2022.06.08 - v. 0.3 - dodalem par2 do monitorowanych komend
# 2021.11.04 - v. 0.2 - zmiana watch na "progress -M"
# 2021.09.19 - v. 0.1 - inicjalna wersja skryptu

progress --monitor-continuously --additional-command par2 --wait --wait-delay 0.5
