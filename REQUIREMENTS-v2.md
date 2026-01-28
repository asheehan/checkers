# Checkers v2 - Requirements Update

## Summary
Improvements based on user testing feedback.

## Bug Fixes

### 1. Search Doesn't Work
- Search functionality is broken
- Should search across note titles, content, and checklist items
- Should filter visible cards in real-time

### 2. Label Popover Disappears
- The label picker popover closes before user can select a label
- Fix: Ensure popover stays open until user clicks outside or selects a label
- May need to adjust click handling / focus management

## Feature Changes

### 3. Checklists as Default
**Current:** New cards are notes by default, can convert to checklist
**New:** 
- New cards should be **checklists by default**
- User can switch to "free-form note" mode with an extra click
- Toggle should be clear (e.g., checkbox icon vs text icon)
- Keep ability to switch between modes on existing cards

### 4. Labels Need Colors
**Current:** Labels are plain text
**New:**
- Each label should have a color (user-selectable when creating/editing)
- Label colors should display as colored badges/pills
- Suggested palette: Same as card colors (Keep's palette)
- Labels on cards should show as colored chips

### 5. Drag and Drop
**Current:** No drag and drop
**New:**
- **Reorder cards:** Drag cards to reorder within the current view
- **Drag to Archive:** Drop zone or drag to archive section
- **Drag to Trash:** Drop zone for deleting
- **Drag from Archive to Notes:** When viewing archive, drag back to restore
- Visual feedback: 
  - Drag ghost/preview
  - Drop zone highlights
  - Smooth animations

## Implementation Notes

### Drag and Drop Libraries
Consider using:
- `@atlaskit/pragmatic-drag-and-drop` (lighter weight)
- `SortableJS` via LiveView hooks
- Native HTML5 drag-drop with LiveView JS hooks

### UI/UX for Drop Zones
- Sidebar could have "Notes", "Archive", "Trash" as drop targets
- Or floating drop zones that appear when dragging
- Visual feedback when hovering over drop zone

### Label Color Storage
Add `color` field to labels schema if not already present:
```elixir
field :color, :string, default: "gray"
```

## Acceptance Criteria

- [ ] New cards are checklists by default
- [ ] Can toggle a card to "note" mode (and back)
- [ ] Search filters cards in real-time (title, content, items)
- [ ] Label popover stays open until dismissed properly
- [ ] Labels display with their assigned colors
- [ ] Can assign colors when creating/editing labels
- [ ] Cards can be dragged to reorder
- [ ] Cards can be dragged to archive
- [ ] Cards can be dragged to trash
- [ ] Cards can be dragged from archive back to notes
- [ ] All existing tests still pass
- [ ] New tests for new functionality
