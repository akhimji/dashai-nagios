#!/bin/bash
find / -group apache ! -path "/proc/*"  -exec chown nagios:nagios {} +
find / -user  apache  ! -path "/proc/*" -exec chown nagios:nagios {} +
