defmodule Checkers.Repo.Migrations.AddColorToLabels do
  use Ecto.Migration

  def change do
    alter table(:labels) do
      add :color, :string, default: "gray"
    end
  end
end
