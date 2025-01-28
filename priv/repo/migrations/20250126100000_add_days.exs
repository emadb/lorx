defmodule Lorx.Repo.Migrations.AddDaysToSchedule do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      add :days, {:array, :string}, default: [true, true, true, true, true, true, true]
    end
  end
end
