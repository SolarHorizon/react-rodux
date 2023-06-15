-- * Copyright (c) Meta Platforms, Inc. and affiliates.
-- *
-- * This source code is licensed under the MIT license found in the
-- * LICENSE file in the root directory of this source tree.

local React = require(script.Parent.Parent.React)
local LuauPolyfill = require(script.Parent.Parent.LuauPolyfill)
local useSyncExternalStore = require(script.Parent.useSyncExternalStore)

local is = LuauPolyfill.Object.is

-- Intentionally not using named imports because Rollup uses dynamic dispatch
-- for CommonJS interop.
-- const {useRef, useEffect, useMemo, useDebugValue} = React;

-- Same as useSyncExternalStore, but supports selector and isEqual arguments.
local function useSyncExternalStoreWithSelector<Snapshot, Selection>(
	subscribe: (
		() -> ()
	) -> () -> (),
	getSnapshot: (
	) -> Snapshot,
	getServerSnapshot: ((
	) -> Snapshot)?,
	selector: (
		snapshot: Snapshot
	) -> Selection,
	isEqual: ((
		a: Selection,
		b: Selection
	) -> boolean)?
): Selection
	-- Use this to track the rendered snapshot.
	--local instRef = React.useRef<({ hasValue: true, value: Selection } | { hasValue: false, value: nil } | nil)>(nil);
	local instRef = React.useRef({} :: any)

	local inst: Selection?

	if instRef.current ~= nil then
		inst = instRef.current
	end

	local getSelection, _getServerSelection = React.useMemo(function()
		-- Track the memoized state using closure variables that are local to this
		-- memoized instance of a getSnapshot function. Intentionally not using a
		-- useRef hook, because that state would be shared across all concurrent
		-- copies of the hook/component.
		local hasMemo = false
		local memoizedSnapshot
		local memoizedSelection: Selection

		local function memoizedSelector(nextSnapshot: Snapshot)
			if not hasMemo then
				-- The first time the hook is called, there is no memoized result.
				hasMemo = true
				memoizedSnapshot = nextSnapshot

				local nextSelection = selector(nextSnapshot)

				if isEqual ~= nil then
					-- Even if the selector has changed, the currently rendered selection
					-- may be equal to the new selection. We should attempt to reuse the
					-- current value if possible, to preserve downstream memoizations.
					if inst ~= nil then
						local currentSelection = inst
						if isEqual(currentSelection, nextSelection) then
							memoizedSelection = currentSelection
							return currentSelection
						end
					end
				end

				memoizedSelection = nextSelection

				return nextSelection
			end

			-- We may be able to reuse the previous invocation's result.
			local prevSnapshot: Snapshot = memoizedSnapshot
			local prevSelection: Selection = memoizedSelection

			if is(prevSnapshot, nextSnapshot) then
				-- The snapshot is the same as last time. Reuse the previous selection.
				return prevSelection
			end

			-- The snapshot has changed, so we need to compute a new selection.
			local nextSelection = selector(nextSnapshot)

			-- If a custom isEqual function is provided, use that to check if the data
			-- has changed. If it hasn't, return the previous selection. That signals
			-- to React that the selections are conceptually equal, and we can bail
			-- out of rendering.
			if isEqual ~= nil and isEqual(prevSelection, nextSelection) then
				return prevSelection
			end

			memoizedSnapshot = nextSnapshot
			memoizedSelection = nextSelection

			return nextSelection
		end

		local function getSnapshotWithSelector()
			return memoizedSelector(getSnapshot())
		end

		local function getServerSnapshotWithSelector()
			-- Note: React17 has no getServerSnapshot, so we are
			-- omitting it entirely here.
			-- return memoizedSelector(getServerSnapshot())
		end

		return getSnapshotWithSelector, getServerSnapshotWithSelector
	end, { getSnapshot, getServerSnapshot, selector, isEqual } :: { any })

	local value = useSyncExternalStore(subscribe, getSelection, nil)
	-- useSyncExternalStore(subscribe, getSelection, getServerSelection)

	React.useEffect(function()
		-- $FlowFixMe[incompatible-type] changing the variant using mutation isn't supported
		-- inst.hasValue = true
		-- $FlowFixMe[incompatible-type]
		inst = value
	end, { value })

	React.useDebugValue(value)

	return value
end

return useSyncExternalStoreWithSelector
