defmodule Checkers.Labels do
  @moduledoc """
  The Labels context for managing labels.
  """

  import Ecto.Query, warn: false
  alias Checkers.Repo
  alias Checkers.Labels.Label

  @doc """
  Returns the list of all labels ordered by name.
  """
  def list_labels do
    from(l in Label, order_by: l.name)
    |> Repo.all()
  end

  @doc """
  Gets a single label.

  Raises `Ecto.NoResultsError` if the Label does not exist.
  """
  def get_label!(id), do: Repo.get!(Label, id)

  @doc """
  Gets a label by ID, returns nil if not found.
  """
  def get_label(id), do: Repo.get(Label, id)

  @doc """
  Gets a label by name.
  """
  def get_label_by_name(name) do
    Repo.get_by(Label, name: name)
  end

  @doc """
  Creates a label.
  """
  def create_label(attrs \\ %{}) do
    %Label{}
    |> Label.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a label.
  """
  def update_label(%Label{} = label, attrs) do
    label
    |> Label.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a label.
  """
  def delete_label(%Label{} = label) do
    Repo.delete(label)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking label changes.
  """
  def change_label(%Label{} = label, attrs \\ %{}) do
    Label.changeset(label, attrs)
  end

  @doc """
  Returns labels with their note counts.
  """
  def list_labels_with_counts do
    from(l in Label,
      left_join: nl in "note_labels",
      on: nl.label_id == l.id,
      left_join: n in Checkers.Notes.Note,
      on: n.id == nl.note_id and is_nil(n.deleted_at) and n.is_archived == false,
      group_by: l.id,
      select: {l, count(n.id)},
      order_by: l.name
    )
    |> Repo.all()
  end
end
