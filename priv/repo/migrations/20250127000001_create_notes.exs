defmodule Checkers.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :color, :string, default: "default"
      add :is_pinned, :boolean, default: false
      add :is_archived, :boolean, default: false
      add :is_checklist, :boolean, default: false
      add :position, :integer, default: 0
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notes, [:is_pinned])
    create index(:notes, [:is_archived])
    create index(:notes, [:deleted_at])
    create index(:notes, [:position])
  end
end
