defmodule Checkers.Labels.Label do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "labels" do
    field :name, :string

    many_to_many :notes, Checkers.Notes.Note,
      join_through: "note_labels"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
    |> unique_constraint(:name)
  end
end
