#-------------------------------------------------------------------------------
# File: move_exchange.jl
# Description: This file contains all functions relatives to the echange move.
# Date: November 4, 2019
# Author: Jonathan Fontaine, Killian Fretaud, Rémi Garcia,
#         Boualem Lamraoui, Benoît Le Badezet, Benoit Loger
#-------------------------------------------------------------------------------


#TODO: Need refactoring

"""
    move_exchange!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)

Interverts the car `car_pos_a` with the car `car_pos_b` in `solution.sequence`. Updates
`solution.M1`, `solution.M2` and `solution.M3`.
"""
function move_exchange!(solution::Solution, car_pos_a::Int, car_pos_b::Int, instance::Instance)
    if car_pos_a > car_pos_b
        return move_exchange!(solution, car_pos_b, car_pos_a, instance)
    end
    if car_pos_a == car_pos_b
        return solution
    end
    car_a = solution.sequence[car_pos_a]
    car_b = solution.sequence[car_pos_b]
    solution.sequence[car_pos_a], solution.sequence[car_pos_b] = solution.sequence[car_pos_b], solution.sequence[car_pos_a]
    #update_matrices!(solution, solution.n, instance)
    for option in 1:(instance.nb_HPRC + instance.nb_LPRC)
        if xor(instance.RC_flag[car_a, option], instance.RC_flag[car_b, option])
            plusminusone = 1
            if instance.RC_flag[car_a, option]
                plusminusone = -1
            end
            first_modified_pos = car_pos_a - instance.RC_q[option] + 1
            if first_modified_pos < 1
                first_modified_pos = 1
            end
            for car_pos in first_modified_pos:car_pos_a
                solution.M1[option, car_pos] += plusminusone
                if car_pos == 1
                    solution.M2[option, car_pos] = 0
                    solution.M3[option, car_pos] = 0
                else
                    solution.M2[option, car_pos] = solution.M2[option, car_pos-1]
                    solution.M3[option, car_pos] = solution.M3[option, car_pos-1]
                end
                # M3 is >=
                if solution.M1[option, car_pos] >= instance.RC_p[option]
                    solution.M3[option, car_pos] += 1
                    # M2 is >
                    if solution.M1[option, car_pos] > instance.RC_p[option]
                        solution.M2[option, car_pos] += 1
                    end
                end
            end

            second_modified_pos = car_pos_b - instance.RC_q[option] + 1
            if second_modified_pos < 1
                second_modified_pos = 1
            end
            for car_pos in second_modified_pos:car_pos_b
                solution.M1[option, car_pos] -= plusminusone
                if car_pos == 1
                    solution.M2[option, car_pos] = 0
                    solution.M3[option, car_pos] = 0
                else
                    solution.M2[option, car_pos] = solution.M2[option, car_pos-1]
                    solution.M3[option, car_pos] = solution.M3[option, car_pos-1]
                end
                # M3 is >=
                if solution.M1[option, car_pos] >= instance.RC_p[option]
                    solution.M3[option, car_pos] += 1
                    # M2 is >
                    if solution.M1[option, car_pos] > instance.RC_p[option]
                        solution.M2[option, car_pos] += 1
                    end
                end
            end
        end
    end
    return solution
end



"""
    cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                       instance::Instance, objective::Int)

Return the cost of the exchange of the car `car_pos_a` with the car `car_pos_b` with respect to
objective `objective`. A negative cost means that the move is interesting with
respect to objective `objective`.
CAREFUL: Return a delta!
"""
function cost_move_exchange(solution::Solution, car_pos_a::Int, car_pos_b::Int,
                            instance::Instance, objective::Int)
    #TODO it might be important that objective is a vector of Int, then we could
    #return a vector of cost.

    # objective should take values between 1 and 3.
    @assert objective >= 1
    @assert objective <= 3

    cost_on_objective = zeros(Int, 3)

    if objective >= 1 #Must improve or keep HPRC
        for option in 1:instance.nb_HPRC
            # No cost if both have it / have it not
            if instance.RC_flag[solution.sequence[car_pos_a], option] != instance.RC_flag[solution.sequence[car_pos_b], option]
                #TODO: Rewrite code or swap indexes ?
                if instance.RC_flag[solution.sequence[car_pos_b], option]
                    car_pos_a,car_pos_b = car_pos_b,car_pos_a
                end
                # New option here -> increasing cost
                last_ended_sequence = car_pos_b - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[1] += solution.M3[option, car_pos_b] - solution.M3[option, last_ended_sequence]
                else
                    cost_on_objective[1] += solution.M3[option, car_pos_b]
                end
                # No option anymore -> decreasing cost
                last_ended_sequence = car_pos_a - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[1] -= solution.M2[option, car_pos_a] - solution.M2[option, last_ended_sequence]
                else
                    cost_on_objective[1] -= solution.M2[option, car_pos_a]
                end
            end
        end
    end
    if objective >= 2 #Must improve or keep HPRC and LPRC
        for option in (instance.nb_HPRC+1):(instance.nb_HPRC+instance.nb_LPRC)
            # No cost if both have it / have it not
            if instance.RC_flag[solution.sequence[car_pos_a], option] != instance.RC_flag[solution.sequence[car_pos_b], option]
                #TODO: Rewrite code or swap indexes ?
                if instance.RC_flag[solution.sequence[car_pos_b], option]
                    car_pos_a,car_pos_b = car_pos_b,car_pos_a
                end
                # New option here -> increasing cost
                last_ended_sequence = car_pos_b - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[2] += solution.M3[option, car_pos_b] - solution.M3[option, last_ended_sequence]
                else
                    cost_on_objective[2] += solution.M3[option, car_pos_b]
                end
                # No option anymore -> decreasing cost
                last_ended_sequence = car_pos_a - instance.RC_q[option]
                if last_ended_sequence > 0
                    cost_on_objective[2] -= solution.M2[option, car_pos_a] - solution.M2[option, last_ended_sequence]
                else
                    cost_on_objective[2] -= solution.M2[option, car_pos_a]
                end
            end
        end
    end
    if objective >= 3 #Must improve or keep HPRC and LPRC and PCC
        cost_on_objective[3] = 1 #TODO see here
    end

    return cost_on_objective
    #return sum(cost_on_objective[i]*WEIGHTS_OBJECTIVE_FUNCTION[i] for i in 1:3)
end