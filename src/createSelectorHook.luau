local React = require(script.Parent.Parent.React)
local Context = require(script.Parent.Context)
local useSyncExternalStoreWithSelector =
	require(script.Parent.useSyncExternalStoreWithSelector)

type Selector = <State, Selection>(State, ...any) -> Selection
type EqualityFn<T> = (old: T, new: T) -> boolean

local function defaultEqualityFn(newState, oldState)
	return newState == oldState
end

--[=[
	@within ReactRodux
	@function createSelectorHook
	@param context ReactContext<Store>
	@return useSelector

	Creates a useSelector hook that uses the given context. This should be used in
	conjunction with a Provider that was passed a custom context.

	```lua
	-- The initial value of the context doesn't matter, it will be overwritten.
	local Context = React.createContext(nil)

	local useSelector = createSelectorHook(Context)
	```
]=]
local function createSelectorHook<State>(context: Context.StoreContext<State>)
	return function<Selection>(
		selector: (State) -> Selection,
		equalityFn: EqualityFn<Selection>?
	)
		local store = React.useContext(context)

		if not equalityFn then
			equalityFn = defaultEqualityFn
		end

		local subscribe = React.useCallback(function(callback)
			local signal = (store.changed :: any):connect(callback)

			return function()
				signal:disconnect()
			end
		end, { store })

		local getSnapshot = React.useCallback(function()
			return store:getState()
		end, { store })

		local selection = useSyncExternalStoreWithSelector(
			subscribe,
			getSnapshot,
			nil,
			selector,
			equalityFn
		)

		return selection
	end
end

return createSelectorHook
