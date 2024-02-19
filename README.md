# A minimal example of Solving ODEs with data-parallel MPI

This is based on [these tests](https://github.com/jipolanco/PencilArrays.jl/blob/master/test/ode.jl
), 
with some changes to adapt it to my goals at the moment.

## Setup
### MPI preferences
It is necessary, among the usual things,
to configure MPI using `MPIPreferences.use_system_binary()`,
and restart Julia (as suggested in the 
[docs](https://juliaparallel.org/MPI.jl/stable/reference/mpipreferences/#MPIPreferences.use_system_binary)).
### tmux-MPI

`tmux-mpi` is a super cool tool that allows to run multiple MPI processes
having each process in its own tmux window or pane.
It might require to memorize a few shortcuts to work with tmux,
but it is definitely worth the effort.

To set it up, follow the instructions 
[at its github repository](https://github.com/wrs20/tmux-mpi),
creating a python virtual environment
using the `requirement.txt` file provided.

If you have set up your environment as I have,
you can launch it with, e.g.: 

``` sh
$ ./tmux-mpi/launch.sh 2 julia --project=.
```

In the launch.sh script
the environment variables are set so that
a pane is created for each MPI rank
(in this case, 2 ranks)
and that the standard input is broadcast
to all the MPI processes.
