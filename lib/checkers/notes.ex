defmodule Checkers.Notes do
  @moduledoc """
  The Notes context for managing notes and checklist items.
  """

  import Ecto.Query, warn: false
  alias Checkers.Repo
  alias Checkers.Notes.{Note, ChecklistItem}
  alias Checkers.Labels.Label

  # ============================================================
  # Notes CRUD
  # ============================================================

  @doc """
  Returns a list of active notes (not deleted, not archived).
  Pinned notes come first, then by position.
  """
  def list_notes(opts \\ []) do
    query =
      from n in Note,
        where: is_nil(n.deleted_at) and n.is_archived == false,
        order_by: [desc: n.is_pinned, asc: n.position, desc: n.updated_at],
        preload: [:checklist_items, :labels]

    query
    |> maybe_filter_by_label(opts[:label_id])
    |> maybe_search(opts[:search])
    |> Repo.all()
  end

  @doc """
  Returns a list of archived notes.
  """
  def list_archived_notes do
    from(n in Note,
      where: is_nil(n.deleted_at) and n.is_archived == true,
      order_by: [desc: n.updated_at],
      preload: [:checklist_items, :labels]
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of trashed notes.
  """
  def list_trashed_notes do
    from(n in Note,
      where: not is_nil(n.deleted_at),
      order_by: [desc: n.deleted_at],
      preload: [:checklist_items, :labels]
    )
    |> Repo.all()
  end

  defp maybe_filter_by_label(query, nil), do: query

  defp maybe_filter_by_label(query, label_id) do
    from n in query,
      join: nl in "note_labels",
      on: nl.note_id == n.id,
      where: nl.label_id == ^label_id
  end

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query

  defp maybe_search(query, search) do
    search_term = "%#{String.downcase(search)}%"

    # Use a subquery to find note IDs that match checklist items
    checklist_matches =
      from ci in Checkers.Notes.ChecklistItem,
        where: like(fragment("lower(?)", ci.content), ^search_term),
        select: ci.note_id

    from n in query,
      where:
        like(fragment("lower(?)", n.title), ^search_term) or
          like(fragment("lower(?)", n.content), ^search_term) or
          n.id in subquery(checklist_matches)
  end

  @doc """
  Gets a single note with preloaded associations.
  """
  def get_note!(id) do
    Note
    |> Repo.get!(id)
    |> Repo.preload([:checklist_items, :labels])
  end

  @doc """
  Gets a note by ID, returns nil if not found.
  """
  def get_note(id) do
    case Repo.get(Note, id) do
      nil -> nil
      note -> Repo.preload(note, [:checklist_items, :labels])
    end
  end

  @doc """
  Creates a new note.
  """
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, note} -> {:ok, Repo.preload(note, [:checklist_items, :labels])}
      error -> error
    end
  end

  @doc """
  Updates a note.
  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, note} -> {:ok, Repo.preload(note, [:checklist_items, :labels], force: true)}
      error -> error
    end
  end

  @doc """
  Soft deletes a note (moves to trash).
  """
  def trash_note(%Note{} = note) do
    update_note(note, %{deleted_at: DateTime.utc_now()})
  end

  @doc """
  Restores a note from trash.
  """
  def restore_note(%Note{} = note) do
    update_note(note, %{deleted_at: nil})
  end

  @doc """
  Permanently deletes a note.
  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Toggles the pinned state of a note.
  """
  def toggle_pin(%Note{} = note) do
    update_note(note, %{is_pinned: !note.is_pinned})
  end

  @doc """
  Archives a note.
  """
  def archive_note(%Note{} = note) do
    update_note(note, %{is_archived: true, is_pinned: false})
  end

  @doc """
  Unarchives a note.
  """
  def unarchive_note(%Note{} = note) do
    update_note(note, %{is_archived: false})
  end

  @doc """
  Updates the color of a note.
  """
  def update_color(%Note{} = note, color) do
    update_note(note, %{color: color})
  end

  @doc """
  Converts a note to/from checklist mode.
  """
  def toggle_checklist(%Note{} = note) do
    update_note(note, %{is_checklist: !note.is_checklist})
  end

  @doc """
  Updates note positions for reordering.
  """
  def update_positions(note_ids) when is_list(note_ids) do
    note_ids
    |> Enum.with_index()
    |> Enum.each(fn {id, position} ->
      from(n in Note, where: n.id == ^id)
      |> Repo.update_all(set: [position: position])
    end)

    :ok
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.
  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  # ============================================================
  # Labels on Notes
  # ============================================================

  @doc """
  Adds a label to a note.
  """
  def add_label_to_note(%Note{} = note, %Label{} = label) do
    note = Repo.preload(note, :labels)
    labels = [label | note.labels] |> Enum.uniq_by(& &1.id)

    note
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:labels, labels)
    |> Repo.update()
    |> case do
      {:ok, note} -> {:ok, Repo.preload(note, [:checklist_items, :labels], force: true)}
      error -> error
    end
  end

  @doc """
  Removes a label from a note.
  """
  def remove_label_from_note(%Note{} = note, %Label{} = label) do
    note = Repo.preload(note, :labels)
    labels = Enum.reject(note.labels, &(&1.id == label.id))

    note
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:labels, labels)
    |> Repo.update()
    |> case do
      {:ok, note} -> {:ok, Repo.preload(note, [:checklist_items, :labels], force: true)}
      error -> error
    end
  end

  # ============================================================
  # Checklist Items
  # ============================================================

  @doc """
  Creates a checklist item for a note.
  """
  def create_checklist_item(%Note{} = note, attrs) do
    max_position =
      from(ci in ChecklistItem, where: ci.note_id == ^note.id, select: max(ci.position))
      |> Repo.one() || -1

    %ChecklistItem{}
    |> ChecklistItem.changeset(Map.merge(attrs, %{note_id: note.id, position: max_position + 1}))
    |> Repo.insert()
  end

  @doc """
  Updates a checklist item.
  """
  def update_checklist_item(%ChecklistItem{} = item, attrs) do
    item
    |> ChecklistItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Toggles the checked state of a checklist item.
  """
  def toggle_checklist_item(%ChecklistItem{} = item) do
    update_checklist_item(item, %{is_checked: !item.is_checked})
  end

  @doc """
  Deletes a checklist item.
  """
  def delete_checklist_item(%ChecklistItem{} = item) do
    Repo.delete(item)
  end

  @doc """
  Gets a checklist item by ID.
  """
  def get_checklist_item!(id), do: Repo.get!(ChecklistItem, id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking checklist item changes.
  """
  def change_checklist_item(%ChecklistItem{} = item, attrs \\ %{}) do
    ChecklistItem.changeset(item, attrs)
  end

  @doc """
  Reorders checklist items, moving checked items to bottom if requested.
  """
  def reorder_checklist_items(%Note{} = note, item_ids) when is_list(item_ids) do
    item_ids
    |> Enum.with_index()
    |> Enum.each(fn {id, position} ->
      from(ci in ChecklistItem, where: ci.id == ^id and ci.note_id == ^note.id)
      |> Repo.update_all(set: [position: position])
    end)

    :ok
  end

  # ============================================================
  # Cleanup
  # ============================================================

  @doc """
  Permanently deletes notes that have been in trash for more than 7 days.
  """
  def empty_old_trash(days \\ 7) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    from(n in Note, where: not is_nil(n.deleted_at) and n.deleted_at < ^cutoff)
    |> Repo.delete_all()
  end
end
