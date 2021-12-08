#!/usr/bin/env zsh
if [ ! -z "$1" ];
then
    if [ $1 = 'bench' ]; then
        julia -t 1 /home/manuel/juliachessengine/uci.jl bench
    else
        julia -t 1 /home/manuel/juliachessengine/uci.jl
    fi
else
    julia -t 1 /home/manuel/juliachessengine/uci.jl
fi