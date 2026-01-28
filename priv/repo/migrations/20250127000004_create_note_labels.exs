defmodule Checkers.Repo.Migrations.CreateNoteLabels do
  use Ecto.Migration

  def change do
    create table(:note_labels, primary_key: false) do
      add :note_id, references(:notes, type: :binary_id, on_delete: :delete_all), null: false
      add :label_id, references(:labels, type: :binary_id, on_delete: :delete_all), null: false
    end

    create unique_index(:note_labels, [:note_id, :label_id])
    create index(:note_labels, [:label_id])
  end
end
