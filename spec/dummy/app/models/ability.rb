class Ability < Ddr::Auth::Ability

  self.ability_definitions += [ Ddr::Batch::BatchAbilityDefinitions ]

end
