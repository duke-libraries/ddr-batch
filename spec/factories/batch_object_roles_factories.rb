FactoryGirl.define do
  factory :batch_object_role, :class => Ddr::Batch::BatchObjectRole do

    factory :batch_object_add_role do
      operation Ddr::Batch::BatchObjectRole::OPERATION_ADD

      factory :batch_object_add_resource_role do
        agent 'user@test.com'
        role_type Ddr::Auth::Roles::RoleTypes::EDITOR.title
        role_scope Ddr::Auth::Roles::RESOURCE_SCOPE
      end

    end

  end
end
