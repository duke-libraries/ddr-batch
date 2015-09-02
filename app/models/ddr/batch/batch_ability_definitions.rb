module Ddr::Batch
  class BatchAbilityDefinitions < Ddr::Auth::AbilityDefinitions

    def call
      if authenticated?
        can :manage, Batch, user_id: user.id
      end
      can :manage, Ddr::Batch::BatchObject do |batch_object|
        can? :manage, batch_object.batch
      end
    end

  end
end