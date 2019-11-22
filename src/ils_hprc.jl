#-------------------------------------------------------------------------------
# File: ils_hprc.jl
# Description: ILS for the RENAULT Roadef 2005 challenge
#   inspired by work of
#   Celso C. Ribeiro, Daniel Aloise, Thiago F. Noronha,
#   Caroline Rocha, Sebastián Urrutia
#
# Date: November 03, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------

function remove(solution_init::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})
    i = instance.nb_late_prec_day+1
    removed = Array{Int, 1}([])
    solution = deepcopy(solution_init)
    while i <= instance.nb_cars && length(removed) <= nbcar
        #TODO Don't take the first nbcar cars but randomly pick nbcar cars
        if crit[i] == 1
            push!(removed, solution.sequence[i])
            deleteat!(solution.sequence, i)
            update_matrices!(solution, length(solution.sequence), instance)
            deleteat!(crit, i)
        else
            i = i + 1
        end
    end
    return solution, removed
end

#TODO Need rework
function greedyadd(solution::Solution, instance::Instance, car::Int)
    i = instance.nb_late_prec_day + 1
    tmp = deepcopy(solution)
    splice!(tmp.sequence, i:i-1, car)
    update_matrices!(tmp, length(tmp.sequence), instance)
    bestcost = costHPRC(tmp, instance)
    bestsol = deepcopy(tmp)
    deleteat!(tmp.sequence, i)
    for j in i:length(tmp.sequence)
        splice!(tmp.sequence, j:j-1, car)
        update_matrices!(tmp, length(tmp.sequence), instance)
        ncost = costHPRC(tmp, instance)
        if ncost < bestcost
            bestcost = ncost
            bestsol = deepcopy(tmp)
        end
        deleteat!(tmp.sequence, j)
    end
    return bestsol
end


function perturbation(solution::Solution, instance::Instance, nbcar::Int, crit::Array{Int,1})
    sol, removed = remove(solution, instance, nbcar, crit)
    for i in removed
        sol = greedyadd(sol, instance, i)
    end
    return sol
end

# Retourne le coût du premier objectif pour la solution solution
function costHPRC(solution::Solution, instance::Instance)
    return cost(solution, instance, 1)[1]
end

#TODO changer rendre intelligent
function localSearchExchange(solution::Solution, instance::Instance)
    while true
        phi = costHPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            best_delta = 0
            L = []
            for j in b0:instance.nb_cars
                delta = cost_move_exchange(solution, i, j, instance,1)[1]
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                k = rand(L)
                move_exchange!(solution, i, k, instance)
            end
        end
        if phi == costHPRC(solution, instance)
            break
        end
    end

    return solution
end

#TODO rendre intelligent
function localSearchInsertion(solution::Solution, instance::Instance)
    while true
        phi = costHPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            best_delta = 0
            L = []
            couts = cost_move_insertion(solution,i,instance,1)
            for j in b0:instance.nb_cars
                delta = couts[j, 1]
                if delta < best_delta
                    L = [j]
                    best_delta = delta
                elseif delta == best_delta
                    push!(L, j)
                end
            end
            if L != []
                k = rand(L)
                move_insertion!(solution, i, k, instance)
            end
        end
        if phi == costHPRC(solution, instance)
            break
        end
    end

    return solution
end

function fastLocalSearchExchange(solution::Solution, instance::Instance, crit::Array{Int, 1})
    while true
        phi = costHPRC(solution, instance)
        b0 = instance.nb_late_prec_day + 1      #First car of the current production day
        for i in b0:instance.nb_cars
            if crit[i] == 1
                best_delta = 0
                L = []
                for j in b0:instance.nb_cars
                    delta = cost_move_exchange(solution, i, j, instance, 1)[1]
                    if delta < best_delta
                        L = [j]
                        best_delta = delta
                    elseif delta == best_delta
                        push!(L, j)
                    end
                end
                if L != []
                    k = rand(L)
                    move_exchange!(solution, i, k, instance)
                end
            end
        end
        if phi == costHPRC(solution, instance)
            break
        end
    end

    return solution
end

#Inidquate which cars are invloved in violation of HPRC and the number
function criticalCars(solution::Solution, instance::Instance)
    criticars = zeros(Int, instance.nb_cars)             # criticars[i] = 1 if car i violate HPRC otherwhise criticars[i] = 0
    nb_crit = 0                             # Number of cars involved in HPRC violation.
    j = 1
    for opt in 1:instance.nb_HPRC
        car = 1
        while car <= instance.nb_cars
            if solution.M2[opt,car] > instance.RC_p[opt]
                cursor = 0
                while cursor < instance.RC_p[opt] && (car+cursor) <= instance.nb_cars
                    if instance.RC_flag[car+cursor, opt] == true && criticars[car + cursor] == 0
                        criticars[car + cursor] = 1
                        nb_crit = nb_crit + 1
                    end
                    cursor = cursor + 1
                end
            end
            car = car + 1
        end
    end

    return criticars, nb_crit
end

function intensification(solution::Solution, instance::Instance)
    solution = localSearchInsertion(solution, instance)
    solution = localSearchExchange(solution, instance)
    return solution
end

function restart(solution::Solution, instance::Instance)
    crit = criticalCars(solution, instance)[1]
    solution = perturbation(solution, instance, NBCAR_DIVERSIFICATION, crit)
    return solution
end


function ILS_HPRC(solution::Solution, instance::Instance, start_time::UInt)
    i = 0                               # Number of itération since the last improvement
    s = deepcopy(solution)
    s_opt = deepcopy(solution)
    lastopt = deepcopy(solution)
    cond = 0 #TODO
    while cond < STOPPING_CRITERIA_ILS_HPRC && costHPRC(s_opt, instance) != 0 && (0.9 * TIME_LIMIT > (time_ns() - start_time) / 1.0e9)
        crit = criticalCars(s, instance)
        neighbor = perturbation(s, instance, NBCAR_PERTURBATION, crit[1])
        crit = criticalCars(neighbor, instance)
        if crit[2] > (instance.nb_cars * 0.6)
            neighbor = localSearchExchange(neighbor, instance)
        else
            neighbor = fastLocalSearchExchange(neighbor, instance, crit[1])
        end
        if costHPRC(s, instance) <= costHPRC(neighbor, instance)
            s = neighbor
        end
        if i == ALPHA_ILS
            s = intensification(s, instance)
        end
        if i == BETA_ILS
            cond = cond + 1
            if costHPRC(lastopt, instance) > costHPRC(s_opt, instance)
                lastopt = s_opt
                cond = 0
            end
            if costHPRC(s, instance) == costHPRC(s_opt, instance) && cond < STOPPING_CRITERIA_ILS_HPRC
                s = restart(s, instance)
                i = 0
            elseif cond < STOPPING_CRITERIA_ILS_HPRC
                s = s_opt
                i = 0
            else
                s = greedy(instance)
            end
        end
        if costHPRC(s, instance) < costHPRC(s_opt, instance)            # There is an improvement
            s_opt = s
            i = 0                   # So the number of iteration since the last improvement shall return to 0
        else
            i = i + 1
        end
        #println(i)
    end
    return s_opt
end
