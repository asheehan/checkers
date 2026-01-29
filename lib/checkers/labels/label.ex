defmodule Checkers.Labels.Label do
  @moduledoc """
  Schema for labels that can be attached to notes for organization.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Label colors - same palette as note colors for consistency
  @colors ~w(gray red orange yellow green teal blue purple pink brown)

  schema "labels" do
    field(:name, :string)
    field(:color, :string, default: "gray")

    many_to_many(:notes, Checkers.Notes.Note, join_through: "note_labels")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name, :color])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_inclusion(:color, @colors)
    |> unique_constraint(:name)
  end

  @doc """
  Returns the list of valid label colors.
  """
  def colors, do: @colors
end
