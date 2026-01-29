defmodule Checkers.Notes.Note do
  @moduledoc """
  Schema for notes/checklists. Notes can be pinned, archived, or trashed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @colors ~w(default red orange yellow green teal blue purple pink brown gray)

  schema "notes" do
    field(:title, :string)
    field(:content, :string)
    field(:color, :string, default: "default")
    field(:is_pinned, :boolean, default: false)
    field(:is_archived, :boolean, default: false)
    field(:is_checklist, :boolean, default: true)
    field(:position, :integer, default: 0)
    field(:deleted_at, :utc_datetime)

    has_many(:checklist_items, Checkers.Notes.ChecklistItem,
      on_delete: :delete_all,
      preload_order: [asc: :position]
    )

    many_to_many(:labels, Checkers.Labels.Label,
      join_through: "note_labels",
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [
      :title,
      :content,
      :color,
      :is_pinned,
      :is_archived,
      :is_checklist,
      :position,
      :deleted_at
    ])
    |> validate_inclusion(:color, @colors)
  end

  @doc """
  Returns the list of valid colors.
  """
  def colors, do: @colors
end
