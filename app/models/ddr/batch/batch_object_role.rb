module Ddr::Batch

  class BatchObjectRole < ActiveRecord::Base
    belongs_to :batch_object, :inverse_of => :batch_object_roles

    OPERATION_ADD = "ADD".freeze  # Add the principal and role to the object in the indicated scope
    OPERATIONS = [ OPERATION_ADD ].freeze

    validates :operation, inclusion: { in: OPERATIONS }
    validate :valid_role, if: :operation_requires_valid_role?
    validate :policy_role_scope_only_for_collections, if: "role_scope == Ddr::Auth::Roles::POLICY_SCOPE"

    def operation_requires_valid_role?
      [ OPERATION_ADD ].include? operation
    end

    def valid_role
      Ddr::Auth::Roles::Role.build(type: role_type, agent: agent, scope: role_scope).valid?
    end

    def policy_role_scope_only_for_collections
      errors.add(:role_scope, "policy role scope is valid only for Collections") unless batch_object.model == "Collection"
    end
  end

end
