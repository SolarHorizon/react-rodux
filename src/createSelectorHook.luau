local React = require(script.Parent.Parent.React)
local Context = require(script.Parent.Context)

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

		local selection, setSelection = React.useState(function()
			return selector(store:getState())
		end)

		local prevSelection = React.useRef(selection)

		if not equalityFn then
			equalityFn = defaultEqualityFn
		end

		React.useEffect(function()
			-- Rodux types store.changed as an RBXScriptSignal which is incorrect
			local storeChanged = (store.changed :: any):connect(function(state)
				local newSelection = selector(state)

				-- Luau doesn't realize that equalityFn can't be nil here
				if
					not (equalityFn :: any)(newSelection, prevSelection.current)
				then
					prevSelection.current = newSelection
					setSelection(newSelection)
				end
			end)

			return function()
				storeChanged:disconnect()
			end
		end, { selector })

		return selection
	end
end

return createSelectorHook
