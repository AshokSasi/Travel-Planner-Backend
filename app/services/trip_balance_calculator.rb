class TripBalanceCalculator
    def initialize(trip, current_user)
        @trip = trip
        @current_user = current_user
        @members = trip.users
    end

    def call
        balances = Hash.new { |h, k| h[k] = 0 }

        calculate_expenses(balances)
        apply_settlements(balances)

        format_output(balances)
    end

    private

    def apply_settlements(balances)
        @trip.settlements.each do |settlement|
            if settlement.user_id == @current_user.id
                balances[settlement.receiver_id] += settlement.amount
            elsif settlement.receiver_id == @current_user.id
                balances[settlement.user_id] -= settlement.amount
            end
        end
  end

    def calculate_expenses(balances)
        @trip.expenses.includes(:user).each do |expense|
            share = expense.amount / @members.count

            @members.each do |member|
                next if member == expense.user

                if expense.user == @current_user
                    balances[member.id] += share
                elsif member == @current_user
                    balances[expense.user.id] -= share
                end
            end
        end
    end

    def format_output(balances)
       balances.map do |member_id, amount|
      member = @members.find { |m| m.id == member_id }

      {
        member_id: member.id,
        name: member.name,
        net_balance: amount.round(2)
      }
    end.reject { |entry| entry[:net_balance] == 0 }
  end
end
