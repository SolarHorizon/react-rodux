local React = require(script.Parent.Parent.React)
local Context = require(script.Parent.Context)

--[=[
	@within ReactRodux
	@function createStoreHook
	@param context ReactContext<Store>
	@return useStore

	Creates a useStore hook that uses the given context. This should be used in
	conjunction with a Provider that was passed a custom context.

	```lua
	-- The initial value of the context doesn't matter, it will be overwritten.
	local Context = React.createContext(nil)

	local useStore = createStoreHook(Context)
	```
]=]
local function createUseStoreHook<State>(context: Context.StoreContext<State>)
	return function()
		return React.useContext(context)
	end
end

return createUseStoreHook
