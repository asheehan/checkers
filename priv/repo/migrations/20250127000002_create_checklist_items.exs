defmodule Checkers.Repo.Migrations.CreateChecklistItems do
  use Ecto.Migration

  def change do
    create table(:checklist_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :string, null: false
      add :is_checked, :boolean, default: false
      add :position, :integer, default: 0
      add :note_id, references(:notes, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:checklist_items, [:note_id])
    create index(:checklist_items, [:position])
  end
end
