local React = require(script.Parent.Parent.React)
local Context = require(script.Parent.Context)

--[=[
	@within ReactRodux
	@function createDispatchHook
	@param context ReactContext<Store>
	@return useDispatch

	Creates a useDispatch hook that uses the given context. This should be used in
	conjunction with a Provider that was passed a custom context.

	```lua
	-- The initial value of the context doesn't matter, it will be overwritten.
	local Context = React.createContext(nil)

	local useDispatch = createDispatchHook(Context)
	```
]=]
local function createDispatchHook<State>(context: Context.StoreContext<State>)
	return function()
		local store = React.useContext(context)

		return function(action)
			store:dispatch(action)
		end
	end
end

return createDispatchHook
