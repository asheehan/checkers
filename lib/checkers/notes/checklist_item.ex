defmodule Checkers.Notes.ChecklistItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "checklist_items" do
    field :content, :string
    field :is_checked, :boolean, default: false
    field :position, :integer, default: 0

    belongs_to :note, Checkers.Notes.Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :is_checked, :position, :note_id])
    |> validate_required([:content])
  end
end
