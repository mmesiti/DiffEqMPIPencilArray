#!/bin/bash
DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "$DIR/venv/bin/activate"
which tmux-mpi

export TMUX_MPI_SYNC_PANES=1
export TMUX_MPI_MODE=pane
tmux-mpi "$@"
