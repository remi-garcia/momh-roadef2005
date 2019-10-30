#=
# VNS_LPRC for the RENAULT Roadef 2005 challenge
# inspired by work of
# Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha, Caroline Rocha, Sebastián Urrutia
#
# @Author Boualem Lamraoui, Benoît Le Badezet, Benoit Loger, Jonathan Fontaine, Killian Fretaud, Rémi Garcia
# =#

include("parser.jl")
include("solution.jl")


const WEIGHTS_OBJECTIVE_FUNCTION = [1e6, 1e3, 1]

function perturbation_VNS_LPRC(sol::Solution, p::Int, k::Int, instance::Instances)
    # TODO
    return Solution(1, 1)
end

# The Local Search is based on a car exchange move.
function localSearch_VNS_LPRC(neighbor::Solution, p::Int, instance::Instances)
    # TODO
    return Solution(1, 1)
end

function intensification_VNS_LPRC(sol::Solution, instance::Instances)
    # TODO
    return Solution(1, 1)
end

# Return a tuple of solution, first element is the cost,and the second one is the number of HRPC violated.
function cost_VNS_LPRC(sol::Solution, instance::Instances)
    nb_HPRC_violated = sum(sol.M2[i, end] for i in 1:instance.nb_HPRC)
    nb_LPRC_violated = sum(sol.M2[instance.nb_HPRC + i, end] for i in 1:instance.nb_LPRC)
    cost = WEIGHTS_OBJECTIVE_FUNCTION[1] * nb_HPRC_violated + WEIGHTS_OBJECTIVE_FUNCTION[2] * nb_LPRC_violated
    return cost, nb_HPRC_violated
end

# function that determine if left is better than right.
function is_better_VNS_LPRC(left::Solution, right::Solution, instance::Instances)
    left_cost = cost_VNS_LPRC(left, instance)
    right_cost = cost_VNS_LPRC(right, instance)
    cost_better = left_cost[1] < right_cost[1]
    HPRC_not_worse = left_cost[2] <= right_cost[2]
    return  cost_better && HPRC_not_worse
end

# VNS-LPRC algorithm describe in section 6.
function VNS_LPRC(sol::Solution, instance::Instances)
    # solutions
    s = deepcopy(sol)
    s_opt = s
    # variable of the algorithm
    # According to the paper, cf 6.1
    k_min = [3, 5]
    k_max = [8, 12]
    p = 1
    k = k_min[p+1]
    nb_intens_not_better = 0
    while nb_intens_not_better < 150
        while k < k_max[p+1]
            neighbor = perturbation_VNS_LPRC(s, p, k, instance)
            neighbor = localSearch_VNS_LPRC(neighbor, p, instance)
            if is_better_VNS_LPRC(neighbor, s, instance)
                s = neighbor
                k = k_min[p+1]
            else
                k = k + 1
            end
            s = intensification_VNS_LPRC(s, instance)
            nb_intens_not_better += 1

            if is_better_VNS_LPRC(s, S, instance)
                s_opt = s
                nb_intens_not_better = 0
            end
        end
        p = 1 - p
        k = k_min[p+1]
    end
    return s_opt
end
