macro mpi_synchronize(expr)
    quote
        begin
            comm = MPI.COMM_WORLD
            rank = MPI.Comm_rank(comm)
            nranks = MPI.Comm_size(comm)
            for r in 0:(nranks-1)
                if rank == r
                    print("[$rank/$nranks]: ")
                    $(esc(expr))
                end
                if MPI.Initialized()
                    MPI.Barrier(MPI.COMM_WORLD)
                end
            end
        end
    end
end
