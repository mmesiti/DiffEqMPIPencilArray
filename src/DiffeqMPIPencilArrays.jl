using MPI
using LinearAlgebra
using OrdinaryDiffEq
using PencilArrays
using Random
using Test
using Plots
using DiffEqCallbacks


include("./utils.jl")

MPI.Init()

Nequations = 10

function createLocalStateDecomposed(total_length::Int)::PencilArray
    decomposition = Pencil((total_length,), (1,), MPI.COMM_WORLD)
    PencilArray{Float64}(undef, decomposition)
end

localState = createLocalStateDecomposed(Nequations)
randn!(localState)

evolutionMatrix = Array{Float64}(undef,(Nequations,Nequations))
if MPI.Comm_rank(MPI.COMM_WORLD) == 0
    Q,R = qr(rand(Nequations,Nequations))
    evolutionMatrix .= Matrix(Q)
end
MPI.Bcast!(evolutionMatrix,MPI.COMM_WORLD,root=0)


@mpi_synchronize println(localState)
@mpi_synchronize println(evolutionMatrix)

function getDeriv!(deriv::PencilArray,
                   state::PencilArray,
                   par,
                   t)
    (;evolutionMatrix,globalStateBuff) = par
    @mpi_synchronize println("t: $t")
    tᵣ₀ = MPI.bcast(t,MPI.COMM_WORLD)
    @assert tᵣ₀ == t
    @assert range_local(deriv) == range_local(state)

    statecp = Array(state)
    MPI.Allgatherv!(statecp,globalStateBuff,MPI.COMM_WORLD)

    deriv .= - evolutionMatrix[range_local(state)[1],:] * globalStateBuff.data
end

globalState = Vector{Float64}(undef,Nequations)

function getglobalbuff(globalState::Vector{T}, localArray::PencilArray{T})::VBuffer where T
    nranks = length(localArray.pencil.topology.ranks)

    counts = [ length(range_remote(localArray,rank)[1]) for rank in 1:nranks ]


    VBuffer(globalState,counts)

end

globalStateBuff = getglobalbuff(globalState,localState)


# For some reason, `solve` does not work
# when 'using DifferentialEquations' is used,
# but with 'using OrdinaryDiffEq' it works.
# Otherwise,
# creating the integrator and then using step! does work
# even with 'using DifferentialEquations'
# https://github.com/jipolanco/PencilArrays.jl/blob/master/test/ode.jl
problem = ODEProblem(getDeriv!,
                     localState,
                     (0.0,4.0),
                     (;globalStateBuff,evolutionMatrix)
                     )


function print_state(localState,t,_)
    statecp = Array(localState)
    globalStateBuff = getglobalbuff(globalState,localState)
    MPI.Allgatherv!(statecp,globalStateBuff,MPI.COMM_WORLD)
    state_to_process= globalStateBuff.data


    @mpi_synchronize println("State: $state_to_process - $t")
end


cb = FunctionCallingCallback(print_state)

solution = solve(problem,
                 Tsit5(),
                 save_everystep=false,
                 callback=cb)


MPI.Finalize()
