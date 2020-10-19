class UpdateMcflyTriggers < McflyMigration
  def change
    update_mcfly_functions
  end
end
