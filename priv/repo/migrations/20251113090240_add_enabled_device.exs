defmodule Lorx.Repo.Migrations.AddEnabledDevice do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add :enabled, :boolean, default: true
    end
  end
end
