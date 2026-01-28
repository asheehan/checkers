defmodule Checkers.NotesTest do
  use Checkers.DataCase

  alias Checkers.Labels
  alias Checkers.Notes
  alias Checkers.Notes.Note

  describe "notes" do
    @valid_attrs %{title: "Test Note", content: "Test content", color: "blue"}
    @update_attrs %{title: "Updated Note", content: "Updated content", color: "green"}
    @invalid_attrs %{color: "invalid_color"}

    def note_fixture(attrs \\ %{}) do
      {:ok, note} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notes.create_note()

      note
    end

    test "list_notes/0 returns all active notes" do
      note = note_fixture()
      notes = Notes.list_notes()
      assert length(notes) == 1
      assert hd(notes).id == note.id
    end

    test "list_notes/0 excludes archived notes" do
      note = note_fixture()
      {:ok, _} = Notes.archive_note(note)
      assert Notes.list_notes() == []
    end

    test "list_notes/0 excludes trashed notes" do
      note = note_fixture()
      {:ok, _} = Notes.trash_note(note)
      assert Notes.list_notes() == []
    end

    test "list_notes/0 shows pinned notes first" do
      note1 = note_fixture(%{title: "Note 1"})
      _note2 = note_fixture(%{title: "Note 2"})
      {:ok, _} = Notes.toggle_pin(note1)

      [first | _] = Notes.list_notes()
      assert first.title == "Note 1"
      assert first.is_pinned == true
    end

    test "get_note!/1 returns the note with given id" do
      note = note_fixture()
      fetched = Notes.get_note!(note.id)
      assert fetched.id == note.id
      assert fetched.title == note.title
    end

    test "create_note/1 with valid data creates a note" do
      assert {:ok, %Note{} = note} = Notes.create_note(@valid_attrs)
      assert note.title == "Test Note"
      assert note.content == "Test content"
      assert note.color == "blue"
      assert note.is_pinned == false
      assert note.is_archived == false
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note" do
      note = note_fixture()
      assert {:ok, %Note{} = updated} = Notes.update_note(note, @update_attrs)
      assert updated.title == "Updated Note"
      assert updated.content == "Updated content"
      assert updated.color == "green"
    end

    test "toggle_pin/1 toggles the pinned state" do
      note = note_fixture()
      assert note.is_pinned == false

      {:ok, pinned} = Notes.toggle_pin(note)
      assert pinned.is_pinned == true

      {:ok, unpinned} = Notes.toggle_pin(pinned)
      assert unpinned.is_pinned == false
    end

    test "archive_note/1 archives the note and unpins it" do
      note = note_fixture()
      {:ok, pinned} = Notes.toggle_pin(note)
      {:ok, archived} = Notes.archive_note(pinned)

      assert archived.is_archived == true
      assert archived.is_pinned == false
    end

    test "unarchive_note/1 unarchives the note" do
      note = note_fixture()
      {:ok, archived} = Notes.archive_note(note)
      {:ok, unarchived} = Notes.unarchive_note(archived)

      assert unarchived.is_archived == false
    end

    test "trash_note/1 soft deletes the note" do
      note = note_fixture()
      {:ok, trashed} = Notes.trash_note(note)

      assert trashed.deleted_at != nil
      assert Notes.list_notes() == []
      assert length(Notes.list_trashed_notes()) == 1
    end

    test "restore_note/1 restores a trashed note" do
      note = note_fixture()
      {:ok, trashed} = Notes.trash_note(note)
      {:ok, restored} = Notes.restore_note(trashed)

      assert restored.deleted_at == nil
      assert length(Notes.list_notes()) == 1
    end

    test "delete_note/1 permanently deletes the note" do
      note = note_fixture()
      assert {:ok, %Note{}} = Notes.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id) end
    end

    test "update_color/2 updates the note color" do
      note = note_fixture(%{color: "default"})
      {:ok, updated} = Notes.update_color(note, "purple")
      assert updated.color == "purple"
    end

    test "toggle_checklist/1 toggles checklist mode" do
      # New notes default to checklist mode
      note = note_fixture()
      assert note.is_checklist == true

      {:ok, toggled} = Notes.toggle_checklist(note)
      assert toggled.is_checklist == false

      {:ok, toggled_back} = Notes.toggle_checklist(toggled)
      assert toggled_back.is_checklist == true
    end
  end

  describe "checklist_items" do
    def note_with_items_fixture do
      note = note_fixture(%{is_checklist: true})
      {:ok, item1} = Notes.create_checklist_item(note, %{content: "Item 1"})
      {:ok, item2} = Notes.create_checklist_item(note, %{content: "Item 2"})
      {Notes.get_note!(note.id), [item1, item2]}
    end

    test "create_checklist_item/2 creates a checklist item" do
      note = note_fixture(%{is_checklist: true})
      {:ok, item} = Notes.create_checklist_item(note, %{content: "Buy milk"})

      assert item.content == "Buy milk"
      assert item.is_checked == false
      assert item.note_id == note.id
    end

    test "create_checklist_item/2 auto-increments position" do
      note = note_fixture(%{is_checklist: true})
      {:ok, item1} = Notes.create_checklist_item(note, %{content: "Item 1"})
      {:ok, item2} = Notes.create_checklist_item(note, %{content: "Item 2"})

      assert item1.position == 0
      assert item2.position == 1
    end

    test "toggle_checklist_item/1 toggles the checked state" do
      {_note, [item | _]} = note_with_items_fixture()

      assert item.is_checked == false
      {:ok, checked} = Notes.toggle_checklist_item(item)
      assert checked.is_checked == true
      {:ok, unchecked} = Notes.toggle_checklist_item(checked)
      assert unchecked.is_checked == false
    end

    test "update_checklist_item/2 updates the item content" do
      {_note, [item | _]} = note_with_items_fixture()
      {:ok, updated} = Notes.update_checklist_item(item, %{content: "Updated content"})
      assert updated.content == "Updated content"
    end

    test "delete_checklist_item/1 deletes the item" do
      {note, [item | _]} = note_with_items_fixture()
      {:ok, _} = Notes.delete_checklist_item(item)

      updated_note = Notes.get_note!(note.id)
      assert length(updated_note.checklist_items) == 1
    end
  end

  describe "labels on notes" do
    test "add_label_to_note/2 adds a label to a note" do
      note = note_fixture()
      {:ok, label} = Labels.create_label(%{name: "Work"})

      {:ok, updated} = Notes.add_label_to_note(note, label)
      assert length(updated.labels) == 1
      assert hd(updated.labels).name == "Work"
    end

    test "remove_label_from_note/2 removes a label from a note" do
      note = note_fixture()
      {:ok, label} = Labels.create_label(%{name: "Work"})
      {:ok, with_label} = Notes.add_label_to_note(note, label)

      {:ok, without_label} = Notes.remove_label_from_note(with_label, label)
      assert without_label.labels == []
    end

    test "list_notes/1 filters by label" do
      note1 = note_fixture(%{title: "Work Note"})
      _note2 = note_fixture(%{title: "Personal Note"})
      {:ok, label} = Labels.create_label(%{name: "Work"})
      {:ok, _} = Notes.add_label_to_note(note1, label)

      filtered = Notes.list_notes(label_id: label.id)
      assert length(filtered) == 1
      assert hd(filtered).title == "Work Note"
    end
  end

  describe "search" do
    test "list_notes/1 searches by title" do
      _note1 = note_fixture(%{title: "Meeting notes", content: "Discuss budget"})
      _note2 = note_fixture(%{title: "Shopping list", content: "Buy groceries"})

      results = Notes.list_notes(search: "Meeting")
      assert length(results) == 1
      assert hd(results).title == "Meeting notes"
    end

    test "list_notes/1 searches by content" do
      _note1 = note_fixture(%{title: "Note 1", content: "Important meeting tomorrow"})
      _note2 = note_fixture(%{title: "Note 2", content: "Random stuff"})

      results = Notes.list_notes(search: "meeting")
      assert length(results) == 1
      assert hd(results).content == "Important meeting tomorrow"
    end

    test "list_notes/1 searches by checklist item content" do
      note = note_fixture(%{title: "Shopping", is_checklist: true})
      {:ok, _item1} = Notes.create_checklist_item(note, %{content: "Buy milk"})
      {:ok, _item2} = Notes.create_checklist_item(note, %{content: "Buy bread"})

      _other_note = note_fixture(%{title: "Work", content: "Do something"})

      results = Notes.list_notes(search: "milk")
      assert length(results) == 1
      assert hd(results).title == "Shopping"
    end
  end
end
