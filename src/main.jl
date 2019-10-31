#=
# VNS for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#

# Complete strategy can be summerize as follow:
#
#   (1) Use a constructive heuristic to find an initial solution.
#   (2) Use an improvement heuristic to optimize the first objective.
#   (3) Use an improvement heuristic to optimize the second objective.
#   (4) Use a repair heuristic to make the current solution feasible.
#   (5) Use an improvement heuristic to optimize the third objective.
#

include("parser.jl")
include("solution.jl")
include("functions.jl")
include("constants.jl")

function main()
    # Instance and initiale solution
    type_fichier = "A"
    nom_fichier = INSTANCES[type_fichier][1]
    solution = init_solution(nom_fichier, type_fichier)

    # Greedy
    #TODO apply greedy (see PR #15)

    #TODO
end