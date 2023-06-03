local Context = require(script.Parent.Context)
local createStoreHook = require(script.Parent.createStoreHook)

--[=[
	@within ReactRodux
	@function createDispatchHook
	@param context ReactContext<Store>
	@return useStore

	Returns the Rodux store that was passed into the Provider. This might be
	useful if you need to use the store for something other than getting state
	or dispatching an action, otherwise `useSelector` and `useDispatch` are
	better options.

	```lua
	local function App(props)
		local store = useStore()

		return e(Button, {
			onClick = function()
				store:destruct()
			end,
		})
	end
	```
]=]
return createStoreHook(Context)
