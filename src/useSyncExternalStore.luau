-- * Copyright (c) Meta Platforms, Inc. and affiliates.
-- *
-- * This source code is licensed under the MIT license found in the
-- * LICENSE file in the root directory of this source tree.

local LuauPolyfill = require(script.Parent.Parent.LuauPolyfill)
local React = require(script.Parent.Parent.React)

local didWarnUncachedGetSnapshot = false
local is = LuauPolyfill.Object.is

-- Disclaimer: This shim breaks many of the rules of React, and only works
-- because of a very particular set of implementation details and assumptions
-- -- change any one of them and it will break. The most important assumption
-- is that updates are always synchronous, because concurrent rendering is
-- only available in versions of React that also have a built-in
-- useSyncExternalStore API. And we only use this shim when the built-in API
-- does not exist.
--
-- Do not assume that the clever hacks used by this hook also work in general.
-- The point of this shim is to replace the need for hacks by other libraries.

local function checkIfSnapshotChanged<T>(
	inst: { value: T, getSnapshot: () -> T }
): boolean
	local latestGetSnapshot = inst.getSnapshot
	local prevValue = inst.value

	local _, result = xpcall(function()
		local nextValue = latestGetSnapshot()
		return not is(prevValue, nextValue)
	end, function()
		return true
	end)

	return result
end

local function useSyncExternalStore<T>(
	subscribe: (() -> ()) -> () -> (),
	getSnapshot: () -> T,
	-- Note: The shim does not use getServerSnapshot, because pre-18 versions of
	-- React do not expose a way to check if we're hydrating. So users of the shim
	-- will need to track that themselves and return the correct value
	-- from `getSnapshot`.
	_getServerSnapshot: (() -> T)?
): T
	-- Read the current snapshot from the store on every render. Again, this
	-- breaks the rules of React, and only works here because of specific
	-- implementation details, most importantly that updates are
	-- always synchronous.
	local value = getSnapshot()

	--selene: allow(global_usage)
	if _G.__DEV__ then
		if not didWarnUncachedGetSnapshot then
			local cachedValue = getSnapshot()
			if not is(value, cachedValue) then
				warn(
					"The result of getSnapshot should be cached to avoid an infinite loop."
				)
				didWarnUncachedGetSnapshot = true
			end
		end
	end

	-- Because updates are synchronous, we don't queue them. Instead we force a
	-- re-render whenever the subscribed state changes by updating an some
	-- arbitrary useState hook. Then, during render, we call getSnapshot to read
	-- the current value.
	--
	-- Because we don't actually use the state returned by the useState hook, we
	-- can save a bit of memory by storing other stuff in that slot.
	--
	-- To implement the early bailout, we need to track some things on a mutable
	-- object. Usually, we would put that in a useRef hook, but we can stash it in
	-- our useState hook instead.
	local state, setState = React.useState({
		inst = {
			value = value,
			getSnapshot = getSnapshot,
		},
	})

	-- To force a re-render, we call forceUpdate(inst)
	local forceUpdate = React.useCallback(function(inst)
		setState(table.clone(inst))
	end, {})

	-- Track the latest getSnapshot function with a ref. This needs to be updated
	-- in the layout phase so we can access it during the tearing check that
	-- happens on subscribe.
	React.useLayoutEffect(function()
		state.inst.value = value
		state.inst.getSnapshot = getSnapshot

		-- Whenever getSnapshot or subscribe changes, we need to check in the
		-- commit phase if there was an interleaved mutation. In concurrent mode
		-- this can happen all the time, but even in synchronous mode, an earlier
		-- effect may have mutated the store.
		if checkIfSnapshotChanged(state.inst) then
			-- Force a re-render.
			forceUpdate(state)
		end
	end, { subscribe, value :: any, getSnapshot :: any })

	React.useEffect(function()
		-- Check for changes right before subscribing. Subsequent changes will be
		-- detected in the subscription handler.
		if checkIfSnapshotChanged(state.inst) then
			forceUpdate(state)
		end

		local function handleStoreChange()
			-- TODO: Because there is no cross-renderer API for batching updates, it's
			-- up to the consumer of this library to wrap their subscription event
			-- with unstable_batchedUpdates. Should we try to detect when this isn't
			-- the case and print a warning in development?

			-- The store changed. Check if the snapshot changed since the last time we
			-- read from the store.
			if checkIfSnapshotChanged(state.inst) then
				-- Force a re-render.
				forceUpdate(state)
			end
		end

		-- Subscribe to the store and return a clean-up function.
		return subscribe(handleStoreChange)
	end, { subscribe })

	React.useDebugValue(value)
	return value
end

return useSyncExternalStore
