defmodule Checkers.LabelsTest do
  use Checkers.DataCase

  alias Checkers.Labels
  alias Checkers.Labels.Label

  describe "labels" do
    @valid_attrs %{name: "Work"}
    @update_attrs %{name: "Personal"}
    @invalid_attrs %{name: nil}

    def label_fixture(attrs \\ %{}) do
      {:ok, label} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Labels.create_label()

      label
    end

    test "list_labels/0 returns all labels ordered by name" do
      _label1 = label_fixture(%{name: "Zebra"})
      _label2 = label_fixture(%{name: "Alpha"})

      labels = Labels.list_labels()
      assert length(labels) == 2
      assert hd(labels).name == "Alpha"
    end

    test "get_label!/1 returns the label with given id" do
      label = label_fixture()
      assert Labels.get_label!(label.id).name == label.name
    end

    test "get_label_by_name/1 returns the label with given name" do
      label = label_fixture()
      assert Labels.get_label_by_name("Work").id == label.id
    end

    test "get_label_by_name/1 returns nil if not found" do
      assert Labels.get_label_by_name("NonExistent") == nil
    end

    test "create_label/1 with valid data creates a label" do
      assert {:ok, %Label{} = label} = Labels.create_label(@valid_attrs)
      assert label.name == "Work"
    end

    test "create_label/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Labels.create_label(@invalid_attrs)
    end

    test "create_label/1 with duplicate name returns error" do
      _label = label_fixture(%{name: "Unique"})
      assert {:error, %Ecto.Changeset{}} = Labels.create_label(%{name: "Unique"})
    end

    test "update_label/2 with valid data updates the label" do
      label = label_fixture()
      assert {:ok, %Label{} = updated} = Labels.update_label(label, @update_attrs)
      assert updated.name == "Personal"
    end

    test "delete_label/1 deletes the label" do
      label = label_fixture()
      assert {:ok, %Label{}} = Labels.delete_label(label)
      assert_raise Ecto.NoResultsError, fn -> Labels.get_label!(label.id) end
    end

    test "change_label/1 returns a label changeset" do
      label = label_fixture()
      assert %Ecto.Changeset{} = Labels.change_label(label)
    end

    test "create_label/1 with color creates a label with that color" do
      assert {:ok, %Label{} = label} = Labels.create_label(%{name: "Urgent", color: "red"})
      assert label.name == "Urgent"
      assert label.color == "red"
    end

    test "create_label/1 without color defaults to gray" do
      assert {:ok, %Label{} = label} = Labels.create_label(%{name: "Default Color"})
      assert label.color == "gray"
    end

    test "update_label/2 can update the color" do
      label = label_fixture()
      assert {:ok, %Label{} = updated} = Labels.update_label(label, %{color: "blue"})
      assert updated.color == "blue"
    end

    test "create_label/1 with invalid color returns error" do
      assert {:error, %Ecto.Changeset{}} = Labels.create_label(%{name: "Bad", color: "neon"})
    end
  end
end
